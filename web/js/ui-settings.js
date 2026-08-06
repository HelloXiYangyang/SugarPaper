/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 设置页（我的） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const COLOR_PALETTE = [
    '#F4B8CE', '#A9E0CB', '#B3D4F0', '#C9C7F0',
    '#FBE6B9', '#BFE8C9', '#E8D5F0', '#C9E8F0',
    '#F0C9C9', '#FAD1B8', '#F5C4DC', '#F2D4A8',
    '#B8D8E8', '#C8D8C0', '#F0DEB8', '#D8C8F0'
  ];

  const AVATAR_EMOJIS = [
    '🧑', '👧', '👦', '👩', '👨', '🧒',
    '👩‍🦰', '👨‍🦱', '👵', '👴',
    '🐱', '🐶', '🦊', '🐻', '🐼', '🐰', '🦄', '🐨',
    '🍓', '🍑', '🍬', '⭐'
  ];
  const SVG_AVATARS = ['person', 'cat', 'fox', 'bear', 'star', 'heart', 'candy', 'sparkle'];

  function dataSize() {
    try {
      const bytes = new Blob([store.exportJSON()]).size;
      return bytes < 1024 ? bytes + ' B' : (bytes / 1024).toFixed(1) + ' KB';
    } catch (e) {
      return '—';
    }
  }

  function switchRow(iconName, title, desc, key) {
    const checked = store.state.settings[key] ? ' checked' : '';
    return '<div class="settings-row"><span class="row-icon">' + S.icons.icon(iconName, 15) + '</span>' +
      '<div class="row-body"><div class="row-title">' + title + '</div>' +
      '<div class="row-desc">' + desc + '</div></div>' +
      '<span class="row-action switch"><input type="checkbox" data-toggle="' + key + '"' + checked + '><span class="track"></span><span class="thumb"></span></span></div>';
  }

  function subjectRowHtml(s, i) {
    return '<div class="subject-row" style="--i:' + (i || 0) + '" data-subject="' + util.escapeHtml(s.name) + '">' +
      '<span class="dot" style="background:' + s.color + '"></span>' +
      '<span class="name">' + util.escapeHtml(s.name) + '</span>' +
      '<span style="font-size:11px;color:var(--text-3)">' + (s.enabled ? '已启用' : '已停用') + '</span>' +
      '<span class="sub-actions">' +
      '<button class="btn small" data-sub-action="toggle">' + (s.enabled ? '停用' : '启用') + '</button>' +
      '<button class="btn small" data-sub-action="edit">' + S.icons.icon('edit', 13) + '</button>' +
      '<button class="btn small soft-danger" data-sub-action="del">' + S.icons.icon('trash', 13) + '</button>' +
      '</span></div>';
  }

  function render(wrap) {
    const set = store.state.settings;
    const html =
      '<div class="settings-card reveal">' +
      '<div class="device-card">' +
      util.avatarHtml(set.avatar, 'avatar-lg') +
      '<div style="flex:1;min-width:0"><div class="device-name">' + util.escapeHtml(set.deviceName) + '</div>' +
      '<div class="device-meta">' + S.icons.icon('save', 12) + ' 离线优先 · 本地存储<br>' + S.icons.icon('list', 12) + ' 数据大小：' + dataSize() + '</div></div>' +
      '<button class="btn small" data-action="change-avatar">' + S.icons.icon('image', 13) + ' 换头像</button>' +
      '<button class="btn small" data-action="rename-device">' + S.icons.icon('edit', 13) + ' 改名</button>' +
      '</div></div>' +

      '<div class="settings-card reveal"><h3>个性化</h3>' +
      switchRow('sparkles', '动态动画', '界面丝滑动效（关闭后全部动画禁用）', 'animations') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('bolt', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">帧率模式</div>' +
      '<div class="row-desc">高刷新率设备更丝滑，动画自动调速</div></div>' +
      '<span class="row-action seg" id="fps-seg">' +
      ['auto', '60', '120'].map((v) =>
        '<button data-frame-rate="' + v + '"' + (set.frameRate === v ? ' class="active"' : '') + '>' +
        ({ auto: '自动', 60: '60 帧', 120: '120 帧' })[v] + '</button>').join('') +
      '</span></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('gauge', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">流畅度自测</div>' +
      '<div class="row-desc" id="fps-result">测量当前实际显示帧率</div></div>' +
      '<button class="btn small" data-action="fps-test">测一测</button></div>' +
      switchRow('moon', '深色模式', '切换马卡龙深色主题', 'darkMode') +
      switchRow('bell', '通知提醒', '截止日期提醒（浏览器支持时）', 'notifications') +
      switchRow('globe', '互联网模式', '跨网络同步（WebRTC · 规划中）', 'internetMode') +
      '</div>' +

      '<div class="settings-card reveal"><h3>数据管理</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('upload', 15) + '</span><div class="row-body"><div class="row-title">导出数据</div><div class="row-desc">将任务与设置导出为 JSON 备份文件</div></div>' +
      '<button class="btn small" data-action="export-data">导出</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('download', 15) + '</span><div class="row-body"><div class="row-title">导入数据</div><div class="row-desc">从 JSON 备份文件恢复</div></div>' +
      '<button class="btn small" data-action="import-data">导入</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('sparkles', 15) + '</span><div class="row-body"><div class="row-title">载入示例数据</div><div class="row-desc">快速体验完整功能</div></div>' +
      '<button class="btn small" data-action="sample">载入</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('trash', 15) + '</span><div class="row-body"><div class="row-title">清空全部数据</div><div class="row-desc">删除所有任务与设置（不可恢复）</div></div>' +
      '<button class="btn small soft-danger" data-action="reset">清空</button></div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('book', 14) + ' 科目管理</h3>' +
      '<div id="subject-rows">' + store.state.subjects.map(subjectRowHtml).join('') + '</div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('plus', 15) + '</span><div class="row-body"><div class="row-title">添加新科目</div><div class="row-desc">自定义科目与马卡龙配色</div></div>' +
      '<button class="btn small soft-pink" data-action="add-subject">添加</button></div>' +
      '</div>' +

      '<div class="settings-card reveal"><div class="about-block">' +
      '<img class="about-icon" src="icon.svg" alt="糖纸图标">' +
      '<div class="about-name">糖纸 · SugarPaper</div>' +
      '<div class="about-ver">v' + store.APP_VERSION + '（Web 版）</div>' +
      '<div class="about-slogan">让作业管理像糖果一样甜美简单。</div>' +
      '<div class="about-slogan">离线优先 · 设备直连 · 马卡龙美学 · 零服务器依赖</div>' +
      '</div></div>' +

      '<input type="file" id="import-file" accept=".json,application/json" hidden>';

    wrap.innerHTML = html;
    bind(wrap);
  }

  function bind(wrap) {
    wrap.querySelectorAll('input[data-toggle]').forEach((inp) => {
      inp.addEventListener('change', () => {
        store.updateSettings({ [inp.dataset.toggle]: inp.checked });
        g.App.applyPrefs();
        if (inp.dataset.toggle === 'notifications' && inp.checked && g.Notification && g.Notification.requestPermission) {
          g.Notification.requestPermission();
        }
      });
    });

    const fpsSeg = wrap.querySelector('#fps-seg');
    if (fpsSeg) {
      fpsSeg.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-frame-rate]');
        if (!btn) return;
        store.updateSettings({ frameRate: btn.dataset.frameRate });
        g.App.applyPrefs();
        g.App.renderView();
      });
    }

    wrap.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (btn) {
        const a = btn.dataset.action;
        if (a === 'rename-device') {
          S.ui.modal.prompt({
            title: '修改设备名称',
            label: '设备名称',
            value: store.state.settings.deviceName,
            placeholder: '例如：我的 MacBook',
            onConfirm: (v) => { store.updateSettings({ deviceName: v }); S.ui.toast('✅ 设备名称已更新'); }
          });
        } else if (a === 'change-avatar') {
          openAvatarModal();
        } else if (a === 'fps-test') {
          g.App.detectFps().then((fps) => {
            const mode = g.App.resolveFps();
            const desc = wrap.querySelector('#fps-result');
            if (desc) desc.textContent = '当前实际帧率：约 ' + fps + ' FPS · 动画档位 ' + mode;
            S.ui.toast('📶 当前流畅度：约 ' + fps + ' FPS');
          });
        } else if (a === 'export-data') {
          const blob = new Blob([store.exportJSON()], { type: 'application/json;charset=utf-8' });
          const link = document.createElement('a');
          link.href = URL.createObjectURL(blob);
          link.download = '糖纸-备份-' + util.todayStr() + '.json';
          link.click();
          URL.revokeObjectURL(link.href);
          S.ui.toast('📤 数据已导出');
        } else if (a === 'import-data') {
          wrap.querySelector('#import-file').click();
        } else if (a === 'sample') {
          g.App.loadSample();
        } else if (a === 'reset') {
          S.ui.modal.confirm({
            title: '清空全部数据',
            message: '将删除所有任务、科目与设置，且无法恢复。建议先导出备份。',
            confirmText: '清空',
            danger: true,
            onConfirm: () => { store.reset(); S.ui.toast('🧹 数据已清空'); }
          });
        } else if (a === 'add-subject') {
          openSubjectModal();
        }
        return;
      }

      const subBtn = e.target.closest('[data-sub-action]');
      if (subBtn) {
        const row = subBtn.closest('.subject-row');
        const name = row.dataset.subject;
        const a = subBtn.dataset.subAction;
        if (a === 'toggle') {
          const s = store.state.subjects.find((x) => x.name === name);
          if (s) store.updateSubject(name, { enabled: !s.enabled });
        } else if (a === 'edit') {
          openSubjectModal(name);
        } else if (a === 'del') {
          S.ui.modal.confirm({
            title: '删除科目',
            message: '确定删除科目「' + name + '」吗？已有任务不会被删除，但会失去科目筛选。',
            confirmText: '删除',
            danger: true,
            onConfirm: () => store.removeSubject(name)
          });
        }
      }
    });

    const file = wrap.querySelector('#import-file');
    if (file) {
      file.addEventListener('change', () => {
        const f = file.files && file.files[0];
        if (!f) return;
        const reader = new FileReader();
        reader.onload = () => {
          try {
            store.importJSON(reader.result);
            S.ui.toast('✅ 数据导入成功');
            g.App.render();
          } catch (err) {
            S.ui.toast('❌ 导入失败：' + err.message);
          }
        };
        reader.readAsText(f, 'utf-8');
        file.value = '';
      });
    }
  }

  function openSubjectModal(name) {
    const existing = name ? store.state.subjects.find((s) => s.name === name) : null;
    const swatches = COLOR_PALETTE.map((c) =>
      '<button type="button" class="swatch" data-color="' + c + '" style="background:' + c + '"></button>').join('');
    const dlg = S.ui.modal.open({
      title: existing ? '编辑科目：' + name : '添加科目',
      footer: ''
    });
    dlg.bodyEl.innerHTML =
      '<div class="field"><label>科目名称</label><input type="text" id="sub-name" value="' + util.escapeHtml(existing ? existing.name : '') + '" placeholder="例如：编程"></div>' +
      '<div class="field"><label>马卡龙配色</label><div class="swatch-row">' + swatches + '</div></div>';
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="save">保存</button>';
    let color = existing ? existing.color : COLOR_PALETTE[0];
    dlg.bodyEl.querySelectorAll('.swatch').forEach((s) => {
      if (s.dataset.color === color) s.classList.add('active');
      s.addEventListener('click', () => {
        color = s.dataset.color;
        dlg.bodyEl.querySelectorAll('.swatch').forEach((x) => x.classList.remove('active'));
        s.classList.add('active');
      });
    });
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      const n = dlg.bodyEl.querySelector('#sub-name').value.trim();
      if (!n) { S.ui.toast('科目名称不能为空'); return; }
      if (existing) {
        store.updateSubject(existing.name, { name: n, color });
        S.ui.toast('✅ 科目已更新');
      } else {
        const ok = store.addSubject(n, color);
        S.ui.toast(ok ? '✅ 科目已添加' : '❌ 科目已存在');
      }
      dlg.close();
    });
  }

  /* ---------- 更换头像弹窗 ---------- */
  function compressImage(file, cb) {
    const reader = new FileReader();
    reader.onload = () => {
      const img = new Image();
      img.onload = () => {
        const size = 256;
        const canvas = document.createElement('canvas');
        canvas.width = size;
        canvas.height = size;
        const ctx = canvas.getContext('2d');
        const scale = Math.max(size / img.width, size / img.height);
        const dw = img.width * scale;
        const dh = img.height * scale;
        ctx.drawImage(img, (size - dw) / 2, (size - dh) / 2, dw, dh);
        cb(canvas.toDataURL('image/jpeg', 0.85));
      };
      img.onerror = () => S.ui.toast('❌ 图片读取失败，请换一张试试');
      img.src = reader.result;
    };
    reader.readAsDataURL(file);
  }

  function openAvatarModal() {
    const current = store.state.settings.avatar;
    const dlg = S.ui.modal.open({ title: '更换头像', footer: '' });
    const grid = AVATAR_EMOJIS.map((e, i) =>
      '<button type="button" class="avatar-option' + (current === e ? ' active' : '') + '" style="--i:' + i + '" data-avatar="' + e + '">' + e + '</button>').join('');
    const svgGrid = SVG_AVATARS.map((n, i) =>
      '<button type="button" class="avatar-option svg' + (current === 'svg:' + n ? ' active' : '') + '" style="--i:' + (i + AVATAR_EMOJIS.length) + '" data-avatar="svg:' + n + '">' + S.icons.avatar(n, 26) + '</button>').join('');
    dlg.bodyEl.innerHTML =
      '<div class="field"><label>' + S.icons.icon('sparkles', 12) + ' 自绘头像</label><div class="avatar-grid">' + svgGrid + '</div></div>' +
      '<div class="field"><label>' + S.icons.icon('user', 12) + ' 内置 emoji 头像</label><div class="avatar-grid">' + grid + '</div></div>' +
      '<div class="field"><label>' + S.icons.icon('camera', 12) + ' 或上传本地图片（自动压缩至 256×256，仅存本机）</label>' +
      '<input type="file" id="avatar-file" accept="image/*" hidden>' +
      '<button class="btn soft-pink" data-action="upload">' + S.icons.icon('camera', 13) + ' 选择图片</button></div>' +
      '<div class="avatar-preview" id="avatar-preview">' +
      '当前：' + util.avatarHtml(current, 'avatar-sm') + '</div>';
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      (current ? '<button class="btn soft-danger" data-action="reset">恢复默认</button>' : '') +
      '<button class="btn primary" data-action="save">保存</button>';

    let selected = current && !String(current).startsWith('data:') ? current : null;

    function refreshPreview() {
      const el = dlg.bodyEl.querySelector('#avatar-preview');
      if (selected === null) {
        el.innerHTML = '当前：' + util.avatarHtml(current, 'avatar-sm');
      } else if (selected === '__default__') {
        el.innerHTML = '选择：' + util.avatarHtml(null, 'avatar-sm') + '<span>将恢复为默认头像</span>';
      } else {
        el.innerHTML = '选择：' + util.avatarHtml(selected, 'avatar-sm');
      }
    }

    dlg.bodyEl.querySelectorAll('.avatar-option').forEach((b) => {
      b.addEventListener('click', () => {
        selected = b.dataset.avatar;
        dlg.bodyEl.querySelectorAll('.avatar-option').forEach((x) => x.classList.remove('active'));
        b.classList.add('active');
        refreshPreview();
      });
    });
    dlg.bodyEl.querySelector('[data-action="upload"]').addEventListener('click', () => {
      dlg.bodyEl.querySelector('#avatar-file').click();
    });
    dlg.bodyEl.querySelector('#avatar-file').addEventListener('change', () => {
      const f = dlg.bodyEl.querySelector('#avatar-file').files[0];
      if (!f) return;
      compressImage(f, (dataUrl) => {
        selected = dataUrl;
        dlg.bodyEl.querySelectorAll('.avatar-option').forEach((x) => x.classList.remove('active'));
        refreshPreview();
        S.ui.toast('图片已加载，点击“保存”生效');
      });
    });
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      if (btn.dataset.action === 'reset') {
        selected = '__default__';
        dlg.bodyEl.querySelectorAll('.avatar-option').forEach((x) => x.classList.remove('active'));
        refreshPreview();
        return;
      }
      if (btn.dataset.action === 'save') {
        if (selected !== null) {
          store.updateSettings({ avatar: selected === '__default__' ? null : selected });
          S.ui.toast(selected === '__default__' ? '↩️ 已恢复默认头像' : '✅ 头像已更新');
        }
        dlg.close();
      }
    });
    refreshPreview();
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.settings = { render };
})(typeof window !== 'undefined' ? window : globalThis);
