/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 好友直连与端到端通信（v0.33.0，S18 模块二）
   预共享密钥模式：A 生成邀请（含共享密钥），B 导入后自动回发 friend-req，
   双方以同一对称密钥 AES-GCM 加密消息/分享，经 Nostr 中继（kind 19324）转发密文。
   好友列表仅存本机 localStorage；中继只见密文。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const account = S.account;
  const store = S.store;
  const util = S.util;

  const FRIEND_KIND = 19324;
  const FRIEND_D_TAG = 'sugarpaper:friend';
  const PROTO = 'sugarpaper://friend';
  const STORAGE_KEY = 'sugarpaper:friends';
  const PENDING_KEY = 'sugarpaper:friend-pending';
  const SEEN_KEY = 'sugarpaper:friend-seen';

  const callbacks = {
    onMessage: null, // (friend, text) => void
    onShareTask: null, // (friend, task) => void
    onChanged: null // 好友列表变化（刷新 UI）
  };

  let friends = [];
  let _seen = [];
  let _subWs = [];
  let _subscribed = false;
  let _myPubHex = null;

  function load() {
    try { friends = JSON.parse(g.localStorage.getItem(STORAGE_KEY) || '[]'); } catch (e) { friends = []; }
    try { _seen = JSON.parse(g.localStorage.getItem(SEEN_KEY) || '[]'); } catch (e) { _seen = []; }
  }
  function save() {
    try { g.localStorage.setItem(STORAGE_KEY, JSON.stringify(friends)); } catch (e) { /* 忽略 */ }
    if (callbacks.onChanged) { try { callbacks.onChanged(); } catch (e) { /* 忽略 */ } }
  }
  function pendingKeys() {
    try { return JSON.parse(g.localStorage.getItem(PENDING_KEY) || '[]'); } catch (e) { return []; }
  }
  function savePending(list) {
    try { g.localStorage.setItem(PENDING_KEY, JSON.stringify(list)); } catch (e) { /* 忽略 */ }
  }
  function markSeen(id) {
    if (_seen.indexOf(id) >= 0) return;
    _seen.push(id);
    if (_seen.length > 200) _seen = _seen.slice(-100);
    try { g.localStorage.setItem(SEEN_KEY, JSON.stringify(_seen)); } catch (e) { /* 忽略 */ }
  }
  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function relays() {
    const s = store.state.settings.sync;
    if (s && Array.isArray(s.relays) && s.relays.length) return s.relays.slice();
    if (S.sync && S.sync.DEFAULT_RELAYS) return S.sync.DEFAULT_RELAYS.slice();
    return [];
  }

  function list() { return friends.slice(); }
  function find(id) { return friends.find((f) => f.id === id); }
  function findPub(pub) { return friends.find((f) => f.pubkey === pub); }

  /** 从种子派生本机公钥（hex，缓存） */
  async function ensurePubHex() {
    if (_myPubHex) return _myPubHex;
    const acc = store.state.account;
    if (!acc) return null;
    const kp = await account.seedToKeyPair(account.b64urlToBytes(acc.seedB64));
    _myPubHex = account.bytesToHex(kp.publicKeyRaw);
    return _myPubHex;
  }

  /** 生成邀请：随机 32 字节共享密钥，保存为待确认，返回邀请文本 */
  async function makeInvite() {
    const pub = await ensurePubHex();
    if (!pub) return { error: '请先创建账号（设置页 → 账号与同步）' };
    const keyBytes = new Uint8Array(32);
    g.crypto.getRandomValues(keyBytes);
    const friendKey = account.b64url(keyBytes);
    const pending = pendingKeys();
    pending.push({ key: friendKey, ts: new Date().toISOString() });
    savePending(pending);
    const name = encodeURIComponent(store.state.settings.deviceName || '糖纸用户');
    return { text: PROTO + '?v=1&name=' + name + '&pub=' + pub + '&key=' + friendKey };
  }

  /** 解析邀请文本 */
  function parseInvite(text) {
    const t = String(text || '').trim();
    if (t.indexOf(PROTO) !== 0) return { error: '邀请格式不正确' };
    const q = t.split('?')[1] || '';
    const params = {};
    q.split('&').forEach((kv) => {
      const i = kv.indexOf('=');
      if (i > 0) params[decodeURIComponent(kv.slice(0, i))] = decodeURIComponent(kv.slice(i + 1));
    });
    if (!params.pub || !params.key) return { error: '邀请缺少公钥或密钥' };
    if (findPub(params.pub)) return { error: '该好友已存在' };
    return { pub: params.pub, key: params.key, name: params.name || '新好友', v: params.v || 1 };
  }

  /** B 导入邀请：添加 A 为好友，并用同一密钥回发 friend-req，让 A 也加上 B */
  async function addByInvite(text) {
    const parsed = parseInvite(text);
    if (parsed.error) return parsed;
    const pub = await ensurePubHex();
    if (!pub) return { error: '请先创建账号' };
    const f = { id: uid(), pubkey: parsed.pub, name: parsed.name, friendKey: parsed.key, addedAt: new Date().toISOString(), lastMsgAt: null };
    friends.push(f);
    save();
    // 回发 friend-req（用同一共享密钥加密，仅含自我介绍）
    try {
      await _send(f, { type: 'friend-req', pub, name: store.state.settings.deviceName || '糖纸用户' });
    } catch (e) { /* 回执失败不影响本地添加 */ }
    return { ok: true, friend: f };
  }

  function remove(id) {
    friends = friends.filter((f) => f.id !== id);
    save();
  }

  /** 发送文本消息 */
  async function sendMessage(friendId, text) {
    const f = find(friendId);
    if (!f) return { error: '好友不存在' };
    const msg = await _send(f, { type: 'msg', text });
    f.lastMsgAt = new Date().toISOString();
    save();
    return msg;
  }

  /** 分享作业（加密发送任务对象，接收方可直接导入） */
  async function shareTask(friendId, task) {
    const f = find(friendId);
    if (!f) return { error: '好友不存在' };
    return _send(f, { type: 'share-task', task: taskPayload(task) });
  }

  function taskPayload(t) {
    const p = {};
    ['subject', 'title', 'subtitle', 'dueDate', 'priority', 'taskType', 'images'].forEach((k) => {
      if (t[k] !== undefined && t[k] !== null && t[k] !== '') p[k] = t[k];
    });
    return p;
  }

  /** 构建并广播 Nostr 事件（kind 19324，d-tag + p-tag 指向接收方） */
  async function buildFriendEvent(targetPub, envelope) {
    const acc = store.state.account;
    const seed = account.b64urlToBytes(acc.seedB64);
    const kp = await account.seedToKeyPair(seed);
    const pubHex = await ensurePubHex();
    const created_at = Math.floor(Date.now() / 1000);
    const tags = [['d', FRIEND_D_TAG], ['p', targetPub]];
    const content = JSON.stringify(envelope);
    const idBytes = await account.sha256(new TextEncoder().encode(
      JSON.stringify([0, pubHex, created_at, FRIEND_KIND, tags, content])));
    const id = account.bytesToHex(idBytes);
    const sig = await account.signBytes(kp.privateKey, account.hexToBytes(id), 'hex');
    return { kind: FRIEND_KIND, created_at, tags, content, pubkey: pubHex, id, sig };
  }

  /** 加密发送到所有中继 */
  async function _send(friend, obj) {
    const env = await account.encryptData(obj, account.b64urlToBytes(friend.friendKey));
    const envelope = { v: 1, type: obj.type, ts: new Date().toISOString(), payload: env };
    const evt = await buildFriendEvent(friend.pubkey, envelope);
    const urls = relays();
    await Promise.all(urls.map((u) => new Promise((resolve) => {
      try {
        const ws = new WebSocket(u);
        const done = () => { try { ws.close(); } catch (e) { /* 忽略 */ } resolve(); };
        ws.onopen = () => {
          try { ws.send(JSON.stringify(['EVENT', evt])); } catch (e) { /* 忽略 */ }
          setTimeout(done, 250);
        };
        ws.onerror = () => resolve();
        setTimeout(done, 1600);
      } catch (e) { resolve(); }
    })));
    return { ok: true };
  }

  /** 处理收到的事件：先试 pending（friend-req），再匹配已知好友（消息/分享） */
  async function handleEvent(evt) {
    if (!evt || evt.kind !== FRIEND_KIND || !evt.pubkey || !evt.content) return;
    if (_seen.indexOf(evt.id) >= 0) return;
    markSeen(evt.id);

    // 1) 待确认邀请回执（friend-req）：用本机生成的共享密钥试解密
    const pending = pendingKeys();
    if (pending.length) {
      for (const pk of pending) {
        try {
          const env = JSON.parse(evt.content);
          if (!env || !env.payload) continue;
          const plain = await account.decryptData(env.payload, account.b64urlToBytes(pk.key));
          const obj = plain;
          if (obj && obj.type === 'friend-req' && obj.pub === evt.pubkey) {
            if (!findPub(obj.pub)) {
              friends.push({ id: uid(), pubkey: obj.pub, name: obj.name || '新好友', friendKey: pk.key, addedAt: new Date().toISOString(), lastMsgAt: null });
              save();
            }
            savePending(pending.filter((x) => x.key !== pk.key));
            if (callbacks.onMessage) callbacks.onMessage(findPub(obj.pub), '已通过你的邀请，互为好友');
            return;
          }
        } catch (e) { /* 密钥不匹配，继续试下一个 */ }
      }
    }

    // 2) 已知好友的消息 / 分享
    const friend = findPub(evt.pubkey);
    if (!friend) return;
    let obj;
    try {
      const env = JSON.parse(evt.content);
      if (!env || !env.payload) return;
      const plain = await account.decryptData(env.payload, account.b64urlToBytes(friend.friendKey));
      obj = plain;
    } catch (e) { return; }
    if (!obj || !obj.type) return;
    friend.lastMsgAt = obj.ts || new Date().toISOString();
    save();
    if (obj.type === 'msg' && callbacks.onMessage) callbacks.onMessage(friend, obj.text || '');
    else if (obj.type === 'share-task' && callbacks.onShareTask) callbacks.onShareTask(friend, obj.task || {});
  }

  /** 订阅中继：kinds[19324] 且 p-tag 指向自己 */
  async function subscribe() {
    const pub = await ensurePubHex();
    if (!pub || _subscribed) return;
    _subscribed = true;
    relays().forEach((url) => {
      try {
        const ws = new WebSocket(url);
        _subWs.push(ws);
        ws.onopen = () => {
          try {
            ws.send(JSON.stringify(['REQ', 'sp-friend-' + pub.slice(0, 8), {
              kinds: [FRIEND_KIND],
              '#p': [pub],
              limit: 60
            }]));
          } catch (e) { /* 忽略 */ }
        };
        ws.onmessage = (ev) => {
          try {
            const msg = JSON.parse(ev.data);
            if (msg[0] === 'EVENT' && msg[1]) handleEvent(msg[1]);
          } catch (e) { /* 忽略 */ }
        };
        ws.onclose = () => {
          const i = _subWs.indexOf(ws);
          if (i >= 0) _subWs.splice(i, 1);
        };
      } catch (e) { /* 忽略 */ }
    });
  }

  function stop() {
    _subWs.forEach((ws) => { try { ws.close(); } catch (e) { /* 忽略 */ } });
    _subWs = [];
    _subscribed = false;
  }

  /** 初始化：读本地好友 + 订阅中继（登录后调用） */
  async function init() {
    load();
    await subscribe();
  }

  g.Sugar.friends = {
    list,
    find,
    makeInvite,
    addByInvite,
    remove,
    sendMessage,
    shareTask,
    init,
    stop,
    _debugHandle: handleEvent,
    setCallbacks(cb) { Object.assign(callbacks, cb || {}); },
    FRIEND_KIND,
    parseInvite
  };
})(typeof window !== 'undefined' ? window : globalThis);
