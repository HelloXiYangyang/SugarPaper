/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 本地存储与状态管理（离线优先） */
(function (g) {
  'use strict';

  const KEY = 'sugarpaper:v1';
  const APP_VERSION = '0.13.2';

  // 默认学科清单（v4.1 统一）：覆盖小学/初中/高中，全平台保持一致
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
      subjects: DEFAULT_SUBJECTS.map((s) => ({ ...s })),
      settings: {
        darkMode: false,
        deviceName: '我的设备',
        notifications: false,
        internetMode: false,
        animations: true, // 动画总开关（false 时禁用全部动画）
        frameRate: 'auto', // 帧率模式：auto(跟随系统) / 60 / 120
        avatar: null, // 头像：null=默认；emoji 字符串；data: 开头的图片 DataURL
        version: APP_VERSION,
        lastSyncTime: null
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
    return {
      tasks: Array.isArray(d.tasks) ? d.tasks : base.tasks,
      subjects,
      settings: Object.assign({}, base.settings, d.settings || {})
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
      priority: input.priority == null ? 1 : input.priority
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
      subjects: state.subjects,
      settings: state.settings
    }, null, 2);
  }

  function importJSON(json) {
    const d = typeof json === 'string' ? JSON.parse(json) : json;
    if (!d || !Array.isArray(d.tasks)) throw new Error('不是有效的糖纸备份文件');
    state.tasks = d.tasks.map((t) => normalizeTask(t));
    state.subjects = Array.isArray(d.subjects) && d.subjects.length ? d.subjects : DEFAULT_SUBJECTS.map((s) => ({ ...s }));
    state.settings = Object.assign({}, defaultState().settings, d.settings || {});
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
    toggleComplete,
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
