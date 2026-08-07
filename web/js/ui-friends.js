/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 好友直连界面（v0.33.0，S18 模块二） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  function esc(s) { return util.escapeHtml(String(s == null ? '' : s)); }

  function friendRow(f) {
    return '<div class="friend-row" data-friend-id="' + f.id + '">' +
      '<span class="friend-avatar">' + S.icons.icon('heart', 16) + '</span>' +
      '<div class="friend-info"><div class="friend-name">' + esc(f.name) + '</div>' +
      '<div class="friend-meta">' + esc(shortId(f.pubkey)) + (f.lastMsgAt ? ' · ' + esc(util.fmtDateTime(f.lastMsgAt)) : '') + '</div></div>' +
      '<span class="friend-ops">' +
      '<button class="btn small" data-friend-op="msg" data-friend-id="' + f.id + '">' + S.icons.icon('edit', 12) + ' 消息</button>' +
      '<button class="btn small" data-friend-op="share" data-friend-id="' + f.id + '">' + S.icons.icon('upload', 12) + ' 分享作业</button>' +
      '<button class="btn small soft-danger" data-friend-op="del" data-friend-id="' + f.id + '">' + S.icons.icon('trash', 12) + '</button>' +
      '</span></div>';
  }

  function shortId(pub) { return pub ? pub.slice(0, 8) : ''; }

  function render(dlg) {
    const list = S.friends.list();
    dlg.bodyEl.innerHTML =
      '<div class="friend-tip">' + S.icons.icon('globe', 13) + ' 好友消息端到端加密（AES-256-GCM），经 Nostr 中继转发密文，无中心服务器。</div>' +
      '<div class="friend-actions">' +
      '<button class="btn soft-pink" data-friend-action="invite">' + S.icons.icon('plus', 13) + ' 生成邀请</button>' +
      '<button class="btn" data-friend-action="import">' + S.icons.icon('download', 13) + ' 导入邀请</button>' +
      '</div>' +
      '<div id="friend-invite-box"></div>' +
      '<div class="friend-list">' +
      (list.length
        ? list.map(friendRow).join('')
        : '<div class="empty"><div class="big">' + S.icons.icon('heart', 34) + '</div>还没有好友<br>生成邀请发给朋友，或粘贴对方邀请</div>') +
      '</div>';

    dlg.bodyEl.querySelectorAll('[data-friend-action]').forEach((b) => {
      b.addEventListener('click', () => {
        if (b.dataset.friendAction === 'invite') showInvite(dlg);
        else showImport(dlg);
      });
    });
    dlg.bodyEl.querySelectorAll('[data-friend-op]').forEach((b) => {
      b.addEventListener('click', () => {
        const id = b.dataset.friendId;
        const op = b.dataset.friendOp;
        if (op === 'msg') promptMessage(dlg, id);
        else if (op === 'share') promptShare(dlg, id);
        else if (op === 'del') { S.friends.remove(id); render(dlg); }
      });
    });
  }

  async function showInvite(dlg) {
    const acc = store.state.account;
    if (!acc) { S.ui.toast('请先创建账号'); return; }
    const r = await S.friends.makeInvite();
    if (r.error) { S.ui.toast(r.error); return; }
    const box = dlg.bodyEl.querySelector('#friend-invite-box');
    box.innerHTML =
      '<div class="friend-invite">' +
      '<div class="friend-invite-title">把下面的邀请发给朋友（含共享密钥，仅你们可见）</div>' +
      '<textarea readonly rows="3">' + esc(r.text) + '</textarea>' +
      '<button class="btn small primary" data-copy-invite>复制邀请</button>' +
      '</div>';
    const copy = box.querySelector('[data-copy-invite]');
    if (copy) {
      copy.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(r.text);
          S.ui.toast('邀请已复制');
        } catch (e) {
          copy.textContent = '请手动选择复制';
        }
      });
    }
  }

  function showImport(dlg) {
    const box = dlg.bodyEl.querySelector('#friend-invite-box');
    box.innerHTML =
      '<div class="friend-invite">' +
      '<textarea id="friend-invite-input" rows="3" placeholder="粘贴对方发来的邀请文本"></textarea>' +
      '<button class="btn small primary" data-import-invite>添加好友</button>' +
      '</div>';
    const btn = box.querySelector('[data-import-invite]');
    if (btn) {
      btn.addEventListener('click', async () => {
        const text = box.querySelector('#friend-invite-input').value;
        const r = await S.friends.addByInvite(text);
        if (r.error) { S.ui.toast(r.error); return; }
        S.ui.toast('已添加好友 ' + r.friend.name);
        render(dlg);
      });
    }
  }

  function promptMessage(dlg, id) {
    S.ui.modal.prompt({
      title: '发送消息',
      label: '消息内容',
      placeholder: '输入要发送的内容（端到端加密）',
      onConfirm: async (v) => {
        const t = String(v || '').trim();
        if (!t) return;
        const r = await S.friends.sendMessage(id, t);
        S.ui.toast(r.error ? r.error : '已发送');
        render(dlg);
      }
    });
  }

  function promptShare(dlg, id) {
    const tasks = store.state.tasks.filter((t) => !t.isDeleted && !t.isCompleted);
    if (!tasks.length) { S.ui.toast('没有可分享的进行中作业'); return; }
    const d = S.ui.modal.open({ title: '分享作业给好友', footer: '' });
    d.bodyEl.innerHTML =
      '<div class="friend-share-list">' +
      tasks.map((t) =>
        '<button class="friend-share-item" data-share-id="' + t.id + '">' +
        '<span class="dot" style="background:' + store.getSubjectColor(t.subject) + '"></span>' +
        esc(t.title) + '<span class="friend-share-sub">' + esc(t.subject) + '</span></button>').join('') +
      '</div>';
    d.footEl.innerHTML = '<button class="btn" data-action="cancel">取消</button>';
    d.footEl.addEventListener('click', (e) => { if (e.target.closest('[data-action="cancel"]')) d.close(); });
    d.bodyEl.querySelectorAll('[data-share-id]').forEach((b) => {
      b.addEventListener('click', async () => {
        const task = store.state.tasks.find((x) => x.id === b.dataset.shareId);
        if (!task) return;
        const r = await S.friends.shareTask(id, task);
        S.ui.toast(r.error ? r.error : '作业已加密分享');
        d.close();
        render(dlg);
      });
    });
  }

  function confirmShare(friend, task) {
    S.ui.modal.confirm({
      title: '收到作业分享',
      message: esc(friend.name) + ' 分享给你：「' + esc(task.title || '作业') + '」（' + esc(task.subject || '默认') + '），导入到你的作业清单？',
      confirmText: '导入',
      onConfirm: () => {
        store.addTask(Object.assign({}, task, {
          id: undefined,
          isCompleted: false,
          completedAt: null,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          isDeleted: false
        }));
        S.ui.toast('作业已导入');
        if (g.App) g.App.render();
      }
    });
  }

  /** 打开好友直连面板（设置页入口调用） */
  function openPanel() {
    if (!store.state.account) { S.ui.toast('请先创建账号（账号与同步）'); return; }
    const dlg = S.ui.modal.open({ title: '好友直连', footer: '', wide: true });
    S.friends.setCallbacks({
      onMessage: (f, text) => {
        S.ui.toast(esc(f.name) + '：' + esc(String(text).slice(0, 40)));
        if (dlg.bodyEl.isConnected) render(dlg);
      },
      onShareTask: (f, task) => confirmShare(f, task),
      onChanged: () => { if (dlg.bodyEl.isConnected) render(dlg); }
    });
    render(dlg);
    dlg.footEl.innerHTML = '<button class="btn" data-action="close">关闭</button>';
    dlg.footEl.addEventListener('click', (e) => { if (e.target.closest('[data-action="close"]')) dlg.close(); });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.friends = { openPanel };
})(typeof window !== 'undefined' ? window : globalThis);
