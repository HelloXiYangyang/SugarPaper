/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 无服务器账号身份（v0.16.0 对齐网页版 `account.js`）：
/// 账号 = 12 词助记词 → PBKDF2 派生种子 → Ed25519 密钥对；
/// 数据 AES-256-GCM 端到端加密，变更带 Ed25519 签名。
class AccountService {
  static const int wordCount = 2048;
  static const int mnemonicLen = 12;
  static const int pbkdf2Iterations = 120000;
  static const String pbkdf2Salt = 'sugarpaper-identity-v1';
  static const String signPrefix = 'sugarpaper:';

  static const _consonants = [
    'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm',
    'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z',
  ];
  static const _vowels = ['a', 'e', 'i', 'o', 'u', 'y'];

  /// 确定性音节词表（CVC 组合取前 2048 个），与网页版生成顺序一致。
  static List<String> get words {
    final out = <String>[];
    outer:
    for (final c1 in _consonants) {
      for (final v in _vowels) {
        for (final c2 in _consonants) {
          out.add('$c1$v$c2');
          if (out.length == wordCount) break outer;
        }
      }
    }
    return out;
  }

  static List<String> _normalizeMnemonic(String text) {
    final words = text.trim().toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.length != mnemonicLen) {
      throw ArgumentError('助记词需为 $mnemonicLen 个词（当前 ${words.length} 个）');
    }
    return words;
  }

  /// 16 字节熵 → 12 词助记词（每词 11 位，共 132 位，含 4 位填充）。
  static List<String> entropyToMnemonic(Uint8List bytes) {
    if (bytes.length != 16) throw ArgumentError('熵长度必须为 16 字节');
    final all = words;
    var value = _bytesToBigInt(bytes) << 4;
    final out = <String>[];
    for (var i = 0; i < mnemonicLen; i++) {
      final idx = (value & BigInt.from(2047)).toInt();
      out.add(all[idx]);
      value = value >> 11;
    }
    return out;
  }

  /// 12 词助记词 → 16 字节熵（校验词表与长度）。
  static Uint8List mnemonicToEntropy(List<String> mnemonicWords) {
    final all = words;
    final index = <String, int>{};
    for (var i = 0; i < all.length; i++) {
      index[all[i]] = i;
    }
    var value = BigInt.zero;
    for (var i = 0; i < mnemonicWords.length; i++) {
      final idx = index[mnemonicWords[i]];
      if (idx == null) {
        throw ArgumentError('助记词含无效词：${mnemonicWords[i]}');
      }
      value = value | (BigInt.from(idx) << (11 * i));
    }
    value = value >> 4; // 丢弃填充位
    return _bigIntToBytes(value, 16);
  }

  /// 助记词 → 32 字节种子（PBKDF2-HMAC-SHA256，120k 次）。
  static Future<Uint8List> mnemonicToSeed(List<String> words) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: pbkdf2Iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKeyFromPassword(
      password: words.join(' '),
      nonce: utf8.encode(pbkdf2Salt),
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  /// 种子 → Ed25519 密钥对（RFC 8032，seed 即私钥种子）。
  static Future<SimpleKeyPair> seedToKeyPair(Uint8List seed) async {
    if (seed.length != 32) throw ArgumentError('种子长度必须为 32 字节');
    return Ed25519().newKeyPairFromSeed(seed);
  }

  /// 创建新账号：随机熵 → 助记词 → 种子 → 密钥对。
  static Future<({List<String> mnemonic, Uint8List seed, SimpleKeyPair keyPair})>
      createAccount() async {
    final entropy = Uint8List.fromList(
      List.generate(16, (_) => math.Random.secure().nextInt(256)),
    );
    final mnemonic = entropyToMnemonic(entropy);
    final seed = await mnemonicToSeed(mnemonic);
    final keyPair = await seedToKeyPair(seed);
    return (mnemonic: mnemonic, seed: seed, keyPair: keyPair);
  }

  /// 用助记词恢复账号。
  static Future<({List<String> mnemonic, Uint8List seed, SimpleKeyPair keyPair})>
      restoreAccount(String mnemonicText) async {
    final words = _normalizeMnemonic(mnemonicText);
    mnemonicToEntropy(words); // 提前校验词表
    final seed = await mnemonicToSeed(words);
    final keyPair = await seedToKeyPair(seed);
    return (mnemonic: words, seed: seed, keyPair: keyPair);
  }

  static Future<Uint8List> sha256(List<int> bytes) async =>
      Uint8List.fromList(await Sha256().hash(bytes).then((h) => h.bytes));

  /// 端到端加密：key = SHA-256(seed)，AES-256-GCM，12 字节随机 IV。
  static Future<({String iv, String data})> encryptData(
    Object plainObj,
    Uint8List seed,
  ) async {
    final aesGcm = AesGcm.with256bits();
    final keyBytes = await sha256(seed);
    final secretKey = await aesGcm.newSecretKeyFromBytes(keyBytes);
    final iv = Uint8List.fromList(
      List.generate(12, (_) => math.Random.secure().nextInt(256)),
    );
    final encrypted = await aesGcm.encrypt(
      utf8.encode(jsonEncode(plainObj)),
      secretKey: secretKey,
      nonce: iv,
    );
    // 与网页版 WebCrypto 格式兼容：data = cipherText || 认证标签(16B)
    final combined = <int>[...encrypted.cipherText, ...encrypted.mac.bytes];
    return (
      iv: _b64url(iv),
      data: _b64url(combined),
    );
  }

  static Future<dynamic> decryptData(
    ({String iv, String data}) env,
    Uint8List seed,
  ) async {
    final aesGcm = AesGcm.with256bits();
    final keyBytes = await sha256(seed);
    final secretKey = await aesGcm.newSecretKeyFromBytes(keyBytes);
    final all = _b64urlToBytes(env.data);
    final tagLength = 16;
    final cipherText = all.sublist(0, all.length - tagLength);
    final mac = all.sublist(all.length - tagLength);
    final decrypted = await aesGcm.decrypt(
      SecretBox(
        cipherText,
        nonce: _b64urlToBytes(env.iv),
        mac: Mac(mac),
      ),
      secretKey: secretKey,
    );
    return jsonDecode(utf8.decode(decrypted));
  }

  /// Ed25519 签名。
  static Future<String> signBytes(SimpleKeyPair keyPair, List<int> bytes) async {
    final sig = await Ed25519().sign(bytes, keyPair: keyPair);
    return _b64url(sig.bytes);
  }

  /// 验签。
  static Future<bool> verifyBytes(
    String pubkeyB64,
    List<int> bytes,
    String sigB64,
  ) async {
    try {
      final publicKey = SimplePublicKey(_b64urlToBytes(pubkeyB64),
          type: KeyPairType.ed25519);
      return await Ed25519().verify(
        bytes,
        signature: Signature(_b64urlToBytes(sigB64), publicKey: publicKey),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<String> publicKeyB64(SimpleKeyPair keyPair) async {
    final pk = await keyPair.extractPublicKey();
    return _b64url(pk.bytes);
  }

  static String accountShortId(String pubkeyB64) {
    if (pubkeyB64.isEmpty) return '';
    if (pubkeyB64.length <= 8) return pubkeyB64;
    return '${pubkeyB64.substring(0, 4)}…${pubkeyB64.substring(pubkeyB64.length - 4)}';
  }

  // ---------- 工具 ----------

  static BigInt _bytesToBigInt(List<int> bytes) {
    var v = BigInt.zero;
    for (final b in bytes) {
      v = (v << 8) | BigInt.from(b);
    }
    return v;
  }

  static Uint8List _bigIntToBytes(BigInt bi, int len) {
    final out = Uint8List(len);
    var v = bi;
    for (var i = len - 1; i >= 0; i--) {
      out[i] = (v & BigInt.from(255)).toInt();
      v >>= 8;
    }
    return out;
  }

  static String _b64url(List<int> bytes) => base64UrlEncode(bytes)
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');

  static Uint8List _b64urlToBytes(String s) {
    var b = s.replaceAll('-', '+').replaceAll('_', '/');
    while (b.length % 4 != 0) {
      b += '=';
    }
    return base64Url.decode(b);
  }
}
