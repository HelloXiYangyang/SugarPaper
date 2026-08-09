/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 无服务器账号身份（v0.16.0 / S2）
   账号 = 12 词助记词 → PBKDF2 派生种子 → Ed25519 密钥对。
   数据 AES-256-GCM 端到端加密，变更带 Ed25519 签名。纯 Web Crypto 实现，零依赖。 */
(function (g) {
  'use strict';

  const CONSONANTS = ['b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'q', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z'];
  const VOWELS = ['a', 'e', 'i', 'o', 'u', 'y'];
  const WORD_COUNT = 2048;
  const MNEMONIC_LEN = 12;
  const PBKDF2_ITERATIONS = 120000;
  const PBKDF2_SALT = 'sugarpaper-identity-v1';
  const SIGN_PREFIX = 'sugarpaper:';

  // 确定性音节词表（CVC 组合取前 2048 个）：不依赖外部词库，跨设备一致
  const WORDS = (function () {
    const out = [];
    outer:
    for (const c1 of CONSONANTS) {
      for (const v of VOWELS) {
        for (const c2 of CONSONANTS) {
          out.push(c1 + v + c2);
          if (out.length === WORD_COUNT) break outer;
        }
      }
    }
    return out;
  })();
  const WORD_INDEX = new Map(WORDS.map((w, i) => [w, i]));

  const enc = new TextEncoder();
  const dec = new TextDecoder();

  function bytesToBigInt(bytes) {
    let v = 0n;
    for (const b of bytes) v = (v << 8n) | BigInt(b);
    return v;
  }

  function bigIntToBytes(bi, len) {
    const out = new Uint8Array(len);
    let v = bi;
    for (let i = len - 1; i >= 0; i--) {
      out[i] = Number(v & 255n);
      v >>= 8n;
    }
    return out;
  }

  function b64url(bytes) {
    let bin = '';
    for (let i = 0; i < bytes.length; i += 512) {
      bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 512));
    }
    return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function b64urlToBytes(s) {
    const bin = atob(String(s).replace(/-/g, '+').replace(/_/g, '/'));
    const out = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  function bytesToHex(bytes) {
    return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
  }

  function hexToBytes(hex) {
    const out = new Uint8Array(Math.floor(hex.length / 2));
    for (let i = 0; i < out.length; i++) out[i] = parseInt(hex.substr(i * 2, 2), 16);
    return out;
  }

  function normalizeMnemonic(text) {
    const words = String(text || '').trim().toLowerCase().split(/\s+/).filter(Boolean);
    if (words.length !== MNEMONIC_LEN) {
      throw new Error('助记词需为 ' + MNEMONIC_LEN + ' 个词（当前 ' + words.length + ' 个）');
    }
    return words;
  }

  /** 16 字节熵 → 12 词助记词（每词 11 位，共 132 位，含 4 位填充） */
  function entropyToMnemonic(bytes) {
    if (!bytes || bytes.length !== 16) throw new Error('熵长度必须为 16 字节');
    let v = bytesToBigInt(bytes) << 4n;
    const words = [];
    for (let i = 0; i < MNEMONIC_LEN; i++) {
      words.push(WORDS[Number(v & 2047n)]);
      v >>= 11n;
    }
    return words;
  }

  /** 12 词助记词 → 16 字节熵（校验词表与长度） */
  function mnemonicToEntropy(words) {
    let v = 0n;
    words.forEach((w, i) => {
      const idx = WORD_INDEX.get(w);
      if (idx == null) throw new Error('助记词含无效词：' + w);
      v |= BigInt(idx) << BigInt(11 * i); // 第 i 个词对应低位第 i 段（与熵→词方向一致）
    });
    v >>= 4n; // 丢弃填充位
    return bigIntToBytes(v, 16);
  }

  async function mnemonicToSeed(words) {
    const key = await g.crypto.subtle.importKey('raw', enc.encode(words.join(' ')), 'PBKDF2', false, ['deriveBits']);
    const bits = await g.crypto.subtle.deriveBits({
      name: 'PBKDF2',
      salt: enc.encode(PBKDF2_SALT),
      iterations: PBKDF2_ITERATIONS,
      hash: 'SHA-256'
    }, key, 256);
    return new Uint8Array(bits);
  }

  // Ed25519 私钥 PKCS8 DER 固定前缀（SEQUENCE/INTEGER/OID/OCTET STRING + 32 字节种子）
  const PKCS8_ED25519_PREFIX = Uint8Array.from([
    0x30, 0x2e, 0x02, 0x01, 0x00,
    0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70,
    0x04, 0x22, 0x04, 0x20
  ]);

  async function seedToKeyPair(seed) {
    if (!seed || seed.length !== 32) throw new Error('种子长度必须为 32 字节');
    const der = new Uint8Array(48);
    der.set(PKCS8_ED25519_PREFIX, 0);
    der.set(seed, 16);
    const privateKey = await g.crypto.subtle.importKey('pkcs8', der, { name: 'Ed25519' }, true, ['sign']);
    // 公钥由种子纯 JS 推导（Ed25519 基点标量乘），跨浏览器/Node 一致，不依赖 CryptoKey.publicKey
    const publicKeyRaw = await ed25519PublicKey(seed);
    return { privateKey, publicKeyRaw, pubkey: b64url(publicKeyRaw) };
  }

  /* ---------- Ed25519 公钥推导（RFC 8032，纯 BigInt 实现） ---------- */
  const FIELD_P = (1n << 255n) - 19n;
  const ED_D = ((-121665n * modpow(121666n, FIELD_P - 2n)) % FIELD_P + FIELD_P) % FIELD_P;
  const BASE_X = 15112221349535400772501151409588531511454012693041857206046113283949847762202n;
  const BASE_Y = 46316835694926478169428394003475163141307993866256225615783033603165251855960n;

  function modpow(b, e) {
    let r = 1n;
    b = ((b % FIELD_P) + FIELD_P) % FIELD_P;
    while (e > 0n) {
      if (e & 1n) r = (r * b) % FIELD_P;
      b = (b * b) % FIELD_P;
      e >>= 1n;
    }
    return r;
  }

  function modInv(x) {
    return modpow(x, FIELD_P - 2n);
  }

  function pointAdd(p1, p2) {
    const [x1, y1] = p1;
    const [x2, y2] = p2;
    const x1y2 = (x1 * y2) % FIELD_P;
    const y1x2 = (y1 * x2) % FIELD_P;
    const x1x2 = (x1 * x2) % FIELD_P;
    const y1y2 = (y1 * y2) % FIELD_P;
    const dxy = (ED_D * x1x2 % FIELD_P * y1y2) % FIELD_P;
    const x3 = ((x1y2 + y1x2) % FIELD_P) * modInv((1n + dxy) % FIELD_P) % FIELD_P;
    const y3 = ((y1y2 + x1x2) % FIELD_P) * modInv((1n - dxy + FIELD_P) % FIELD_P) % FIELD_P;
    return [x3, y3];
  }

  function scalarmultBase(k) {
    let r = [0n, 1n];
    let base = [BASE_X, BASE_Y];
    for (let i = 0; i < 256; i++) {
      if ((k >> BigInt(i)) & 1n) r = pointAdd(r, base);
      base = pointAdd(base, base);
    }
    return r;
  }

  /** RFC 8032：seed → SHA-512 → clamp → a·B → 编码为 32 字节公钥 */
  async function ed25519PublicKey(seed) {
    const h = new Uint8Array(await g.crypto.subtle.digest('SHA-512', seed));
    const a = new Uint8Array(32);
    a.set(h.subarray(0, 32));
    a[0] &= 248;
    a[31] &= 127;
    a[31] |= 64;
    let k = 0n;
    for (let i = 0; i < 32; i++) k |= BigInt(a[i]) << BigInt(8 * i); // RFC 8032：小端标量
    const [x, y] = scalarmultBase(k);
    const out = new Uint8Array(32);
    let yv = y;
    for (let i = 0; i < 32; i++) {
      out[i] = Number(yv & 255n);
      yv >>= 8n;
    }
    if ((x & 1n) === 1n) out[31] |= 0x80;
    return out;
  }

  async function createAccount() {
    const entropy = new Uint8Array(16);
    g.crypto.getRandomValues(entropy);
    const mnemonic = entropyToMnemonic(entropy);
    const seed = await mnemonicToSeed(mnemonic);
    const kp = await seedToKeyPair(seed);
    return { mnemonic, seed, kp };
  }

  async function restoreAccount(mnemonicText) {
    const words = normalizeMnemonic(mnemonicText);
    mnemonicToEntropy(words); // 提前校验词表
    const seed = await mnemonicToSeed(words);
    const kp = await seedToKeyPair(seed);
    return { mnemonic: words, seed, kp };
  }

  async function sha256(bytes) {
    const d = await g.crypto.subtle.digest('SHA-256', bytes);
    return new Uint8Array(d);
  }

  /** 端到端加密：种子 → SHA-256 → AES-256-GCM */
  async function encryptData(plainObj, seed) {
    const keyBytes = await sha256(seed);
    const key = await g.crypto.subtle.importKey('raw', keyBytes, 'AES-GCM', false, ['encrypt']);
    const iv = new Uint8Array(12);
    g.crypto.getRandomValues(iv);
    const ct = await g.crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, enc.encode(JSON.stringify(plainObj)));
    return { iv: b64url(iv), data: b64url(new Uint8Array(ct)) };
  }

  async function decryptData(env, seed) {
    const keyBytes = await sha256(seed);
    const key = await g.crypto.subtle.importKey('raw', keyBytes, 'AES-GCM', false, ['decrypt']);
    const iv = b64urlToBytes(env.iv);
    const ct = b64urlToBytes(env.data);
    const pt = await g.crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ct);
    return JSON.parse(dec.decode(pt));
  }

  async function signBytes(privateKey, bytes, out) {
    const s = await g.crypto.subtle.sign('Ed25519', privateKey, bytes);
    const u = new Uint8Array(s);
    return out === 'hex' ? bytesToHex(u) : b64url(u);
  }

  async function verifyBytes(pubkeyB64, bytes, sig, sigIsHex) {
    const pub = await g.crypto.subtle.importKey('raw', b64urlToBytes(pubkeyB64), { name: 'Ed25519' }, false, ['verify']);
    const sigBytes = sigIsHex ? hexToBytes(sig) : b64urlToBytes(sig);
    return g.crypto.subtle.verify('Ed25519', pub, sigBytes, bytes);
  }

  function accountShortId(pubkeyB64) {
    if (!pubkeyB64) return '';
    return pubkeyB64.slice(0, 4) + '…' + pubkeyB64.slice(-4);
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.account = {
    WORDS,
    WORD_COUNT,
    MNEMONIC_LEN,
    entropyToMnemonic,
    mnemonicToEntropy,
    mnemonicToSeed,
    seedToKeyPair,
    createAccount,
    restoreAccount,
    encryptData,
    decryptData,
    signBytes,
    verifyBytes,
    sha256,
    b64url,
    b64urlToBytes,
    bytesToHex,
    hexToBytes,
    accountShortId,
    normalizeMnemonic
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      entropyToMnemonic,
      mnemonicToEntropy,
      mnemonicToSeed,
      seedToKeyPair,
      createAccount,
      restoreAccount,
      encryptData,
      decryptData,
      signBytes,
      verifyBytes,
      sha256,
      ed25519PublicKey,
      b64url,
      b64urlToBytes,
      bytesToHex,
      hexToBytes,
      accountShortId,
      normalizeMnemonic,
      WORDS
    };
  }
})(typeof window !== 'undefined' ? window : globalThis);
