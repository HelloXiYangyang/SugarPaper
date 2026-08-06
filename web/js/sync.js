/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 无服务器跨设备同步（v0.16.0 / S2）
   通道 v1：Nostr 公共中继（WebSocket，浏览器无 CORS 限制）。
   流程：拉取最新加密快照 → 验签 → 解密 → 按 updatedAt 逐条合并 → 推送合并结果。
   架构上保留 SyncChannel 抽象，后续可接入 WebDAV / WebRTC 通道。 */
(function (g) {
  'use strict';

  const DEFAULT_RELAYS = [
    'wss://relay.damus.io',
    'wss://nostr.wine',
    'wss://relay.nostr.band'
  ];
  const SYNC_KIND = 19322;
  const SYNC_D_TAG = 'sugarpaper:snapshot';
  const REQ_TIMEOUT = 8000;

  function store() {
    return g.Sugar.store;
  }

  function account() {
    return store().state.account;
  }

  function relays() {
    const list = store().state.settings.sync && store().state.settings.sync.relays;
    return Array.isArray(list) && list.length ? list.slice() : DEFAULT_RELAYS.slice();
  }

  const sync = {
    status: 'off', // off | connecting | connected | error
    lastSyncAt: null,
    lastError: null,
    _ws: null,
    _debTimer: null,
    _lastFingerprint: ''
  };

  function emitStatus() {
    if (g.App && typeof g.App.renderView === 'function') {
      try { g.App.renderView(); } catch (e) { /* 忽略 */ }
    }
  }

  function setStatus(s, err) {
    sync.status = s;
    sync.lastError = err || null;
    if (s === 'connected') sync.lastSyncAt = new Date().toISOString();
    emitStatus();
  }

  function snapshotPayload(state) {
    const ver = (state.account && state.account.version) || 1;
    return {
      version: ver,
      exportedAt: new Date().toISOString(),
      tasks: state.tasks,
      notes: state.notes,
      focusSessions: state.focusSessions
    };
  }

  async function buildEnvelope(state) {
    const acc = state.account;
    if (!acc || !acc.seedB64) throw new Error('尚未创建账号');
    const seed = g.Sugar.account.b64urlToBytes(acc.seedB64);
    const kp = await g.Sugar.account.seedToKeyPair(seed);
    const payload = snapshotPayload(state);
    const { iv, data } = await g.Sugar.account.encryptData(payload, seed);
    const version = (acc.version || 0) + 1;
    const sig = await g.Sugar.account.signBytes(kp.privateKey, new TextEncoder().encode('sugarpaper:' + version + ':' + iv + ':' + data), 'b64');
    return { app: 'SugarPaper', kind: 'sync', ver: 1, version, iv, data, sig, pubkey: acc.pubkey };
  }

  async function nostrEvent(env) {
    const acc = account();
    const seed = g.Sugar.account.b64urlToBytes(acc.seedB64);
    const kp = await g.Sugar.account.seedToKeyPair(seed);
    const created_at = Math.floor(Date.now() / 1000);
    const tags = [['d', SYNC_D_TAG], ['t', 'sugarpaper']];
    const content = JSON.stringify(env);
    const idBytes = await g.Sugar.account.sha256(new TextEncoder().encode(JSON.stringify([0, acc.pubkey, created_at, SYNC_KIND, tags, content])));
    const id = g.Sugar.account.bytesToHex(idBytes);
    const sig = await g.Sugar.account.signBytes(kp.privateKey, g.Sugar.account.hexToBytes(id), 'hex');
    return { kind: SYNC_KIND, created_at, tags, content, pubkey: acc.pubkey, id, sig };
  }

  function openWs(url, timeoutMs) {
    return new Promise((resolve, reject) => {
      if (typeof WebSocket === 'undefined') {
        reject(new Error('当前环境不支持 WebSocket'));
        return;
      }
      let ws;
      try {
        ws = new WebSocket(url);
      } catch (e) {
        reject(e);
        return;
      }
      const t = setTimeout(() => {
        try { ws.close(); } catch (e) { /* 忽略 */ }
        reject(new Error('连接中继超时：' + url));
      }, timeoutMs || REQ_TIMEOUT);
      ws.onopen = () => { clearTimeout(t); resolve(ws); };
      ws.onerror = () => {
        clearTimeout(t);
        reject(new Error('无法连接中继：' + url));
      };
    });
  }

  /** 拉取作者最新的糖纸快照事件；返回解密后的 payload 或 null */
  async function fetchLatest(ws, pubkey) {
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error('拉取快照超时')), REQ_TIMEOUT);
      let best = null;
      ws.onmessage = (ev) => {
        let msg;
        try { msg = JSON.parse(ev.data); } catch (e) { return; }
        if (!Array.isArray(msg)) return;
        if (msg[0] === 'EVENT' && msg[1] && msg[1].kind === SYNC_KIND) {
          try {
            const env = JSON.parse(msg[1].content);
            if (env && env.app === 'SugarPaper' && env.kind === 'sync' && env.version != null) {
              if (!best || env.version > best.version) best = env;
            }
          } catch (e) { /* 忽略无效事件 */ }
        } else if (msg[0] === 'EOSE') {
          clearTimeout(timer);
          resolve(best);
        }
      };
      ws.send(JSON.stringify(['REQ', 'sugarpaper', {
        kinds: [SYNC_KIND],
        authors: [pubkey],
        '#d': [SYNC_D_TAG],
        limit: 20
      }]));
    });
  }

  /** 逐条按 updatedAt 合并（LWW）；isDeleted 墓碑随记录保留 */
  function mergeById(a, b) {
    const map = new Map();
    (a || []).forEach((x) => { if (x && x.id) map.set(x.id, x); });
    (b || []).forEach((x) => {
      if (!x || !x.id) return;
      const ex = map.get(x.id);
      if (!ex) map.set(x.id, x);
      else if (String(x.updatedAt || '') >= String(ex.updatedAt || '')) map.set(x.id, x);
    });
    return Array.from(map.values());
  }

  function mergeSnapshot(local, remote) {
    const tasks = mergeById(local.tasks, remote.tasks);
    const notes = mergeById(local.notes, remote.notes);
    const focusSessions = mergeById(local.focusSessions, remote.focusSessions);
    const changed =
      JSON.stringify(tasks) !== JSON.stringify(local.tasks || []) ||
      JSON.stringify(notes) !== JSON.stringify(local.notes || []) ||
      JSON.stringify(focusSessions) !== JSON.stringify(local.focusSessions || []);
    return { tasks, notes, focusSessions, changed };
  }

  async function verifyEnvelope(env, pubkeyB64) {
    if (env.pubkey !== pubkeyB64) return false;
    const bytes = new TextEncoder().encode('sugarpaper:' + env.version + ':' + env.iv + ':' + env.data);
    try {
      return await g.Sugar.account.verifyBytes(pubkeyB64, bytes, env.sig, false);
    } catch (e) {
      return false;
    }
  }

  async function syncNow() {
    const acc = account();
    if (!acc) {
      setStatus('off');
      return;
    }
    if (sync.status === 'connecting') return;
    setStatus('connecting');
    const url = relays()[0];
    let ws;
    try {
      ws = await openWs(url);
      const remote = await fetchLatest(ws, acc.pubkey);
      const seed = g.Sugar.account.b64urlToBytes(acc.seedB64);
      if (remote) {
        const ok = await verifyEnvelope(remote, acc.pubkey);
        if (ok) {
          const payload = await g.Sugar.account.decryptData(remote, seed);
          const merged = mergeSnapshot({
            tasks: store().state.tasks,
            notes: store().state.notes,
            focusSessions: store().state.focusSessions
          }, payload);
          if (merged.changed) {
            store().replaceAll({ tasks: merged.tasks, notes: merged.notes, focusSessions: merged.focusSessions });
          }
          const nextVersion = Math.max((acc.version || 0), payload.version || 0);
          store().updateAccount({ version: nextVersion });
        }
      }
      const env = await buildEnvelope(store().state);
      ws.send(JSON.stringify(['EVENT', await nostrEvent(env)]));
      await new Promise((r) => setTimeout(r, 400));
      ws.close();
      ws = null;
      store().updateAccount({ lastSyncAt: new Date().toISOString() });
      setStatus('connected');
    } catch (e) {
      try { if (ws) ws.close(); } catch (e2) { /* 忽略 */ }
      setStatus('error', e && e.message ? e.message : String(e));
      console.warn('[sync] 同步失败：', e);
    }
  }

  function dataFingerprint(state) {
    const t = (state.tasks || []).map((x) => x.id + ':' + (x.updatedAt || '')).join('|');
    const n = (state.notes || []).map((x) => x.id + ':' + (x.updatedAt || '')).join('|');
    const f = (state.focusSessions || []).map((x) => x.id + ':' + (x.updatedAt || '')).join('|');
    return t.length + ':' + n.length + ':' + f.length + '|' + t + n + f;
  }

  /** 数据变更后自动同步（防抖，仅在账号 + 自动同步开启且数据确有变化时执行） */
  function scheduleSync() {
    const st = store().state;
    if (!st.account || !st.settings.sync || !st.settings.sync.autoSync) return;
    const fp = dataFingerprint(st);
    if (fp === sync._lastFingerprint) return;
    sync._lastFingerprint = fp;
    clearTimeout(sync._debTimer);
    sync._debTimer = setTimeout(() => { syncNow(); }, 3000);
  }

  function stop() {
    clearTimeout(sync._debTimer);
    if (sync._ws) {
      try { sync._ws.close(); } catch (e) { /* 忽略 */ }
      sync._ws = null;
    }
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.sync = {
    DEFAULT_RELAYS,
    SYNC_KIND,
    status: sync,
    syncNow,
    scheduleSync,
    mergeSnapshot,
    buildEnvelope,
    nostrEvent,
    verifyEnvelope,
    snapshotPayload,
    dataFingerprint,
    stop
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
      mergeSnapshot,
      mergeById,
      dataFingerprint,
      DEFAULT_RELAYS,
      SYNC_KIND
    };
  }
})(typeof window !== 'undefined' ? window : globalThis);
