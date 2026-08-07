/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/account_service.dart';
import 'package:sugarpaper/data/store.dart';
import 'package:sugarpaper/data/sync_service.dart';
import 'package:sugarpaper/models/account.dart';

/// 安卓客户端 ↔ NIP-01 严格中继（hex 公钥校验）的往返测试：
/// 验证 SyncService 推送的事件能被公共中继接受，且能拉回自己的事件。
void main() {
  test('SyncService 经 hex 校验中继完成推送与拉取', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final events = <Map<String, dynamic>>[];
    final hexRe = RegExp(r'^[a-f0-9]{64}$');

    server.listen((req) async {
      if (req.uri.path != '/relay') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      final ws = await WebSocketTransformer.upgrade(req);
      ws.listen((data) {
        final msg = jsonDecode(data as String);
        if (msg is! List || msg.isEmpty) return;
        if (msg[0] == 'EVENT') {
          final ev = Map<String, dynamic>.from(msg[1] as Map);
          if (hexRe.hasMatch((ev['pubkey'] as String?) ?? '')) {
            events.add(ev);
            ws.add(jsonEncode(['OK', ev['id'], true, '']));
          }
        } else if (msg[0] == 'REQ') {
          final filter = Map<String, dynamic>.from(msg[2] as Map);
          final kinds = (filter['kinds'] as List? ?? []).cast<int>();
          final authors = (filter['authors'] as List? ?? []).cast<String>();
          final dTag = ((filter['#d'] as List?) ?? []).cast<String>();
          for (final ev in events) {
            if (kinds.isNotEmpty && !kinds.contains(ev['kind'])) continue;
            if (authors.isNotEmpty && !authors.contains(ev['pubkey'])) continue;
            if (dTag.isNotEmpty) {
              final tags = (ev['tags'] as List? ?? []);
              final hit = tags.any((t) =>
                  t is List &&
                  t.isNotEmpty &&
                  t[0] == 'd' &&
                  t[1] == dTag.first);
              if (!hit) continue;
            }
            ws.add(jsonEncode(['EVENT', ev]));
          }
          ws.add(jsonEncode(['EOSE', msg[1]]));
        }
      }, onError: (_) {});
    });

    final store = AppStore()
      ..overrideDir =
          await Directory.systemTemp.createTemp('sugarpaper-interop');

    const mnemonic = 'bac bab bac bab bac bab bac bab bac bab bac bab';
    final restored = await AccountService.restoreAccount(mnemonic);
    store.setAccount(Account(
      pubkey: await AccountService.publicKeyB64(restored.keyPair),
      seedB64: base64Url
          .encode(restored.seed)
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', ''),
      mnemonic: mnemonic,
      displayName: '互通测试',
    ));
    store.updateSettings({'relays': ['ws://127.0.0.1:$port/relay']});
    store.addTask({
      'subject': '数学',
      'title': '跨端同步试卷',
      'dueDate': '2026-08-10',
    });

    final sync = SyncService();
    await sync.syncOnce(store);
    expect(sync.status, 'connected', reason: '推送失败：${sync.lastError}');
    expect(sync.lastError, isNull);
    expect(events, isNotEmpty);
    expect(hexRe.hasMatch((events.first['pubkey'] as String?) ?? ''), isTrue,
        reason: '事件 pubkey 必须是 64 位 hex 才能被公共中继接受');

    store.tasks.clear();
    await sync.syncOnce(store);
    expect(sync.status, 'connected', reason: '回读失败：${sync.lastError}');
    expect(store.tasks.any((t) => t.title == '跨端同步试卷'), isTrue,
        reason: '应能从中继拉回自己推送的快照');

    await server.close(force: true);
  });
}
