/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/account.dart';
import '../models/focus_session.dart';
import '../models/note.dart';
import '../models/task.dart';
import 'account_service.dart';
import 'store.dart';

/// 无服务器跨设备同步（v0.16.0 对齐网页版 `sync.js`）：
/// Nostr 公共中继（WebSocket），拉取最新加密快照 → 验签 → 解密 →
/// 按 updatedAt 逐条合并 → 推送合并结果。
class SyncService {
  static const defaultRelays = [
    'wss://relay.damus.io',
    'wss://nostr.wine',
    'wss://relay.nostr.band',
  ];
  static const syncKind = 19322;
  static const syncDTag = 'sugarpaper:snapshot';
  static const reqTimeout = Duration(seconds: 8);

  String status = 'off'; // off | connecting | connected | error
  String? lastError;

  List<String> _relays(AppStore store) =>
      store.settings.relays.isNotEmpty
          ? store.settings.relays
          : defaultRelays;

  Map<String, dynamic> snapshotPayload(AppStore store) {
    final ver = (store.account?.version ?? 0);
    return {
      'version': ver,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': store.tasks.map((t) => t.toJson()).toList(),
      'notes': store.notes.map((n) => n.toJson()).toList(),
      'focusSessions':
          store.focusSessions.map((s) => s.toJson()).toList(),
    };
  }

  /// 构建加密信封（对齐网页版 buildEnvelope）。
  Future<Map<String, dynamic>> buildEnvelope(AppStore store) async {
    final acc = store.account;
    if (acc == null) throw StateError('尚未创建账号');
    final seed = Uint8List.fromList(_b64urlToBytes(acc.seedB64));
    final keyPair = await AccountService.seedToKeyPair(seed);
    final payload = snapshotPayload(store);
    final env = await AccountService.encryptData(payload, seed);
    final version = (acc.version) + 1;
    final sig = await AccountService.signBytes(
      keyPair,
      utf8.encode('${AccountService.signPrefix}$version:${env.iv}:${env.data}'),
    );
    return {
      'app': 'SugarPaper',
      'kind': 'sync',
      'ver': 1,
      'version': version,
      'iv': env.iv,
      'data': env.data,
      'sig': sig,
      'pubkey': acc.pubkey,
    };
  }

  /// 验签信封（对齐网页版 verifyEnvelope）。
  Future<bool> verifyEnvelope(Map<String, dynamic> env, String pubkeyB64) async {
    if (env['pubkey'] != pubkeyB64) return false;
    final bytes = utf8.encode(
      '${AccountService.signPrefix}${env['version']}:${env['iv']}:${env['data']}',
    );
    return AccountService.verifyBytes(
      pubkeyB64,
      bytes,
      env['sig'] as String,
    );
  }

  /// 构造 Nostr 事件并签名（对齐网页版 nostrEvent）。
  Future<Map<String, dynamic>> nostrEvent(
    Account acc,
    Map<String, dynamic> env,
  ) async {
    final seed = Uint8List.fromList(_b64urlToBytes(acc.seedB64));
    final keyPair = await AccountService.seedToKeyPair(seed);
    final pubkeyHex = await AccountService.publicKeyHex(keyPair);
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = [
      ['d', syncDTag],
      ['t', 'sugarpaper'],
    ];
    final content = jsonEncode(env);
    final idBytes = await AccountService.sha256(
      utf8.encode(
        jsonEncode([0, pubkeyHex, createdAt, syncKind, tags, content]),
      ),
    );
    final id = _bytesToHex(idBytes);
    final sig = await AccountService.signBytes(
      keyPair,
      _hexToBytes(id),
    );
    return {
      'kind': syncKind,
      'created_at': createdAt,
      'tags': tags,
      'content': content,
      'pubkey': pubkeyHex,
      'id': id,
      'sig': sig,
    };
  }

  Future<WebSocket> _openWs(String url) async {
    final socket = await WebSocket.connect(url).timeout(reqTimeout);
    return socket;
  }

  /// 从单个中继拉取作者最新的糖纸快照事件（返回最高 version 的 env 或 null）。
  Future<Map<String, dynamic>?> _fetchLatest(
    WebSocket ws,
    String pubkeyHex,
  ) async {
    final completer = Completer<Map<String, dynamic>?>();
    Map<String, dynamic>? best;
    final timer = Timer(reqTimeout, () {
      if (!completer.isCompleted) completer.complete(best);
    });
    ws.listen((data) {
      try {
        final msg = jsonDecode(data as String);
        if (msg is! List || msg.isEmpty) return;
        if (msg[0] == 'EVENT' &&
            msg[1] is Map &&
            msg[1]['kind'] == syncKind) {
          final env = jsonDecode(msg[1]['content'] as String);
          if (env is Map &&
              env['app'] == 'SugarPaper' &&
              env['kind'] == 'sync' &&
              env['version'] is num) {
            final v = (env['version'] as num).toInt();
            if (best == null || v > (best!['version'] as num).toInt()) {
              best = Map<String, dynamic>.from(env);
            }
          }
        } else if (msg[0] == 'EOSE') {
          timer.cancel();
          if (!completer.isCompleted) completer.complete(best);
        }
      } catch (_) {
        // 忽略无效消息
      }
    }, onError: (_) {
      timer.cancel();
      if (!completer.isCompleted) completer.complete(best);
    });
    ws.add(jsonEncode([
      'REQ',
      'sugarpaper',
      {
        'kinds': [syncKind],
        'authors': [pubkeyHex],
        '#d': [syncDTag],
        'limit': 20,
      },
    ]));
    return completer.future;
  }

  /// 逐条按 updatedAt 合并（LWW）；isDeleted 墓碑随记录保留。
  List<Map<String, dynamic>> mergeById(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final map = <String, Map<String, dynamic>>{};
    for (final x in a) {
      if (x['id'] != null) map[x['id'] as String] = x;
    }
    for (final x in b) {
      if (x['id'] == null) continue;
      final id = x['id'] as String;
      final ex = map[id];
      if (ex == null ||
          (x['updatedAt']?.toString() ?? '')
                  .compareTo(ex['updatedAt']?.toString() ?? '') >=
              0) {
        map[id] = x;
      }
    }
    return map.values.toList();
  }

  /// 执行一轮同步：连接默认中继 → 拉取 → 验签解密 → 合并 → 推送。
  Future<void> syncOnce(AppStore store, {void Function()? onDone}) async {
    final acc = store.account;
    if (acc == null) {
      status = 'error';
      lastError = '请先创建或恢复账号';
      return;
    }
    status = 'connecting';
    lastError = null;
    try {
      final url = _relays(store).first;
      final ws = await _openWs(url);
      final seed = Uint8List.fromList(_b64urlToBytes(acc.seedB64));
      final keyPair = await AccountService.seedToKeyPair(seed);
      final pubkeyHex = await AccountService.publicKeyHex(keyPair);
      final remote = await _fetchLatest(ws, pubkeyHex);
      if (remote != null && await verifyEnvelope(remote, acc.pubkey)) {
        final payload = await AccountService.decryptData(
          (iv: remote['iv'] as String, data: remote['data'] as String),
          seed,
        ) as Map<String, dynamic>;
        _applyRemote(store, payload);
      }
      // 推送合并后的本地快照（版本递增）
      final env = await buildEnvelope(store);
      final event = await nostrEvent(acc, env);
      ws.add(jsonEncode(['EVENT', event]));
      await ws.close();
      store.updateAccount({
        'lastSyncAt': DateTime.now().toIso8601String(),
      });
      status = 'connected';
    } catch (e) {
      status = 'error';
      lastError = e.toString();
    }
    onDone?.call();
  }

  void _applyRemote(AppStore store, Map<String, dynamic> payload) {
    final remoteTasks = (payload['tasks'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final remoteNotes = (payload['notes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final remoteFocus = (payload['focusSessions'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final mergedTasks = mergeById(
      store.tasks.map((t) => t.toJson()).toList(),
      remoteTasks,
    );
    final mergedNotes = mergeById(
      store.notes.map((n) => n.toJson()).toList(),
      remoteNotes,
    );
    final mergedFocus = mergeById(
      store.focusSessions.map((s) => s.toJson()).toList(),
      remoteFocus,
    );

    final tasksChanged = jsonEncode(mergedTasks) !=
        jsonEncode(store.tasks.map((t) => t.toJson()).toList());
    final notesChanged = jsonEncode(mergedNotes) !=
        jsonEncode(store.notes.map((n) => n.toJson()).toList());
    final focusChanged = jsonEncode(mergedFocus) !=
        jsonEncode(store.focusSessions.map((s) => s.toJson()).toList());

    if (tasksChanged || notesChanged || focusChanged) {
      store.tasks
        ..clear()
        ..addAll(mergedTasks
            .map((e) => Task.fromJson(e)));
      store.notes
        ..clear()
        ..addAll(mergedNotes.map((e) => Note.fromJson(e)));
      store.focusSessions
        ..clear()
        ..addAll(mergedFocus.map((e) => FocusSession.fromJson(e)));
      final remoteVersion = (payload['version'] as num?)?.toInt() ?? 0;
      store.updateAccount({
        'version': remoteVersion > (store.account?.version ?? 0)
            ? remoteVersion
            : store.account?.version,
      });
      store.persist();
    }
  }

  static Uint8List _b64urlToBytes(String s) {
    var b = s.replaceAll('-', '+').replaceAll('_', '/');
    while (b.length % 4 != 0) {
      b += '=';
    }
    return base64Url.decode(b);
  }

  static String _bytesToHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  static Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
