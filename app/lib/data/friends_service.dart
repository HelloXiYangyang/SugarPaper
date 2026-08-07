/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/account.dart';
import 'account_service.dart';

/// 好友（本地记录）。
class Friend {
  final String id;
  final String pubkey; // 64 位 hex
  final String name;
  final String friendKey; // b64url 共享密钥
  final String addedAt;
  String? lastMsgAt;

  Friend({
    required this.id,
    required this.pubkey,
    required this.name,
    required this.friendKey,
    required this.addedAt,
    this.lastMsgAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'name': name,
        'friendKey': friendKey,
        'addedAt': addedAt,
        'lastMsgAt': lastMsgAt,
      };

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: (j['id'] as String?) ?? '',
        pubkey: (j['pubkey'] as String?) ?? '',
        name: (j['name'] as String?) ?? '好友',
        friendKey: (j['friendKey'] as String?) ?? '',
        addedAt: (j['addedAt'] as String?) ?? '',
        lastMsgAt: j['lastMsgAt'] as String?,
      );
}

/// 好友直连（v0.33.0，S18 模块二）：预共享密钥 + AES-GCM 加密消息/分享，
/// 经 Nostr 中继（kind 19324）转发密文；协议与网页版 `web/js/friends.js` 一致。
/// 好友列表独立 JSON 存储（不进入同步快照）。
class FriendsService {
  static const int friendKind = 19324;
  static const String friendDTag = 'sugarpaper:friend';
  static const String proto = 'sugarpaper://friend';
  static const String _fileName = 'sugarpaper_friends.json';

  final Directory? overrideDir;
  final List<Friend> _friends = [];
  final Map<String, String> _pendingKeys = {}; // key -> ts
  final List<String> _seen = [];

  FriendsService({this.overrideDir});

  Future<Directory> _dir() async {
    if (overrideDir != null) return overrideDir!;
    return getApplicationDocumentsDirectory();
  }

  Future<void> load() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      if (await file.exists()) {
        final j = jsonDecode(await file.readAsString());
        if (j is Map) {
          final list = (j['friends'] as List?) ?? const [];
          _friends
            ..clear()
            ..addAll(list
                .whereType<Map>()
                .map((e) => Friend.fromJson(Map<String, dynamic>.from(e))));
        }
      }
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'friends': _friends.map((f) => f.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  List<Friend> get list => List.unmodifiable(_friends);

  Friend? findPub(String pub) {
    for (final f in _friends) {
      if (f.pubkey == pub) return f;
    }
    return null;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static String _b64url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static Uint8List _b64urlBytes(String s) {
    var t = s.replaceAll('-', '+').replaceAll('_', '/');
    while (t.length % 4 != 0) {
      t += '=';
    }
    return base64Url.decode(t);
  }

  String _uid() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      Random().nextInt(0xffffff).toRadixString(36);

  /// 生成邀请：随机 32 字节共享密钥 + 本机公钥。
  Future<String> makeInvite(Account acc) async {
    final rand = Random.secure();
    final keyBytes =
        Uint8List.fromList(List.generate(32, (_) => rand.nextInt(256)));
    final friendKey = _b64url(keyBytes);
    _pendingKeys[friendKey] = DateTime.now().toIso8601String();
    final pub = await _pubHex(acc);
    final name = Uri.encodeComponent(acc.displayName);
    return '$proto?v=1&name=$name&pub=$pub&key=$friendKey';
  }

  Future<String> _pubHex(Account acc) async {
    final kp = await AccountService.seedToKeyPair(_b64urlBytes(acc.seedB64));
    return AccountService.publicKeyHex(kp);
  }

  /// 解析邀请文本。
  ({String? error, String? pub, String? key, String? name}) parseInvite(
      String text) {
    final t = (text ?? '').trim();
    if (!t.startsWith(proto)) {
      return (error: '邀请格式不正确', pub: null, key: null, name: null);
    }
    final parts = t.split('?');
    final q = parts.length > 1 ? parts[1] : '';
    final params = <String, String>{};
    q.split('&').forEach((kv) {
      final i = kv.indexOf('=');
      if (i > 0) {
        params[Uri.decodeComponent(kv.substring(0, i))] =
            Uri.decodeComponent(kv.substring(i + 1));
      }
    });
    final pub = params['pub'];
    final key = params['key'];
    if (pub == null || key == null) {
      return (error: '邀请缺少公钥或密钥', pub: null, key: null, name: null);
    }
    if (findPub(pub) != null) {
      return (error: '该好友已存在', pub: null, key: null, name: null);
    }
    return (error: null, pub: pub, key: key, name: params['name'] ?? '新好友');
  }

  /// 导入邀请：添加对方为好友，并回发 friend-req 让对方也加上本机。
  Future<({String? error, Friend? friend})> addByInvite(
      Account acc, String text) async {
    final p = parseInvite(text);
    if (p.error != null) return (error: p.error, friend: null);
    final f = Friend(
      id: _uid(),
      pubkey: p.pub!,
      name: p.name!,
      friendKey: p.key!,
      addedAt: DateTime.now().toIso8601String(),
    );
    _friends.add(f);
    await save();
    try {
      await _send(acc, f, {
        'type': 'friend-req',
        'pub': await _pubHex(acc),
        'name': acc.displayName,
      });
    } catch (_) {}
    return (error: null, friend: f);
  }

  Future<void> remove(String id) async {
    _friends.removeWhere((f) => f.id == id);
    await save();
  }

  /// 加密发送到中继（kind 19324，d-tag + p-tag）。
  Future<void> _send(Account acc, Friend f, Map<String, dynamic> obj) async {
    final seed = _b64urlBytes(f.friendKey);
    final env = await AccountService.encryptData(obj, seed);
    final envelope = {
      'v': 1,
      'type': obj['type'],
      'ts': DateTime.now().toIso8601String(),
      'payload': {'iv': env.iv, 'data': env.data},
    };
    final evt = await _buildEvent(acc, f.pubkey, envelope);
    for (final url in _relays()) {
      try {
        final ws =
            await WebSocket.connect(url).timeout(const Duration(seconds: 4));
        ws.add(jsonEncode(['EVENT', evt]));
        await Future.delayed(const Duration(milliseconds: 200));
        await ws.close();
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _buildEvent(
      Account acc, String targetPub, Map envelope) async {
    final kp = await AccountService.seedToKeyPair(_b64urlBytes(acc.seedB64));
    final pub = await AccountService.publicKeyHex(kp);
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = [
      ['d', friendDTag],
      ['p', targetPub]
    ];
    final content = jsonEncode(envelope);
    final idBytes = await AccountService.sha256(
        utf8.encode(jsonEncode([0, pub, createdAt, friendKind, tags, content])));
    final id = _hex(idBytes);
    final sigB64 = await AccountService.signBytes(kp, utf8.encode(id));
    return {
      'kind': friendKind,
      'created_at': createdAt,
      'tags': tags,
      'content': content,
      'pubkey': pub,
      'id': id,
      'sig': _hex(_b64urlBytes(sigB64)),
    };
  }

  List<String> _relays() => const [
        'wss://relay.damus.io',
        'wss://nos.lol',
      ];

  /// 处理收到的事件（中继订阅回调）：先试 pending（friend-req），再匹配好友。
  Future<void> handleEvent(Account acc, Map<String, dynamic> evt) async {
    if (evt['kind'] != friendKind) return;
    final pubkey = evt['pubkey'] as String?;
    final content = evt['content'] as String?;
    final id = evt['id'] as String? ?? '';
    if (pubkey == null || content == null) return;
    if (_seen.contains(id)) return;
    _seen.add(id);
    if (_seen.length > 200) _seen.removeRange(0, _seen.length - 100);

    if (_pendingKeys.isNotEmpty) {
      for (final entry in _pendingKeys.entries.toList()) {
        try {
          final env = jsonDecode(content) as Map;
          final payload = env['payload'] as Map;
          final obj = await AccountService.decryptData(
            (iv: payload['iv'] as String, data: payload['data'] as String),
            _b64urlBytes(entry.key),
          );
          if (obj is Map &&
              obj['type'] == 'friend-req' &&
              obj['pub'] == pubkey) {
            if (findPub(pubkey) == null) {
              _friends.add(Friend(
                id: _uid(),
                pubkey: pubkey,
                name: (obj['name'] as String?) ?? '新好友',
                friendKey: entry.key,
                addedAt: DateTime.now().toIso8601String(),
              ));
              await save();
            }
            _pendingKeys.remove(entry.key);
            return;
          }
        } catch (_) {}
      }
    }

    final friend = findPub(pubkey);
    if (friend == null) return;
    try {
      final env = jsonDecode(content) as Map;
      final payload = env['payload'] as Map;
      final obj = await AccountService.decryptData(
        (iv: payload['iv'] as String, data: payload['data'] as String),
        _b64urlBytes(friend.friendKey),
      );
      friend.lastMsgAt = (env['ts'] as String?) ??
          DateTime.now().toIso8601String();
      await save();
      onMessage?.call(friend,
          obj is Map ? Map<String, dynamic>.from(obj) : const {});
    } catch (_) {}
  }

  /// 收到好友消息/分享回调（UI 层注入）。
  void Function(Friend friend, Map<String, dynamic> payload)? onMessage;
}
