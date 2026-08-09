/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 设置页（我的） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const COLOR_PALETTE = [
    // 按色系顺序排列：粉红 → 桃橙 → 金黄 → 绿 → 蓝 → 紫（同色系相邻）
    '#F4B8CE', '#F5C4DC', '#F0C9C9',
    '#FAD1B8', '#F2D4A8',
    '#FBE6B9', '#F0DEB8',
    '#A9E0CB', '#BFE8C9', '#C8D8C0',
    '#B3D4F0', '#C9E8F0', '#B8D8E8',
    '#C9C7F0', '#E8D5F0', '#D8C8F0'
  ];
  const THEMES = [
    ['classic', '经典白', 'linear-gradient(135deg,#FBF6F2,#F4B8CE)'],
    ['bluegreen', '清新蓝绿', 'linear-gradient(135deg,#9ED8C6,#B0CFF0)'],
    ['sunshine', '阳光黄桃', 'linear-gradient(135deg,#F8CE9E,#DFE3A0)'],
    ['rose', '玫瑰粉', 'linear-gradient(135deg,#F5BCC4,#E0C4E8)'],
    ['lavender', '梦幻紫', 'linear-gradient(135deg,#D5C8F2,#C9B8EC)'],
    ['mint', '薄荷绿', 'linear-gradient(135deg,#BFE8C9,#A9E0CB)'],
    ['dark', '暗色', 'linear-gradient(135deg,#2E2738,#4A3F47)']
  ];

  function dataSize() {
    try {
      const bytes = new Blob([store.exportJSON()]).size;
      return bytes < 1024 ? bytes + ' B' : (bytes / 1024).toFixed(1) + ' KB';
    } catch (e) {
      return '—';
    }
  }

  /* ---------- v0.32.0：成就徽章墙 ---------- */
  function badgesWallHtml() {
    const rw = S.rewards;
    if (!rw) return '<div class="row-desc">完成作业即可解锁成就徽章</div>';
    const unlockedMap = rw.unlocked(store.state);
    return rw.BADGES.map((b) => {
      const t = unlockedMap[b.id];
      return '<div class="badge-item' + (t ? ' unlocked' : '') + '" title="' + util.escapeHtml(b.desc) + '">' +
        '<span class="badge-ico">' + S.icons.icon(b.icon, 22) + '</span>' +
        '<span class="badge-name">' + util.escapeHtml(b.name) + '</span>' +
        (t ? '<span class="badge-time">' + util.fmtDate(t) + '</span>' : '') +
        '</div>';
    }).join('');
  }

  /* ---------- v0.33.0：我的勋章横条（参考健康/多邻国个人主页） ---------- */
  function badgeStripHtml() {
    const rw = S.rewards;
    if (!rw) return '';
    const unlockedMap = rw.unlocked(store.state);
    const count = Object.keys(unlockedMap).length;
    const recent = rw.BADGES.filter((b) => unlockedMap[b.id]).slice(-6);
    return '<div class="badge-strip">' +
      '<div class="bs-head"><span>' + S.icons.icon('star', 14) + ' 我的勋章</span><b>' + count + '/' + rw.BADGES.length + '</b></div>' +
      '<div class="bs-list">' +
      (recent.length
        ? recent.map((b) => '<span class="bs-item" title="' + util.escapeHtml(b.name) + '">' + S.icons.icon(b.icon, 20) + '</span>').join('')
        : '<span class="bs-empty">完成作业解锁第一枚徽章</span>') +
      '</div></div>';
  }

  function switchRow(iconName, title, desc, key) {
    const checked = getSetting(key) ? ' checked' : '';
    return '<div class="settings-row"><span class="row-icon">' + S.icons.icon(iconName, 15) + '</span>' +
      '<div class="row-body"><div class="row-title">' + title + '</div>' +
      '<div class="row-desc">' + desc + '</div></div>' +
      '<span class="row-action switch"><input type="checkbox" data-toggle="' + key + '"' + checked + '><span class="track"></span><span class="thumb"></span></span></div>';
  }

  function getSetting(key) {
    return key.split('.').reduce((o, k) => (o == null ? undefined : o[k]), store.state.settings);
  }

  function patchSetting(key, val) {
    const ks = key.split('.');
    if (ks.length === 1) {
      store.updateSettings({ [ks[0]]: val });
    } else {
      const inner = Object.assign({}, store.state.settings[ks[0]] || {});
      inner[ks[1]] = val;
      store.updateSettings({ [ks[0]]: inner });
    }
  }

  function segRow(iconName, title, desc, id, options, attr, activeVal) {
    return '<div class="settings-row"><span class="row-icon">' + S.icons.icon(iconName, 15) + '</span>' +
      '<div class="row-body"><div class="row-title">' + title + '</div>' +
      '<div class="row-desc">' + desc + '</div></div>' +
      '<span class="row-action seg" id="' + id + '">' +
      options.map((v) => '<button data-' + attr + '="' + v + '"' + (activeVal === v ? ' class="active"' : '') + '>' + v + '</button>').join('') +
      '</span></div>';
  }

  /** 设置项静默更新：避免触发整页重建导致闪屏/开关跳动 */
  function quietSettingsUpdate(fn) {
    if (g.App) g.App._suspendView = true;
    try {
      fn();
    } finally {
      if (g.App) g.App._suspendView = false;
    }
  }

  function setSegActive(segEl, attrKey, val) {
    if (!segEl) return;
    segEl.querySelectorAll('button').forEach((b) => {
      b.classList.toggle('active', b.dataset[attrKey] === String(val));
    });
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
    const goals = Object.assign({ dailyXp: 50, dailyTasks: 3 }, set.rewardsGoals || {});
    const html =
      '<div class="settings-card reveal">' +
      '<div class="device-card">' +
      util.avatarHtml(set.avatar, 'avatar-lg') +
      '<div style="flex:1;min-width:0"><div class="device-name">' + util.escapeHtml(set.deviceName) + '</div>' +
      '<div class="device-meta">' + S.icons.icon('save', 12) + ' 离线优先 · 本地存储<br>' + S.icons.icon('list', 12) + ' 数据大小：' + dataSize() + '</div></div>' +
      '<button class="btn small" data-action="change-avatar">' + S.icons.icon('image', 13) + ' 换头像</button>' +
      '<button class="btn small" data-action="rename-device">' + S.icons.icon('edit', 13) + ' 改名</button>' +
      '</div>' +
      '<div class="profile-shortcuts">' +
      '<button class="ps-item" data-shortcut="badges">' + S.icons.icon('star', 18) + '<span>我的勋章</span></button>' +
      '<button class="ps-item" data-shortcut="stats">' + S.icons.icon('chart-bar', 18) + '<span>统计</span></button>' +
      '<button class="ps-item" data-shortcut="account">' + S.icons.icon('user', 18) + '<span>账号</span></button>' +
      '<button class="ps-item" data-shortcut="data">' + S.icons.icon('save', 18) + '<span>数据管理</span></button>' +
      '</div></div>' +

      '<div class="settings-card reveal"><h3>个性化</h3>' +
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
      switchRow('bell', '通知提醒', '截止日期与便签提醒（浏览器支持时）', 'notifications') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('clock', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">前一晚提醒时间</div>' +
      '<div class="row-desc">截止前一天的晚上提醒（默认 20:00）</div></div>' +
      '<span class="row-action"><input type="time" id="reminder-eve" value="' + (set.reminder.eve || '20:00') + '"></span></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('sun', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">当天早上提醒时间</div>' +
      '<div class="row-desc">当天早上提醒窗口起点（持续 2 小时，默认 07:00）</div></div>' +
      '<span class="row-action"><input type="time" id="reminder-morning" value="' + (set.reminder.morning || '07:00') + '"></span></div>' +
      switchRow('globe', '互联网模式', '跨网络同步（WebRTC · 规划中）', 'internetMode') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('sparkles', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">主题</div>' +
      '<div class="row-desc">5 套马卡龙配色 + 经典白 + 暗色，自由切换</div></div>' +
      '<span class="row-action palettes" id="theme-picker">' +
      THEMES.map((p) =>
        '<button class="palette-swatch' + (set.theme === p[0] ? ' active' : '') + '" data-theme-swatch="' + p[0] + '" title="' + p[1] + '" style="background:' + p[2] + '"></button>').join('') +
      '</span></div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('flame', 15) + ' 激励与成就</h3>' +
      badgeStripHtml() +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('bolt', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">每日 XP 目标</div>' +
      '<div class="row-desc">完成作业获得经验值，冲刺每日目标</div></div>' +
      '<span class="row-action seg" id="xp-goal-seg">' +
      [30, 50, 80, 100].map((v) =>
        '<button data-xp-goal="' + v + '"' + (goals.dailyXp === v ? ' class="active"' : '') + '>' + v + '</button>').join('') +
      '</span></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('check', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">每日完成目标</div>' +
      '<div class="row-desc">每天完成几项作业</div></div>' +
      '<span class="row-action seg" id="task-goal-seg">' +
      [2, 3, 5, 8].map((v) =>
        '<button data-task-goal="' + v + '"' + (goals.dailyTasks === v ? ' class="active"' : '') + '>' + v + '</button>').join('') +
      '</span></div>' +
      '<div class="badge-wall">' + badgesWallHtml() + '</div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('bolt', 15) + ' 番茄钟与专注场景</h3>' +
      segRow('clock', '专注时长', '一个番茄的时长（分钟）', 'pomo-focus-seg', [25, 45, 60], 'pomo-focus', set.pomodoro.focusMin) +
      segRow('moon', '短休息', '专注之间的短休息（分钟）', 'pomo-break-seg', [5, 10, 15], 'pomo-break', set.pomodoro.shortBreakMin) +
      segRow('sun', '长休息', '每 4 轮番茄后的长休息（分钟）', 'pomo-long-seg', [15, 20, 30], 'pomo-long', set.pomodoro.longBreakMin) +
      switchRow('bolt', '自动进入休息', '专注结束自动开始休息（否则暂停等待）', 'pomodoro.autoStartBreak') +
      switchRow('bell', '完成提示音', '番茄完成时播放提示音', 'pomodoro.soundOnFinish') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('music', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">默认专注场景</div>' +
      '<div class="row-desc">开始专注时自动播放的声音环境</div></div>' +
      '<span class="row-action"><select id="focus-scene">' +
      (S.ui.focus ? S.ui.focus.SCENES.filter((s) => !s.disabled && !(s.custom && !set.focus.customAudio)).map((s) =>
        '<option value="' + s.id + '"' + (set.focus.sceneId === s.id ? ' selected' : '') + '>' +
        (s.custom && set.focus.customAudio ? util.escapeHtml(set.focus.customAudio.name) : util.escapeHtml(s.name)) + '</option>').join('') : '') +
      '</select></span></div>' +
      '</div>' +

      (S.ui.account ? S.ui.account.cardHtml() : '') +
      (S.ui.account ? S.ui.account.familyCardHtml() : '') +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('heart', 15) + ' 好友直连</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('globe', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">端到端加密好友</div>' +
      '<div class="row-desc">加好友、加密消息、分享作业（无中心服务器）</div></div>' +
      '<button class="btn small soft-pink" data-action="open-friends">打开</button></div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('book', 15) + ' 教师模式</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('file-text', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">布置作业</div>' +
      '<div class="row-desc">按标准格式排好作业，复制/下载发到班级群；学生粘贴进糖纸即可一键导入</div></div>' +
      '<button class="btn small soft-pink" data-action="open-teacher">打开</button></div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>数据安全网</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('save', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">上次导出备份</div>' +
      '<div class="row-desc" id="last-export-time">' + (set.lastExportAt ? util.fmtDateTime(set.lastExportAt) : '从未导出') + '</div></div>' +
      '<button class="btn small soft-pink" data-action="export-data">立即备份</button></div>' +
      switchRow('bell', '自动备份提醒', '超过 7 天未导出时在首页提示', 'backupReminder') +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('save', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">存储用量</div>' +
      '<div class="row-desc" id="storage-usage">计算中…</div></div></div>' +
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

      '<div class="settings-card reveal"><h3>' + S.icons.icon('download', 15) + ' 更新</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('candy', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">当前版本</div>' +
      '<div class="row-desc">网页版 v' + store.APP_VERSION + ' · 与安卓版同步发布</div></div></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('globe', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">最新版本</div>' +
      '<div class="row-desc" id="latest-version-desc">检查中…</div></div>' +
      '<button class="btn small" data-action="check-update">检查</button></div>' +
      '<div class="settings-row" id="update-actions-row" hidden><span class="row-icon">' + S.icons.icon('bolt', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">发现新版本</div>' +
      '<div class="row-desc">刷新页面即可获取最新网页版</div></div>' +
      '<button class="btn small primary" data-action="update-refresh">立即刷新</button>' +
      '<a class="btn small" href="https://github.com/HelloXiYangyang/SugarPaper/releases" target="_blank" rel="noopener">更新记录</a></div>' +
      '</div>' +

      '<div class="settings-card reveal"><h3>' + S.icons.icon('book', 15) + ' 法律与隐私</h3>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('file-text', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">用户协议</div>' +
      '<div class="row-desc">v1.0.0 · 首次使用需阅读并同意</div></div>' +
      '<button class="btn small" data-action="view-terms">查看</button></div>' +
      '<div class="settings-row"><span class="row-icon">' + S.icons.icon('file-text', 15) + '</span>' +
      '<div class="row-body"><div class="row-title">隐私政策</div>' +
      '<div class="row-desc">v1.0.0 · 个人信息处理规则</div></div>' +
      '<button class="btn small" data-action="view-privacy">查看</button></div>' +
      '</div>' +

      '<div class="settings-card reveal"><div class="about-block">' +
      '<img class="about-icon" src="icon.svg" alt="糖纸图标">' +
      '<div class="about-name">糖纸 · SugarPaper</div>' +
      '<div class="about-ver">v' + store.APP_VERSION + '（Web 版）</div>' +
      '<div class="about-slogan">让作业管理像糖果一样甜美简单。</div>' +
'<div class="about-slogan">离线优先 · 设备直连 · 现代简洁美学 · 零服务器依赖</div>' +
      '</div></div>' +

      '<input type="file" id="import-file" accept=".json,application/json" hidden>';

    wrap.innerHTML = html;
    bind(wrap);

    // 更新状态行：进入设置页时同步最新检查结果
    const updater = S.updater;
    if (updater) refreshUpdateRow(wrap, updater);
  }

  function refreshUpdateRow(wrap, updater) {
    const desc = wrap.querySelector('#latest-version-desc');
    const row = wrap.querySelector('#update-actions-row');
    if (!desc) return;
    const st = updater.state;
    if (st.checking) {
      desc.textContent = '正在检查更新…';
      if (row) row.hidden = true;
      return;
    }
    if (st.latest) {
      if (st.updateAvailable) {
        desc.textContent = 'v' + st.latest.version + ' · 可更新';
        if (row) row.hidden = false;
      } else {
        desc.textContent = 'v' + st.latest.version + ' · 已是最新版本';
        if (row) row.hidden = true;
      }
    } else if (st.error) {
      desc.textContent = '检查失败（离线或元数据未部署）';
      if (row) row.hidden = true;
    } else {
      desc.textContent = '尚未检查';
      if (row) row.hidden = true;
    }
  }

  function bind(wrap) {
    // v0.33.0：个人信息头卡快捷入口（勋章/统计/账号/数据管理）
    wrap.querySelectorAll('[data-shortcut]').forEach((b) => {
      b.addEventListener('click', () => {
        const t = b.dataset.shortcut;
        if (t === 'stats') { g.App.navigate('stats'); return; }
        const map = { badges: '激励与成就', account: '账号与同步', data: '数据管理' };
        const label = map[t];
        if (!label) return;
        const card = [...wrap.querySelectorAll('.settings-card')].find((c) => c.innerText.indexOf(label) >= 0);
        if (card) card.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    });

    if (S.ui.account) S.ui.account.bind(wrap);
    wrap.querySelectorAll('input[data-toggle]').forEach((inp) => {
      inp.addEventListener('change', () => {
        quietSettingsUpdate(() => {
          patchSetting(inp.dataset.toggle, inp.checked);
          g.App.applyPrefs();
        });
        if (inp.dataset.toggle === 'notifications' && inp.checked && g.Notification && g.Notification.requestPermission) {
          g.Notification.requestPermission();
        }
      });
    });

    const pomoFocus = wrap.querySelector('#pomo-focus-seg');
    if (pomoFocus) {
      pomoFocus.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-pomo-focus]');
        if (!btn) return;
        quietSettingsUpdate(() => patchSetting('pomodoro.focusMin', +btn.dataset.pomoFocus));
        setSegActive(pomoFocus, 'pomoFocus', btn.dataset.pomoFocus);
      });
    }
    const pomoBreak = wrap.querySelector('#pomo-break-seg');
    if (pomoBreak) {
      pomoBreak.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-pomo-break]');
        if (!btn) return;
        quietSettingsUpdate(() => patchSetting('pomodoro.shortBreakMin', +btn.dataset.pomoBreak));
        setSegActive(pomoBreak, 'pomoBreak', btn.dataset.pomoBreak);
      });
    }
    const pomoLong = wrap.querySelector('#pomo-long-seg');
    if (pomoLong) {
      pomoLong.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-pomo-long]');
        if (!btn) return;
        quietSettingsUpdate(() => patchSetting('pomodoro.longBreakMin', +btn.dataset.pomoLong));
        setSegActive(pomoLong, 'pomoLong', btn.dataset.pomoLong);
      });
    }
    const sceneSel = wrap.querySelector('#focus-scene');
    if (sceneSel) {
      sceneSel.addEventListener('change', () => {
        quietSettingsUpdate(() => patchSetting('focus.sceneId', sceneSel.value));
        S.ui.toast('默认场景已更新');
      });
    }
    const reminderEve = wrap.querySelector('#reminder-eve');
    if (reminderEve) {
      reminderEve.addEventListener('change', () => {
        quietSettingsUpdate(() => store.updateSettings({ reminder: Object.assign({}, store.state.settings.reminder, { eve: reminderEve.value }) }));
        S.ui.toast('前一晚提醒时间已更新');
      });
    }
    const reminderMorning = wrap.querySelector('#reminder-morning');
    if (reminderMorning) {
      reminderMorning.addEventListener('change', () => {
        quietSettingsUpdate(() => store.updateSettings({ reminder: Object.assign({}, store.state.settings.reminder, { morning: reminderMorning.value }) }));
        S.ui.toast('早上提醒时间已更新');
      });
    }
    if (g.navigator && g.navigator.storage && g.navigator.storage.estimate) {
      g.navigator.storage.estimate().then((est) => {
        const el = wrap.querySelector('#storage-usage');
        if (!el) return;
        const used = est.usage || 0;
        const quota = est.quota || 0;
        const usedKb = (used / 1024).toFixed(0);
        const quotaMb = (quota / 1024 / 1024).toFixed(0);
        const pct = quota ? Math.round((used / quota) * 100) : 0;
        el.innerHTML = '已用 ' + usedKb + ' KB / 可用约 ' + quotaMb + ' MB（' + pct + '%）' +
          (pct > 80 ? ' · <span style="color:var(--danger-strong)">空间紧张，建议导出备份</span>' : '');
      }).catch(() => {
        const el = wrap.querySelector('#storage-usage');
        if (el) el.textContent = '当前浏览器不支持估算';
      });
    }

    const fpsSeg = wrap.querySelector('#fps-seg');
    if (fpsSeg) {
      fpsSeg.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-frame-rate]');
        if (!btn) return;
        quietSettingsUpdate(() => {
          store.updateSettings({ frameRate: btn.dataset.frameRate });
          g.App.applyPrefs();
        });
        setSegActive(fpsSeg, 'frameRate', btn.dataset.frameRate);
      });
    }

    // v0.32.0：激励目标设定
    const xpGoalSeg = wrap.querySelector('#xp-goal-seg');
    if (xpGoalSeg) {
      xpGoalSeg.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-xp-goal]');
        if (!btn) return;
        quietSettingsUpdate(() => {
          store.updateSettings({
            rewardsGoals: Object.assign({}, store.state.settings.rewardsGoals || {}, { dailyXp: +btn.dataset.xpGoal })
          });
        });
        setSegActive(xpGoalSeg, 'xpGoal', btn.dataset.xpGoal);
      });
    }
    const taskGoalSeg = wrap.querySelector('#task-goal-seg');
    if (taskGoalSeg) {
      taskGoalSeg.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-task-goal]');
        if (!btn) return;
        quietSettingsUpdate(() => {
          store.updateSettings({
            rewardsGoals: Object.assign({}, store.state.settings.rewardsGoals || {}, { dailyTasks: +btn.dataset.taskGoal })
          });
        });
        setSegActive(taskGoalSeg, 'taskGoal', btn.dataset.taskGoal);
      });
    }

    const themePicker = wrap.querySelector('#theme-picker');
    if (themePicker) {
      themePicker.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-theme-swatch]');
        if (!btn) return;
        quietSettingsUpdate(() => {
          store.updateSettings({ theme: btn.dataset.themeSwatch });
          g.App.applyPrefs();
        });
        themePicker.querySelectorAll('.palette-swatch').forEach((s) => {
          s.classList.toggle('active', s.dataset.themeSwatch === btn.dataset.themeSwatch);
        });
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
    onConfirm: (v) => { store.updateSettings({ deviceName: v }); S.ui.toast('设备名称已更新'); }
          });
        } else if (a === 'change-avatar') {
          openAvatarModal();
        } else if (a === 'fps-test') {
          g.App.detectFps().then((fps) => {
            const mode = g.App.resolveFps();
            const desc = wrap.querySelector('#fps-result');
            if (desc) desc.textContent = '当前实际帧率：约 ' + fps + ' FPS · 动画档位 ' + mode;
    S.ui.toast('当前流畅度：约 ' + fps + ' FPS');
          });
        } else if (a === 'export-data') {
          const blob = new Blob([store.exportJSON()], { type: 'application/json;charset=utf-8' });
          const link = document.createElement('a');
          link.href = URL.createObjectURL(blob);
          link.download = '糖纸-备份-' + util.todayStr() + '.json';
          link.click();
          URL.revokeObjectURL(link.href);
          store.updateSettings({ lastExportAt: new Date().toISOString() });
    S.ui.toast('数据已导出');
          g.App.renderView();
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
    onConfirm: () => { store.reset(); S.ui.toast('数据已清空'); }
          });
        } else if (a === 'add-subject') {
          openSubjectModal();
        } else if (a === 'open-teacher') {
          S.ui.teacher.openTeacherModal();
        } else if (a === 'check-update') {
          const updater = S.updater;
          if (!updater) return;
          const desc = wrap.querySelector('#latest-version-desc');
          if (desc) desc.textContent = '正在检查更新…';
          updater.check(true).then(() => refreshUpdateRow(wrap, updater));
        } else if (a === 'update-refresh') {
          if (S.updater) S.updater.refresh();
        } else if (a === 'view-terms') {
          if (S.legal) S.legal.view('terms');
        } else if (a === 'view-privacy') {
          if (S.legal) S.legal.view('privacy');
        } else if (a === 'open-friends') {
          if (S.ui.friends) S.ui.friends.openPanel();
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
    S.ui.toast('数据导入成功');
            g.App.render();
          } catch (err) {
    S.ui.toast('导入失败：' + err.message);
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
    S.ui.toast('科目已更新');
      } else {
        const ok = store.addSubject(n, color);
    S.ui.toast(ok ? '科目已添加' : '科目已存在');
      }
      dlg.close();
    });
  }

  /* ---------- 更换头像弹窗 ---------- */
  function openAvatarModal() {
    const current = store.state.settings.avatar;
    const dlg = S.ui.modal.open({ title: '头像', footer: '' });
    dlg.bodyEl.innerHTML =
      '<div class="avatar-preview">' +
      util.avatarHtml(current, 'avatar-lg') +
      '<span>' + (current ? '当前为自定义头像' : '当前为默认头像') + '</span></div>' +
      '<div class="field"><label>' + S.icons.icon('camera', 12) + ' 自定义头像</label>' +
      '<label class="avatar-upload" id="avatar-upload" for="avatar-file">' +
      '<span class="au-icon">' + S.icons.icon('upload', 22) + '</span>' +
      '<span class="au-title">点击选择或拖拽图片上传</span>' +
      '<span class="au-hint">自动压缩至 256×256 · 仅存本机</span>' +
      '</label>' +
      '<input type="file" id="avatar-file" accept="image/*" hidden></div>';
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="close">关闭</button>' +
      (current ? '<button class="btn soft-danger" data-action="reset">恢复默认头像</button>' : '');
    const handleFile = (file) => {
      if (!file) return;
      compressImage(file, (dataUrl) => {
        store.updateSettings({ avatar: dataUrl });
        S.ui.toast('头像已更新');
        dlg.close();
      });
    };
    dlg.bodyEl.querySelector('#avatar-file').addEventListener('change', () => {
      handleFile(dlg.bodyEl.querySelector('#avatar-file').files[0]);
    });
    const uploadZone = dlg.bodyEl.querySelector('#avatar-upload');
    uploadZone.addEventListener('dragover', (e) => {
      e.preventDefault();
      uploadZone.classList.add('dragover');
    });
    uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('dragover'));
    uploadZone.addEventListener('drop', (e) => {
      e.preventDefault();
      uploadZone.classList.remove('dragover');
      handleFile(e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]);
    });
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'reset') {
        store.updateSettings({ avatar: null });
        S.ui.toast('已恢复默认头像');
        dlg.close();
      }
    });
  }

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
      img.onerror = () => S.ui.toast('图片读取失败，请换一张试试');
      img.src = reader.result;
    };
    reader.readAsDataURL(file);
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.settings = { render };
})(typeof window !== 'undefined' ? window : globalThis);
