/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 本地存储与状态管理（离线优先） */
(function (g) {
  'use strict';

  const KEY = 'sugarpaper:v1';
  const APP_VERSION = '0.34.0';

  // 默认学科清单（v4.1 统一）：覆盖小学/初中/高中，各端保持一致
  const DEFAULT_SUBJECTS = [
    { name: '语文', color: '#F4B8CE', enabled: true },
    { name: '数学', color: '#B3D4F0', enabled: true },
    { name: '英语', color: '#C9C7F0', enabled: true },
    { name: '物理', color: '#A9E0CB', enabled: true },
    { name: '化学', color: '#FBE6B9', enabled: true },
    { name: '生物', color: '#BFE8C9', enabled: true },
    { name: '历史', color: '#E8D5F0', enabled: true },
    { name: '地理', color: '#C9E8F0', enabled: true },
    { name: '政治', color: '#F0C9C9', enabled: true },
    { name: '体育与健康', color: '#FAD1B8', enabled: true },
    { name: '音乐', color: '#F5C4DC', enabled: true },
    { name: '美术', color: '#F2D4A8', enabled: true },
    { name: '信息技术', color: '#B8D8E8', enabled: true },
    { name: '通用技术', color: '#C8D8C0', enabled: true },
    { name: '劳动', color: '#F0DEB8', enabled: true },
    { name: '综合实践活动', color: '#D8C8F0', enabled: true }
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function defaultState() {
    return {
      tasks: [],
      notes: [],
      focusSessions: [],
      account: null, // v0.16.0：无服务器账号 { pubkey, displayName, seedB64, mnemonic, version, lastSyncAt, devices }
      subjects: DEFAULT_SUBJECTS.map((s) => ({ ...s })),
      settings: {
        deviceName: '我的设备',
        notifications: false,
        internetMode: false,
        animations: true, // 动画总开关（false 时禁用全部动画）
        frameRate: 'auto', // 帧率模式：auto(跟随系统) / 60 / 120
        darkMode: false, // 兼容旧数据（迁移到 theme 后不再使用）
        palette: 'classic', // 兼容旧数据（迁移到 theme 后不再使用）
        theme: 'classic', // 主题（七套平行）：classic / bluegreen / sunshine / rose / lavender / mint / dark
        avatar: null, // 头像：null=默认；emoji 字符串；data: 开头的图片 DataURL
        version: APP_VERSION,
        lastSyncTime: null,
        // v0.15.0：番茄钟配置
        pomodoro: {
          focusMin: 25,
          shortBreakMin: 5,
          longBreakMin: 15,
          roundsBeforeLongBreak: 4,
          autoStartBreak: false,
          autoStartFocus: false,
          soundOnFinish: true
        },
        // v0.15.0：专注场景偏好
        focus: {
          sceneId: 'pink-noise',
          volume: 0.6,
          // v0.17.0：叠加音混音（Noisli 式）
          mixSceneId: null,
          mixVolume: 0.4,
        // v0.18.0：自定义声音场景（本地音频 dataURL，≤2MB）
          customAudio: null
        },
        // v0.22.0：提醒时间自定义（前一晚 / 当天早上窗口起点）
        reminder: {
          eve: '20:00',
          morning: '07:00'
        },
        // v0.15.0：数据安全网（自动备份提醒 / 已提醒标记）
        backupReminder: true,
        lastExportAt: null,
        backupSnoozedAt: null,
        notifiedDue: {},
        notifiedNotes: {},
        // v0.16.0：跨设备同步（S2）
        sync: {
          autoSync: false,
          relays: ['wss://relay.damus.io', 'wss://nostr.wine', 'wss://relay.nostr.band']
        },
        // v0.17.0：家庭模式——本机保存的家庭成员档案（助记词 + 昵称），可快捷切换账号代管
        familyProfiles: []
      }
    };
  }

  function migrate(raw) {
    const d = raw || {};
    const base = defaultState();
    // v0.7.1：保证小初高 16 科默认学科齐全（不覆盖用户已有配置，只补充缺失科目）
    const subjects = Array.isArray(d.subjects) ? d.subjects.slice() : base.subjects;
    DEFAULT_SUBJECTS.forEach((s) => {
      if (!subjects.some((x) => x.name === s.name)) subjects.push({ ...s });
    });
    // v0.14.0：旧版 darkMode / palette 迁移为独立 theme（七套平行主题）
    const settings = Object.assign({}, base.settings, d.settings || {});
    if (d.settings && !d.settings.theme) {
      settings.theme = settings.darkMode ? 'dark' : (settings.palette || 'classic');
    }
    // v0.15.0：深层合并嵌套配置，避免旧数据缺失新字段
    settings.pomodoro = Object.assign({}, base.settings.pomodoro, (d.settings && d.settings.pomodoro) || {});
    settings.focus = Object.assign({}, base.settings.focus, (d.settings && d.settings.focus) || {});
    // v0.16.0：同步配置深层合并
    settings.sync = Object.assign({}, base.settings.sync, (d.settings && d.settings.sync) || {});
    if (!Array.isArray(settings.sync.relays) || !settings.sync.relays.length) {
      settings.sync.relays = base.settings.sync.relays.slice();
    }
    // v0.22.0：提醒配置深层合并
    settings.reminder = Object.assign({}, base.settings.reminder, (d.settings && d.settings.reminder) || {});
    return {
      tasks: Array.isArray(d.tasks) ? d.tasks : base.tasks,
      notes: Array.isArray(d.notes) ? d.notes : base.notes,
      focusSessions: Array.isArray(d.focusSessions) ? d.focusSessions : base.focusSessions,
      account: d.account ? Object.assign({}, base.account, d.account) : null,
      subjects,
      settings
    };
  }

  function load() {
    try {
      const raw = g.localStorage ? g.localStorage.getItem(KEY) : null;
      if (raw) return migrate(JSON.parse(raw));
    } catch (e) {
      console.warn('[store] 读取本地数据失败：', e);
    }
    return defaultState();
  }

  const state = load();
  const listeners = [];

  function persist() {
    try {
      if (g.localStorage) g.localStorage.setItem(KEY, JSON.stringify(state));
    } catch (e) {
      console.warn('[store] 写入本地数据失败：', e);
    }
  }

  function emit() {
    listeners.slice().forEach((fn) => {
      try { fn(); } catch (e) { console.error(e); }
    });
  }

  function subscribe(fn) {
    listeners.push(fn);
    return () => {
      const i = listeners.indexOf(fn);
      if (i >= 0) listeners.splice(i, 1);
    };
  }

  function findTask(id) {
    return state.tasks.find((t) => t.id === id);
  }

  function normalizeTask(input) {
    const now = nowIso();
    const text = String((input.title || '') + ' ' + (input.subtitle || ''));
    return {
      id: input.id || g.Sugar.util.uuid(),
      subject: input.subject || '默认',
      title: String(input.title || '').trim(),
      subtitle: input.subtitle || '',
      isCompleted: !!input.isCompleted,
      order: input.order == null ? maxOrder() + 1 : input.order,
      createdAt: input.createdAt || now,
      updatedAt: input.updatedAt || now,
      isDeleted: !!input.isDeleted,
      completedAt: input.completedAt || (input.isCompleted ? now : null),
      dueDate: input.dueDate || null,
      priority: input.priority == null ? 1 : input.priority,
      // v0.17.0：任务类型（written/recite/checkin）与家长确认标记
      taskType: input.taskType || (g.Sugar.parser && g.Sugar.parser.detectTaskType(text)) || 'written',
      confirmed: !!input.confirmed,
      // v0.22.0：作业图片附件（拍照存档，最多 4 张，dataURL 仅存本机）
      images: Array.isArray(input.images) ? input.images.slice(0, 4) : []
    };
  }

  function maxOrder() {
    return state.tasks.reduce((mx, t) => (t.isDeleted ? mx : Math.max(mx, t.order || 0)), 0);
  }

  function addTask(input) {
    const task = normalizeTask(input);
    state.tasks.push(task);
    persist();
    emit();
    return task;
  }

  function addTasks(list) {
    const added = list.map((t) => normalizeTask(t));
    state.tasks.push(...added);
    persist();
    emit();
    return added;
  }

  function updateTask(id, patch) {
    const t = findTask(id);
    if (!t) return null;
    Object.assign(t, patch, { updatedAt: nowIso() });
    persist();
    emit();
    return t;
  }

  function deleteTask(id) {
    const t = findTask(id);
    if (!t) return;
    t.isDeleted = true;
    t.updatedAt = nowIso();
    persist();
    emit();
  }

  /* ---------- 便签（v0.15.0） ---------- */

  function normalizeNote(input) {
    const now = nowIso();
    return {
      id: input.id || g.Sugar.util.uuid(),
      title: String(input.title || '').trim(),
      content: String(input.content || ''),
      color: input.color || input.colorHex || '#F4B8CE',
      colorHex: input.colorHex || input.color || '#F4B8CE',
      pinned: !!input.pinned,
      archived: !!input.archived,
      tags: Array.isArray(input.tags) ? input.tags.slice() : [],
      remindAt: input.remindAt || null,
      // v0.19.0：图片附件（压缩后的 dataURL，随便签加密同步）
      images: Array.isArray(input.images) ? input.images.slice(0, 4) : [],
      createdAt: input.createdAt || now,
      updatedAt: input.updatedAt || now,
      isDeleted: !!input.isDeleted
    };
  }

  function findNote(id) {
    return state.notes.find((n) => n.id === id);
  }

  function addNote(input) {
    const note = normalizeNote(input);
    state.notes.push(note);
    persist();
    emit();
    return note;
  }

  function updateNote(id, patch) {
    const n = findNote(id);
    if (!n) return null;
    Object.assign(n, patch, { updatedAt: nowIso() });
    if (patch.tags !== undefined && !Array.isArray(patch.tags)) n.tags = [];
    persist();
    emit();
    return n;
  }

  function deleteNote(id) {
    const n = findNote(id);
    if (!n) return;
    n.isDeleted = true;
    n.updatedAt = nowIso();
    persist();
    emit();
  }

  function toggleNotePin(id) {
    const n = findNote(id);
    if (!n) return null;
    n.pinned = !n.pinned;
    n.updatedAt = nowIso();
    persist();
    emit();
    return n;
  }

  function toggleNoteArchive(id) {
    const n = findNote(id);
    if (!n) return null;
    n.archived = !n.archived;
    n.updatedAt = nowIso();
    persist();
    emit();
    return n;
  }

  /* ---------- 专注会话（v0.15.0） ---------- */

  function addFocusSession(input) {
    const now = nowIso();
    const task = input.taskId ? state.tasks.find((t) => t.id === input.taskId) : null;
    const session = {
      id: input.id || g.Sugar.util.uuid(),
      taskId: input.taskId || null,
      taskTitle: input.taskTitle || (task ? task.title : null),
      subject: input.subject || null,
      sceneId: input.sceneId || null,
      startAt: input.startAt || now,
      endAt: input.endAt || now,
      minutes: Math.max(1, Math.round(input.minutes || 1)),
      pomodoros: input.pomodoros || 1,
      completed: !!input.completed,
      source: input.source || 'pomodoro',
      updatedAt: input.updatedAt || input.endAt || now
    };
    state.focusSessions.push(session);
    persist();
    emit();
    return session;
  }

  /* ---------- 账号（v0.16.0 / S2） ---------- */

  function setAccount(acc) {
    state.account = acc;
    persist();
    emit();
    return acc;
  }

  function updateAccount(patch) {
    if (!state.account) return null;
    state.account = Object.assign({}, state.account, patch);
    persist();
    emit();
    return state.account;
  }

  function clearAccount() {
    state.account = null;
    persist();
    emit();
  }

  /* ---------- 家庭模式档案（v0.17.0） ---------- */

  function addFamilyProfile(profile) {
    const list = Array.isArray(state.settings.familyProfiles) ? state.settings.familyProfiles.slice() : [];
    list.push({
      id: profile.id || g.Sugar.util.uuid(),
      label: profile.label || '家庭成员',
      mnemonic: profile.mnemonic,
      pubkey: profile.pubkey || '',
      createdAt: profile.createdAt || nowIso()
    });
    updateSettings({ familyProfiles: list });
    return list[list.length - 1];
  }

  function removeFamilyProfile(id) {
    const list = (state.settings.familyProfiles || []).filter((p) => p.id !== id);
    updateSettings({ familyProfiles: list });
  }

  function replaceAll(data) {
    if (Array.isArray(data.tasks)) state.tasks = data.tasks;
    if (Array.isArray(data.notes)) state.notes = data.notes;
    if (Array.isArray(data.focusSessions)) state.focusSessions = data.focusSessions;
    persist();
    emit();
  }

  function toggleComplete(id) {
    const t = findTask(id);
    if (!t) return;
    const now = nowIso();
    t.isCompleted = !t.isCompleted;
    t.completedAt = t.isCompleted ? now : null;
    t.updatedAt = now;
    persist();
    emit();
    return t;
  }

  /** 家长确认（打卡类任务）：确认/取消确认 */
  function toggleConfirm(id) {
    const t = findTask(id);
    if (!t) return null;
    t.confirmed = !t.confirmed;
    t.updatedAt = nowIso();
    persist();
    emit();
    return t;
  }

  function moveTask(id, dir) {
    const active = state.tasks
      .filter((t) => !t.isDeleted && !t.isCompleted)
      .sort((a, b) => (a.order || 0) - (b.order || 0) || (a.createdAt < b.createdAt ? -1 : 1));
    const i = active.findIndex((t) => t.id === id);
    if (i < 0) return;
    const j = i + dir;
    if (j < 0 || j >= active.length) return;
    const tmp = active[i].order;
    active[i].order = active[j].order;
    active[j].order = tmp;
    active[i].updatedAt = nowIso();
    active[j].updatedAt = nowIso();
    persist();
    emit();
  }

  function importTasks(tasks, mode) {
    if (mode === 'overwrite') {
      state.tasks = [];
    }
    addTasks(tasks);
  }

  function getSubjectColor(name) {
    const s = state.subjects.find((x) => x.name === name);
    return s ? s.color : '#C9C7F0';
  }

  function addSubject(name, color) {
    if (state.subjects.some((s) => s.name === name)) return false;
    state.subjects.push({ name, color: color || '#C9C7F0', enabled: true });
    persist();
    emit();
    return true;
  }

  function updateSubject(name, patch) {
    const s = state.subjects.find((x) => x.name === name);
    if (!s) return false;
    const oldName = s.name;
    Object.assign(s, patch);
    if (patch.name && patch.name !== oldName) {
      state.tasks.forEach((t) => {
        if (t.subject === oldName) t.subject = patch.name;
      });
    }
    persist();
    emit();
    return true;
  }

  function removeSubject(name) {
    const i = state.subjects.findIndex((s) => s.name === name);
    if (i < 0) return;
    state.subjects.splice(i, 1);
    persist();
    emit();
  }

  function updateSettings(patch) {
    Object.assign(state.settings, patch);
    persist();
    emit();
  }

  function exportJSON() {
    return JSON.stringify({
      app: 'SugarPaper',
      kind: 'backup',
      version: APP_VERSION,
      exportedAt: nowIso(),
      tasks: state.tasks,
      notes: state.notes,
      focusSessions: state.focusSessions,
      account: state.account,
      subjects: state.subjects,
      settings: state.settings
    }, null, 2);
  }

  function importJSON(json) {
    const d = typeof json === 'string' ? JSON.parse(json) : json;
    if (!d || !Array.isArray(d.tasks)) throw new Error('不是有效的糖纸备份文件');
    state.tasks = d.tasks.map((t) => normalizeTask(t));
    state.notes = Array.isArray(d.notes) ? d.notes.map((n) => normalizeNote(n)) : [];
    state.focusSessions = Array.isArray(d.focusSessions) ? d.focusSessions : [];
    state.account = d.account ? Object.assign({}, defaultState().account, d.account) : null;
    state.subjects = Array.isArray(d.subjects) && d.subjects.length ? d.subjects : DEFAULT_SUBJECTS.map((s) => ({ ...s }));
    state.settings = Object.assign({}, defaultState().settings, d.settings || {});
    state.settings.pomodoro = Object.assign({}, defaultState().settings.pomodoro, (d.settings && d.settings.pomodoro) || {});
    state.settings.focus = Object.assign({}, defaultState().settings.focus, (d.settings && d.settings.focus) || {});
    state.settings.sync = Object.assign({}, defaultState().settings.sync, (d.settings && d.settings.sync) || {});
    state.settings.reminder = Object.assign({}, defaultState().settings.reminder, (d.settings && d.settings.reminder) || {});
    persist();
    emit();
  }

  function reset() {
    const fresh = defaultState();
    state.tasks = fresh.tasks;
    state.subjects = fresh.subjects;
    state.settings = fresh.settings;
    persist();
    emit();
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.store = {
    KEY,
    APP_VERSION,
    DEFAULT_SUBJECTS,
    state,
    persist,
    subscribe,
    addTask,
    addTasks,
    updateTask,
    deleteTask,
    addNote,
    updateNote,
    deleteNote,
    toggleNotePin,
    toggleNoteArchive,
    addFocusSession,
    setAccount,
    updateAccount,
    clearAccount,
    addFamilyProfile,
    removeFamilyProfile,
    replaceAll,
    toggleComplete,
    toggleConfirm,
    moveTask,
    importTasks,
    getSubjectColor,
    addSubject,
    updateSubject,
    removeSubject,
    updateSettings,
    exportJSON,
    importJSON,
    reset
  };
})(typeof window !== 'undefined' ? window : globalThis);
