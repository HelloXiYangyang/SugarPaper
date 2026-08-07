/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 账号与同步界面（v0.16.0 / S2）
   无服务器账号：创建 / 恢复 / 备份助记词；同步状态、手动同步、中继配置、设备管理。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  function statusText() {
    const st = S.sync.status.status;
    if (st === 'off') return '未连接';
    if (st === 'connecting') return '连接中…';
    if (st === 'connected') return '已连接';
    return '同步异常';
  }

  function switchRow(iconName, title, desc, key) {
    const val = key.split('.').reduce((o, k) => (o == null ? undefined : o[k]), store.state.settings);
    const checked = val ? ' checked' : '';
    return '<div class="settings-row"><span class="row-icon">' + S.icons.icon(iconName, 15) + '</span>' +
      '<div class="row-body"><div class="row-title">' + title + '</div>' +
      '<div class="row-desc">' + desc + '</div></div>' +
      '<span class="row-action switch"><input type="checkbox" data-toggle="' + key + '"' + checked + '><span class="track"></span><span class="thumb"></span></span></div>';
  }

  function devicesHtml() {
    const acc = store.state.account;
    const list = (acc && Array.isArray(acc.devices) && acc.devices.length)
      ? acc.devices
      : [{ id: 'local', name: store.state.settings.deviceName, lastSyncAt: acc ? acc.lastSyncAt : null }];
    return list.map((d) =>
      '<div class="subject-row"><span class="dot" style="background:var(--mint-strong)"></span>' +
      '<span class="name">' + util.escapeHtml(d.name) + '</span>' +
      '<span style="font-size:11px;color:var(--text-3)">' + (d.lastSyncAt ? util.fmtDateTime(d.lastSyncAt) : '从未同步') + '</span>' +
      '<span class="sub-actions"><button class="btn small soft-danger" data-action="remove-device" data-device="' + util.escapeHtml(d.id) + '">解绑</button></span></div>'
    ).join('');
  }

  function cardHtml() {
    const acc = store.state.account;
    if (!acc) {
      return '<div class="settings-card reveal"><h3>🔑 账号与同步</h3>' +
        '<div class="settings-row"><span class="row-icon">' + S.icons.icon('user', 15) + '</span>' +
        '<div class="row-body"><div class="row-title">创建账号</div>' +
        '<div class="row-desc">12 词助记词即账号 · 数据端到端加密 · 无需任何服务器</div></div>' +
        '<button class="btn small primary" data-action="create-account">创建</button></div>' +
        '<div class="settings-row"><span class="row-icon">' + S.icons.icon('download', 15) + '</span>' +
        '<div class="row-body"><div class="row-title">恢复账号</div>' +
        '<div class="row-desc">在新设备输入助记词，登录同一账号并拉取数据</div></div>' +
        '<button class="btn small" data-action="restore-account">恢复</button></div>' +
        '</div>';
    }
    const lastSync = acc.lastSyncAt ? util.fmtDateTime(acc.lastSyncAt) : '从未同步';
    const relay = (store.state.settings.sync && store.state.settings.sync.relays && store.state.settings.sync.relays[0]) || '未配置';
    return '<div class="settings-card reveal"><h3>🔑 账号与同步</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('user', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">' + util.escapeHtml(acc.displayName || '小糖') +
      ' <span class="tag pri-mid">' + util.escapeHtml(S.account.accountShortId(acc.pubkey)) + '</span></div>' +
      '<div class="row-desc">身份即密钥 · 助记词已备份' + (acc.mnemonic ? ' ✓' : ' ✗') + '</div></div>' +
      '<button class="btn small" data-action="rename-account">' + S.icons.icon('edit', 13) + '</button>' +
      '<button class="btn small soft-pink" data-action="backup-mnemonic">备份助记词</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('globe', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">同步状态</div>' +
      '<div class="row-desc" id="sync-status">' + statusText() + ' · 上次同步 ' + lastSync +
      (S.sync.status.lastError ? ' · ' + util.escapeHtml(S.sync.status.lastError) : '') + '</div></div>' +
      '<button class="btn small" data-action="sync-now">立即同步</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('bolt', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">在线直连（P2P）</div>' +
      '<div class="row-desc" id="direct-status">' + util.escapeHtml(S.sync.directStatusText()) + '</div></div>' +
      '<button class="btn small" data-action="direct-sync">' +
      (S.sync.direct.status === 'off' || S.sync.direct.status === 'error' ? '直连' : '停止') +
      '</button></div>' +
      switchRow('bolt', '自动同步', '数据变化后自动同步到云端桥（中继）', 'sync.autoSync') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('paperclip', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">同步中继</div>' +
      '<div class="row-desc">' + util.escapeHtml(relay) + '</div></div>' +
      '<button class="btn small" data-action="configure-relays">配置</button></div>' +
      '<div class="settings-row" style="align-items:flex-start"><span class="row-icon">' + S.icons.icon('save', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">设备</div><div id="sync-devices">' + devicesHtml() + '</div></div></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('trash', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">删除本地账号</div>' +
      '<div class="row-desc">仅删除本机身份，本地任务数据保留；其他设备不受影响</div></div>' +
      '<button class="btn small soft-danger" data-action="delete-account">删除</button></div>' +
      '</div>';
  }

  function familyCardHtml() {
    const profiles = store.state.settings.familyProfiles || [];
    const rows = profiles.length
      ? profiles.map((p) =>
          '<div class="subject-row"><span class="dot" style="background:var(--lavender-strong)"></span>' +
          '<span class="name">' + util.escapeHtml(p.label) + '</span>' +
          '<span style="font-size:11px;color:var(--text-3)">' + util.escapeHtml(S.account.accountShortId(p.pubkey)) + '</span>' +
          '<span class="sub-actions">' +
          '<button class="btn small" data-action="switch-family" data-profile="' + util.escapeHtml(p.id) + '">切换</button>' +
          '<button class="btn small soft-danger" data-action="remove-family" data-profile="' + util.escapeHtml(p.id) + '">' +
          S.icons.icon('trash', 13) + '</button></span></div>').join('')
      : '<div style="font-size:12px;color:var(--text-3);padding:4px 2px">还没有家庭成员档案</div>';
    return '<div class="settings-card reveal"><h3>👨‍👩‍👧 家庭模式</h3>' +
      '<div class="settings-row" style="align-items:flex-start"><span class="row-icon">' + S.icons.icon('user', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">家庭成员档案</div>' +
      '<div class="row-desc">保存孩子/家人的助记词档案，一键切换账号代管；打卡类任务可在对应账号中确认</div>' +
      '<div id="family-profiles">' + rows + '</div></div></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('plus', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">添加档案</div><div class="row-desc">输入成员助记词与昵称</div></div>' +
      '<button class="btn small soft-pink" data-action="add-family">添加</button></div>' +
      '</div>';
  }

  async function saveAccount(result) {
    const acc = {
      pubkey: result.kp.pubkey,
      displayName: '小糖',
      seedB64: S.account.b64url(result.seed),
      mnemonic: result.mnemonic.join(' '),
      version: 1,
      createdAt: new Date().toISOString(),
      lastSyncAt: null,
      devices: [{ id: util.uuid(), name: store.state.settings.deviceName, lastSyncAt: null }]
    };
    store.setAccount(acc);
    S.ui.toast('✅ 账号已创建，助记词即账号，请务必备份');
    g.App.render();
  }

  function openCreate() {
    S.account.createAccount().then((result) => {
      const words = result.mnemonic.map((w, i) =>
        '<span class="mn-word">' + (i + 1) + '. ' + util.escapeHtml(w) + '</span>').join('');
      const dlg = S.ui.modal.open({
        title: '创建账号 · 备份助记词',
        body:
          '<div class="field"><label>这是你的账号（12 词助记词）</label>' +
          '<div class="mn-grid">' + words + '</div>' +
          '<div style="font-size:12px;color:var(--danger-strong);margin-top:8px;line-height:1.6">⚠️ 助记词即账号，丢失无法找回。请抄写或保存到安全的地方，不要发给任何人。</div></div>',
        footer: ''
      });
      dlg.footEl.innerHTML =
        '<button class="btn" data-action="cancel">取消</button>' +
        '<button class="btn soft-pink" data-action="copy">' + S.icons.icon('paperclip', 13) + ' 复制助记词</button>' +
        '<button class="btn primary" data-action="ok">' + S.icons.icon('check', 13) + ' 我已抄写保存</button>';
      dlg.footEl.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-action]');
        if (!btn) return;
        if (btn.dataset.action === 'cancel') { dlg.close(); return; }
        if (btn.dataset.action === 'copy') {
          const text = result.mnemonic.join(' ');
          if (g.navigator && g.navigator.clipboard) {
            g.navigator.clipboard.writeText(text).then(() => S.ui.toast('已复制助记词')).catch(() => S.ui.toast('复制失败，请手动抄写'));
          } else {
            S.ui.toast('浏览器不支持自动复制，请手动抄写');
          }
          return;
        }
        dlg.close();
        saveAccount(result);
      });
    }).catch((e) => S.ui.toast('创建账号失败：' + (e && e.message ? e.message : e)));
  }

  function openRestore() {
    const dlg = S.ui.modal.open({
      title: '恢复账号',
      body:
        '<div class="field"><label>输入 12 词助记词（用空格分隔）</label>' +
        '<textarea id="restore-mnemonic" placeholder="例如：bob yac …" style="min-height:90px"></textarea>' +
        '<div style="font-size:12px;color:var(--text-3);margin-top:6px">恢复后将从云端桥拉取同一账号的数据并合并。</div></div>',
      footer: ''
    });
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="ok">恢复并同步</button>';
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      const text = dlg.bodyEl.querySelector('#restore-mnemonic').value.trim();
      if (!text) { S.ui.toast('请输入助记词'); return; }
      S.account.restoreAccount(text).then((result) => {
        dlg.close();
        saveAccount(result);
        // 恢复后立即拉取一次云端数据
        setTimeout(() => S.sync.syncNow(), 300);
      }).catch((e) => {
        S.ui.toast('恢复失败：' + (e && e.message ? e.message : e));
      });
    });
  }

  function openBackup() {
    const acc = store.state.account;
    if (!acc || !acc.mnemonic) { S.ui.toast('暂无可备份的助记词'); return; }
    const words = acc.mnemonic.split(/\s+/).map((w, i) =>
      '<span class="mn-word">' + (i + 1) + '. ' + util.escapeHtml(w) + '</span>').join('');
    const dlg = S.ui.modal.open({
      title: '备份助记词',
      body:
        '<div class="field"><label>你的账号助记词</label>' +
        '<div class="mn-grid">' + words + '</div>' +
        '<div style="font-size:12px;color:var(--danger-strong);margin-top:8px;line-height:1.6">请抄写或保存到安全的地方，丢失无法找回。</div></div>',
      footer: ''
    });
    dlg.footEl.innerHTML = '<button class="btn" data-action="close">知道了</button>';
  }

  function openRelays() {
    const current = (store.state.settings.sync && store.state.settings.sync.relays) || S.sync.DEFAULT_RELAYS;
    const dlg = S.ui.modal.open({
      title: '同步中继配置',
      body:
        '<div class="field"><label>中继地址（多个用逗号分隔）</label>' +
        '<textarea id="relay-input" style="min-height:90px">' + util.escapeHtml(current.join(', ')) + '</textarea>' +
        '<div style="font-size:12px;color:var(--text-3);margin-top:6px">默认使用公共 Nostr 中继；也可填写自建/自选中继。数据始终端到端加密。</div></div>',
      footer: ''
    });
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="ok">保存</button>';
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      const relays = dlg.bodyEl.querySelector('#relay-input').value
        .split(/[,，\s]+/).map((s) => s.trim()).filter((s) => /^wss?:\/\//.test(s));
      if (!relays.length) { S.ui.toast('请输入至少一个有效中继地址（wss://）'); return; }
      store.updateSettings({ sync: Object.assign({}, store.state.settings.sync, { relays }) });
      S.ui.toast('中继配置已保存');
      dlg.close();
      g.App.renderView();
    });
  }

  function openAddFamily() {
    const dlg = S.ui.modal.open({
      title: '添加家庭成员',
      body:
        '<div class="field"><label>昵称（例如：小明）</label><input type="text" id="family-label" placeholder="小明"></div>' +
        '<div class="field"><label>成员助记词（12 词）</label>' +
        '<textarea id="family-mnemonic" placeholder="粘贴或输入成员账号的 12 词助记词" style="min-height:80px"></textarea></div>',
      footer: ''
    });
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="ok">' + S.icons.icon('check', 13) + ' 保存档案</button>';
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      const label = dlg.bodyEl.querySelector('#family-label').value.trim() || '家庭成员';
      const mnemonic = dlg.bodyEl.querySelector('#family-mnemonic').value.trim();
      if (!mnemonic) { S.ui.toast('请输入成员助记词'); return; }
      S.account.restoreAccount(mnemonic).then((result) => {
        store.addFamilyProfile({
          label,
          mnemonic: result.mnemonic.join(' '),
          pubkey: result.kp.pubkey
        });
        S.ui.toast('✅ 已添加 ' + label + ' 的档案');
        dlg.close();
        g.App.renderView();
      }).catch((err) => {
        S.ui.toast('助记词无效：' + (err && err.message ? err.message : err));
      });
    });
  }

  function switchFamily(id) {
    const p = (store.state.settings.familyProfiles || []).find((x) => x.id === id);
    if (!p) return;
    S.account.restoreAccount(p.mnemonic).then((result) => {
      store.setAccount({
        pubkey: result.kp.pubkey,
        displayName: p.label,
        seedB64: S.account.b64url(result.seed),
        mnemonic: result.mnemonic.join(' '),
        version: 1,
        createdAt: new Date().toISOString(),
        lastSyncAt: null,
        devices: [{ id: util.uuid(), name: store.state.settings.deviceName, lastSyncAt: null }]
      });
      S.ui.toast('已切换到 ' + p.label + ' 的账号');
      g.App.render();
    }).catch((err) => S.ui.toast('切换失败：' + (err && err.message ? err.message : err)));
  }

  function bind(wrap) {
    wrap.querySelectorAll('input[data-toggle="sync.autoSync"]').forEach((inp) => {
      inp.addEventListener('change', () => {
        if (g.App) g.App._suspendView = true;
        try {
          store.updateSettings({ sync: Object.assign({}, store.state.settings.sync, { autoSync: inp.checked }) });
        } finally {
          if (g.App) g.App._suspendView = false;
        }
      });
    });
    wrap.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      const a = btn.dataset.action;
      if (a === 'create-account') openCreate();
      else if (a === 'restore-account') openRestore();
      else if (a === 'backup-mnemonic') openBackup();
      else if (a === 'rename-account') {
        S.ui.modal.prompt({
          title: '修改昵称',
          label: '昵称',
          value: store.state.account.displayName,
          placeholder: '例如：小糖',
          onConfirm: (v) => { store.updateAccount({ displayName: v }); S.ui.toast('✅ 昵称已更新'); }
        });
      } else if (a === 'sync-now') {
        S.sync.syncNow();
      } else if (a === 'direct-sync') {
        if (S.sync.direct.status === 'off' || S.sync.direct.status === 'error') {
          S.sync.directSync();
        } else {
          S.sync.stopDirect();
        }
      } else if (a === 'configure-relays') {
        openRelays();
      } else if (a === 'add-family') {
        openAddFamily();
      } else if (a === 'switch-family') {
        switchFamily(btn.dataset.profile);
      } else if (a === 'remove-family') {
        const id = btn.dataset.profile;
        S.ui.modal.confirm({
          title: '删除成员档案',
          message: '删除后需重新输入助记词才能切换该账号。确定删除吗？',
          confirmText: '删除',
          danger: true,
          onConfirm: () => {
            store.removeFamilyProfile(id);
            S.ui.toast('成员档案已删除');
          }
        });
      } else if (a === 'remove-device') {
        const id = btn.dataset.device;
        S.ui.modal.confirm({
          title: '解绑设备',
          message: '确定解绑该设备吗？',
          confirmText: '解绑',
          danger: true,
          onConfirm: () => {
            const acc = store.state.account;
            if (acc) {
              store.updateAccount({ devices: (acc.devices || []).filter((d) => d.id !== id) });
              S.ui.toast('设备已解绑');
            }
          }
        });
      } else if (a === 'delete-account') {
        S.ui.modal.confirm({
          title: '删除本地账号',
          message: '将删除本机保存的身份（助记词与密钥）。本地任务数据会保留，其他设备不受影响。确定吗？',
          confirmText: '删除',
          danger: true,
          onConfirm: () => {
            store.clearAccount();
            S.sync.stop();
            S.ui.toast('本地账号已删除');
            g.App.render();
          }
        });
      }
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.account = { cardHtml, familyCardHtml, bind, openCreate, openRestore, openBackup, openRelays, openAddFamily, switchFamily };
})(typeof window !== 'undefined' ? window : globalThis);
