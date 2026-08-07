/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 测试用迷你 Nostr 中继：仅服务于 e2e（本地 WebSocket，路径 /relay）
   支持 EVENT 存储/广播、REQ 过滤 + EOSE；不用于生产。 */
'use strict';

const crypto = require('crypto');

const WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

function encodeFrame(payload, opcode) {
  const data = Buffer.isBuffer(payload) ? payload : Buffer.from(String(payload), 'utf-8');
  const len = data.length;
  const head = [0x80 | (opcode || 0x1)];
  let lenBuf;
  if (len < 126) {
    lenBuf = Buffer.from([len]);
  } else if (len < 65536) {
    head.push(126);
    lenBuf = Buffer.alloc(2);
    lenBuf.writeUInt16BE(len, 0);
  } else {
    head.push(127);
    lenBuf = Buffer.alloc(8);
    lenBuf.writeBigUInt64BE(BigInt(len), 0);
  }
  return Buffer.concat([Buffer.from(head), lenBuf, data]);
}

/** 解析客户端帧（掩码文本帧）；返回消费的字节数，消息推入 out */
function decodeFrames(buf, out) {
  let offset = 0;
  while (offset + 2 <= buf.length) {
    const b0 = buf[offset];
    const b1 = buf[offset + 1];
    const opcode = b0 & 0x0f;
    const masked = (b1 & 0x80) !== 0;
    let len = b1 & 0x7f;
    offset += 2;
    if (len === 126) {
      if (offset + 2 > buf.length) break;
      len = buf.readUInt16BE(offset);
      offset += 2;
    } else if (len === 127) {
      if (offset + 8 > buf.length) break;
      len = Number(buf.readBigUInt64BE(offset));
      offset += 8;
    }
    let maskKey = null;
    if (masked) {
      if (offset + 4 > buf.length) break;
      maskKey = buf.slice(offset, offset + 4);
      offset += 4;
    }
    if (offset + len > buf.length) break;
    let payload = buf.slice(offset, offset + len);
    offset += len;
    if (maskKey) {
      const unmasked = Buffer.alloc(len);
      for (let i = 0; i < len; i++) unmasked[i] = payload[i] ^ maskKey[i % 4];
      payload = unmasked;
    }
    if (opcode === 0x8) {
      out.push({ close: true });
      return offset;
    }
    if (opcode === 0x1) out.push({ text: payload.toString('utf-8') });
    else if (opcode === 0x9) out.push({ ping: true });
    // 测试中不处理分片与二进制帧
  }
  return offset;
}

function attachMiniRelay(server) {
  const clients = new Set();
  const events = [];

  function closeClient(c) {
    clients.delete(c);
    try { c.socket.destroy(); } catch (e) { /* 忽略 */ }
  }

  function safeSend(c, buf) {
    try { if (c.socket.writable) c.socket.write(buf); } catch (e) { /* 忽略 */ }
  }

  function broadcast(data, except) {
    clients.forEach((c) => { if (c !== except) safeSend(c, encodeFrame(data)); });
  }

  server.on('upgrade', (req, socket) => {
    if (req.url !== '/relay') {
      socket.destroy();
      return;
    }
    const key = req.headers['sec-websocket-key'];
    if (!key) {
      socket.destroy();
      return;
    }
    const accept = crypto.createHash('sha1').update(key + WS_GUID).digest('base64');
    socket.write(
      'HTTP/1.1 101 Switching Protocols\r\n' +
      'Upgrade: websocket\r\n' +
      'Connection: Upgrade\r\n' +
      'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n'
    );
    const client = { socket, buffer: Buffer.alloc(0) };
    clients.add(client);

    socket.on('data', (chunk) => {
      client.buffer = Buffer.concat([client.buffer, chunk]);
      const messages = [];
      client.buffer = client.buffer.slice(decodeFrames(client.buffer, messages));
      messages.forEach((m) => {
        if (m.close) { closeClient(client); return; }
        if (m.ping) { safeSend(client, encodeFrame('', 0xA)); return; }
        if (!m.text) return;
        let msg;
        try { msg = JSON.parse(m.text); } catch (e) { return; }
        if (!Array.isArray(msg)) return;
        if (msg[0] === 'EVENT') {
          const ev = msg[1];
          // NIP-01：事件 pubkey 必须为 64 位小写 hex（模拟公共中继校验，防回归）
          if (ev && ev.kind && /^[a-f0-9]{64}$/.test(String(ev.pubkey || ''))) {
            events.push(ev);
            broadcast(JSON.stringify(['EVENT', ev]), client);
          }
        } else if (msg[0] === 'REQ') {
          const subId = msg[1];
          const filter = msg[2] || {};
          const kinds = filter.kinds || [];
          const authors = filter.authors || [];
          const dTag = (filter['#d'] || [])[0];
          const matches = events.filter((ev) => {
            if (kinds.length && !kinds.includes(ev.kind)) return false;
            if (authors.length && !authors.includes(ev.pubkey)) return false;
            if (dTag && !(ev.tags || []).some((t) => t[0] === 'd' && t[1] === dTag)) return false;
            return true;
          });
          // 可替换事件（kind 19322 快照）按 d-tag + pubkey 去重取最新；信令全量下发
          const latest = new Map();
          matches.slice().sort((a, b) => (b.created_at || 0) - (a.created_at || 0)).forEach((ev) => {
            if (ev.kind === 19322) {
              const key = ev.pubkey + '|' + ((ev.tags || []).find((t) => t[0] === 'd') || [])[1];
              if (!latest.has(key)) latest.set(key, ev);
            } else {
              latest.set(ev.id, ev);
            }
          });
          [...latest.values()].forEach((ev) => safeSend(client, encodeFrame(JSON.stringify(['EVENT', ev]))));
          safeSend(client, encodeFrame(JSON.stringify(['EOSE', subId])));
        }
      });
    });
    socket.on('close', () => closeClient(client));
    socket.on('error', () => closeClient(client));
  });

  return { events };
}

module.exports = { attachMiniRelay, encodeFrame };
