/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/account_service.dart';
import 'package:sugarpaper/data/sync_service.dart';
import 'package:sugarpaper/models/account.dart';

void main() {
  group('AccountService', () {
    test('词表：确定性生成 2048 词且互不相同', () {
      final words = AccountService.words;
      expect(words.length, 2048);
      expect(words.toSet().length, 2048);
      // 与网页版一致的示例词（CVC 顺序第一个应为 bab）
      expect(words.first, 'bab');
      expect(words.last, 'ven');
    });

    test('助记词 ↔ 熵往返一致', () {
      final entropy = Uint8List.fromList(
        List<int>.generate(16, (i) => i * 7 + 3),
      );
      final mnemonic = AccountService.entropyToMnemonic(entropy);
      expect(mnemonic.length, 12);
      final back = AccountService.mnemonicToEntropy(mnemonic);
      expect(back, entropy);
    });

    test('创建账号 → 助记词恢复账号 → 同一公钥', () async {
      final created = await AccountService.createAccount();
      final mnemonicText = created.mnemonic.join(' ');
      final restored = await AccountService.restoreAccount(mnemonicText);
      final pk1 = await AccountService.publicKeyB64(created.keyPair);
      final pk2 = await AccountService.publicKeyB64(restored.keyPair);
      expect(pk1, pk2);
    });

    test('无效助记词被拒绝', () {
      expect(
        () => AccountService.restoreAccount('a b c'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('AES-GCM 加密解密往返', () async {
      final created = await AccountService.createAccount();
      final seed = created.seed;
      final env = await AccountService.encryptData({'a': 1, 'b': '糖纸'}, seed);
      final decrypted = await AccountService.decryptData(env, seed);
      expect(decrypted['a'], 1);
      expect(decrypted['b'], '糖纸');
    });

    test('Ed25519 签名与验签', () async {
      final created = await AccountService.createAccount();
      final pubkey = await AccountService.publicKeyB64(created.keyPair);
      final message = utf8.encode('sugarpaper:1:iv:data');
      final sig = await AccountService.signBytes(created.keyPair, message);
      final ok = await AccountService.verifyBytes(pubkey, message, sig);
      expect(ok, isTrue);
      // 篡改消息应验签失败
      final bad = await AccountService.verifyBytes(
        pubkey,
        utf8.encode('sugarpaper:2:iv:data'),
        sig,
      );
      expect(bad, isFalse);
    });

    test('Nostr 公钥 hex 与网页版跨端向量一致', () async {
      const mnemonic = 'bac bab bac bab bac bab bac bab bac bab bac bab';
      final restored = await AccountService.restoreAccount(mnemonic);
      final hex = await AccountService.publicKeyHex(restored.keyPair);
      // 由网页版 account.js 同种子推导（v0.26.0 互通校验向量）
      expect(
        hex,
        '9695c460e97e86ac847ef972632a3fb8a2c503fd29efcc42d7a875ad27929316',
      );
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hex), isTrue);
    });
  });

  group('SyncService 合并', () {
    test('mergeById 按 updatedAt 后写覆盖（LWW）', () async {
      final sync = SyncService();
      // 通过私有方法不可直接访问，改用公开信封逻辑验证：
      // 构造两个同 id 记录，更新较晚的应胜出
      final old_ = {
        'id': 't1',
        'title': '旧',
        'updatedAt': '2026-08-01T00:00:00',
      };
      final new_ = {
        'id': 't1',
        'title': '新',
        'updatedAt': '2026-08-02T00:00:00',
      };
      final merged = sync.mergeById(
        [Map<String, dynamic>.from(old_)],
        [Map<String, dynamic>.from(new_)],
      );
      expect(merged.length, 1);
      expect(merged.first['title'], '新');
    });

    test('Nostr 事件 pubkey 使用 64 位 hex（公共中继 NIP-01）', () async {
      final created = await AccountService.createAccount();
      final acc = Account(
        pubkey: await AccountService.publicKeyB64(created.keyPair),
        seedB64: base64Url
            .encode(created.seed)
            .replaceAll('+', '-')
            .replaceAll('/', '_')
            .replaceAll('=', ''),
        mnemonic: created.mnemonic.join(' '),
        displayName: '测试',
      );
      final event = await SyncService().nostrEvent(acc, {'app': 'SugarPaper'});
      expect(event['pubkey'], isA<String>());
      expect(
        RegExp(r'^[a-f0-9]{64}$').hasMatch(event['pubkey'] as String),
        isTrue,
      );
      expect(event['id'], isA<String>());
      expect((event['id'] as String).length, 64);
    });
  });
}
