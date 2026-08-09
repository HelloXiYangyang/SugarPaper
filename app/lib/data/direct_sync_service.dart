/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/account.dart';
import 'account_service.dart';
import 'store.dart';
import 'sync_service.dart';

/// WebRTC 在线直连（v0.17.1 对齐网页版 sync.js direct）：
/// 两台在线设备经 Nostr 中继交换 SDP 信令（kind 19323），
/// 建立 P2P DataChannel 后直接交换加密快照；中继只转发信令、不接触数据。
class DirectSyncService {
  static const signalKind = 19323;
  static const signalDTag = 'sugarpaper:signal';

  final SyncService _sync = SyncService();

  String status = 'off'; // off | listening | connecting | connected | error
  String? peer;
  String? lastError;

  WebSocket? _ws;
  RTCPeerConnection? _pc;
  RTCDataChannel? _channel;
  String? _session;
  bool _gotOffer = false;
  Timer? _timeout;
  bool _running = false;

  bool get isActive =>
      status == 'listening' || status == 'connecting' || status == 'connected';

  List<String> _relays(AppStore store) =>
      store.settings.relays.isNotEmpty
          ? store.settings.relays
          : SyncService.defaultRelays;

  Future<void> start(AppStore store, {void Function()? onChanged}) async {
    final acc = store.account;
    if (acc == null) {
      status = 'error';
      lastError = '请先创建或恢复账号';
      onChanged?.call();
      return;
    }
    if (isActive) return;
    stop();
    _running = true;
    status = 'listening';
    lastError = null;
    onChanged?.call();
    final url = _relays(store).first;
    try {
      _ws = await WebSocket.connect(url).timeout(const Duration(seconds: 8));
      _session = 'd${math.Random().nextInt(1 << 30).toRadixString(36)}';
      _pc = await createPeerConnection(const {
        'iceServers': [],
        'sdpSemantics': 'unified-plan',
      });
      _pc!.onIceCandidate = (candidate) {
        if (candidate.candidate != null && _running) {
          _sendSignal(acc, {
            'type': 'candidate',
            'candidate': candidate.toMap(),
          });
        }
      };
      _pc!.onDataChannel = (channel) {
        _setupChannel(channel, store, onChanged);
      };
      _ws!.listen(
        (data) => _handleSignalMessage(data, acc, store, onChanged),
        onError: (_) {},
      );
      _ws!.add(jsonEncode([
        'REQ',
        'sp-signal',
        {
          'kinds': [signalKind],
          'authors': [await AccountService.publicKeyHex(
            await AccountService.seedToKeyPair(
              Uint8List.fromList(_b64urlToBytes(acc.seedB64)),
            ),
          )],
          '#d': [signalDTag],
          'limit': 30,
        },
      ]));

      // 对称创建 DataChannel（negotiated + 固定 id 0），两端自动配对
      final dc = await _pc!.createDataChannel(
        'sugarpaper-sync',
        RTCDataChannelInit()
          ..negotiated = true
          ..id = 0,
      );
      _setupChannel(dc, store, onChanged);

      // 稍等片刻：对方已发 offer 则应答，否则自己发 offer（处理 glare）
      Timer(const Duration(milliseconds: 500), () async {
        if (_gotOffer || _pc == null || !_running) return;
        try {
          final offer = await _pc!.createOffer();
          await _pc!.setLocalDescription(offer);
          _sendSignal(acc, {'type': 'offer', 'sdp': offer.sdp});
        } catch (_) {}
      });

      _timeout = Timer(const Duration(seconds: 20), () {
        if (status == 'listening' || status == 'connecting') {
          status = 'error';
          lastError = '等待对方设备超时（两端需同时点击「直连」）';
          stop();
          onChanged?.call();
        }
      });
    } catch (e) {
      status = 'error';
      lastError = '直连失败：${e.toString()}';
      stop();
      onChanged?.call();
    }
  }

  void stop() {
    _running = false;
    _timeout?.cancel();
    _timeout = null;
    try {
      _channel?.close();
    } catch (_) {}
    try {
      _pc?.close();
    } catch (_) {}
    try {
      _ws?.close();
    } catch (_) {}
    _channel = null;
    _pc = null;
    _ws = null;
    _session = null;
    peer = null;
    _gotOffer = false;
    status = 'off';
  }

  // ---------- 信令 ----------

  Future<void> _sendSignal(Account acc, Map<String, dynamic> obj) async {
    final ws = _ws;
    if (ws == null || _session == null) return;
    try {
      final event = await _signSignalEvent(acc, obj);
      ws.add(jsonEncode(['EVENT', event]));
    } catch (_) {}
  }

  /// 构造 Nostr 信令事件并签名（对齐网页版 nostrSignalEvent）。
  Future<Map<String, dynamic>> _signSignalEvent(
    Account acc,
    Map<String, dynamic> obj,
  ) async {
    final seed = Uint8List.fromList(_b64urlToBytes(acc.seedB64));
    final keyPair = await AccountService.seedToKeyPair(seed);
    final pubkeyHex = await AccountService.publicKeyHex(keyPair);
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final content = jsonEncode({
      'session': _session,
      'type': obj['type'],
      'sdp': obj['sdp'],
      'candidate': obj['candidate'],
    });
    final tags = [
      ['d', signalDTag],
      ['t', 'sugarpaper'],
    ];
    final idBytes = await AccountService.sha256(
      utf8.encode(
        jsonEncode([0, pubkeyHex, createdAt, signalKind, tags, content]),
      ),
    );
    final id = _bytesToHex(idBytes);
    final sig = await AccountService.signBytes(keyPair, _hexToBytes(id));
    return {
      'kind': signalKind,
      'created_at': createdAt,
      'tags': tags,
      'content': content,
      'pubkey': pubkeyHex,
      'id': id,
      'sig': sig,
    };
  }

  void _handleSignalMessage(
    dynamic raw,
    Account acc,
    AppStore store,
    void Function()? onChanged,
  ) {
    try {
      final msg = jsonDecode(raw as String);
      if (msg is! List || msg.isEmpty || msg[0] != 'EVENT') return;
      final evt = msg[1];
      if (evt is! Map || evt['kind'] != signalKind) return;
      final sig = jsonDecode(evt['content'] as String);
      if (sig is! Map || sig['type'] == null) return;
      final pc = _pc;
      if (pc == null || _session == null) return;

      _handleSignal(
        acc,
        store,
        pc,
        Map<String, dynamic>.from(sig),
        onChanged,
      );
    } catch (_) {}
  }

  Future<void> _handleSignal(
    Account acc,
    AppStore store,
    RTCPeerConnection pc,
    Map<String, dynamic> sig,
    void Function()? onChanged,
  ) async {
    try {
      final type = sig['type'] as String;
      if (type == 'offer') {
        _gotOffer = true;
        if (status == 'listening') {
          status = 'connecting';
          onChanged?.call();
        }
        // glare：先回滚本地 offer 再应答
        if (pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await pc.setLocalDescription(RTCSessionDescription('rollback', ''));
        }
        await pc.setRemoteDescription(
          RTCSessionDescription('offer', sig['sdp'] as String),
        );
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        _sendSignal(acc, {'type': 'answer', 'sdp': answer.sdp});
      } else if (type == 'answer') {
        if (pc.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          await pc.setRemoteDescription(
            RTCSessionDescription('answer', sig['sdp'] as String),
          );
        }
      } else if (type == 'candidate') {
        final cand = sig['candidate'];
        if (cand is Map && cand['candidate'] != null) {
          try {
            await pc.addCandidate(
              RTCIceCandidate(
                cand['candidate'] as String? ?? '',
                cand['sdpMid'] as String? ?? '',
                (cand['sdpMLineIndex'] as num?)?.toInt() ?? 0,
              ),
            );
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // ---------- DataChannel ----------

  void _setupChannel(
    RTCDataChannel channel,
    AppStore store,
    void Function()? onChanged,
  ) {
    _channel = channel;
    channel.onDataChannelState = (state) async {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        final acc = store.account;
        if (acc == null) return;
        status = 'connected';
        peer = AccountService.accountShortId(acc.pubkey);
        onChanged?.call();
        // 发送本地加密快照
        try {
          final env = await _sync.buildEnvelope(store);
          await channel.send(RTCDataChannelMessage(jsonEncode(env)));
        } catch (_) {}
      }
    };
    channel.onMessage = (dynamic data) async {
      final acc = store.account;
      if (acc == null) return;
      String text;
      text = data.text;
      try {
        final env = jsonDecode(text);
        if (env is! Map) return;
        if (!await _sync.verifyEnvelope(
            Map<String, dynamic>.from(env), acc.pubkey)) {
          return;
        }
        final seed = Uint8List.fromList(_b64urlToBytes(acc.seedB64));
        final payload = await AccountService.decryptData(
          (
            iv: env['iv'] as String,
            data: env['data'] as String,
          ),
          seed,
        ) as Map<String, dynamic>;
        _applyRemote(store, payload);
        final remoteVersion = (payload['version'] as num?)?.toInt() ?? 0;
        store.updateAccount({
          'version': remoteVersion > (store.account?.version ?? 0)
              ? remoteVersion
              : store.account?.version,
          'lastSyncAt': DateTime.now().toIso8601String(),
        });
        onChanged?.call();
      } catch (_) {}
    };
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
    store.replaceAll(
      tasks: _sync.mergeById(
        store.tasks.map((t) => t.toJson()).toList(),
        remoteTasks,
      ),
      notes: _sync.mergeById(
        store.notes.map((n) => n.toJson()).toList(),
        remoteNotes,
      ),
      focusSessions: _sync.mergeById(
        store.focusSessions.map((s) => s.toJson()).toList(),
        remoteFocus,
      ),
    );
  }

  static Uint8List _b64urlToBytes(String s) {
    var b = s.replaceAll('-', '+').replaceAll('_', '/');
    while (b.length % 4 != 0) {
      b += '=';
    }
    return base64Url.decode(b);
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
