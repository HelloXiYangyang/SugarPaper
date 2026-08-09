/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 激励引擎（v0.32.0，S18 模块一）
   多邻国式个人激励：XP / 连胜 / 成就徽章 / 欠账复习。
   全部为纯函数派生（不破坏现有数据模型）；徽章解锁状态存 settings.achievements，
   欠账补完计数存 settings.rewards，均随加密快照同步。
   本模块是纯计算层，UI 动画见 ui-home / ui-stats / ui-settings。 */
(function (g) {
  'use strict';

  const util = g.Sugar.util;

  const XP_BASE = { checkin: 10, recite: 15, written: 20 };
  const BADGES = [
    { id: 'first-step', name: '初来乍到', desc: '完成第 1 项作业', icon: 'star' },
    { id: 'ten-strong', name: '十全十美', desc: '累计完成 10 项作业', icon: 'check' },
    { id: 'hundred', name: '百炼成钢', desc: '累计完成 100 项作业', icon: 'flame' },
    { id: 'three-day', name: '三天打鱼', desc: '连续 3 天完成作业', icon: 'sparkles' },
    { id: 'week-streak', name: '一周连胜', desc: '连续 7 天完成作业', icon: 'candy' },
    { id: 'month-king', name: '全勤王', desc: '连续 30 天完成作业', icon: 'sun' },
    { id: 'focus-100', name: '专注达人', desc: '累计完成 100 个番茄', icon: 'bolt' },
    { id: 'night-owl', name: '夜猫子', desc: '累计 50 个番茄在 21 点后完成', icon: 'moon' },
    { id: 'on-time', name: '准时侠', desc: '完成 5 项以上且准时率 90%', icon: 'clock' },
    { id: 'comeback', name: '逆袭者', desc: '完成 1 次欠账补完', icon: 'undo' },
    { id: 'perfect-week', name: '满分周', desc: '某一周内作业全部按时完成', icon: 'target' },
    { id: 'family-helper', name: '家人好帮手', desc: '启用家庭模式且累计完成 20 项', icon: 'heart' }
  ];

  function dateStr(d) {
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  function todayStr() {
    return dateStr(new Date());
  }

  /** 任务是否逾期（未完成且截止日期早于参考日） */
  function isOverdue(task, ref) {
    if (!task || task.isCompleted) return false;
    return !!(task.dueDate && String(task.dueDate) < (ref || todayStr()));
  }

  /** 单任务 XP：类型基础分 + 高优先级 50% + 欠账补完双倍 */
  function taskXp(task, opts) {
    const t = task || {};
    let xp = XP_BASE[t.taskType] || XP_BASE.written;
    if (t.priority === 2) xp = Math.round(xp * 1.5);
    if (opts && opts.overdueBoost && isOverdue(t)) xp *= 2;
    return xp;
  }

  /** 某天完成的任务 */
  function completedOn(tasks, day) {
    const ref = day || todayStr();
    return (tasks || []).filter((t) => t.isCompleted && t.completedAt &&
      dateStr(new Date(t.completedAt)) === ref);
  }

  /** 某天完成项数与 XP */
  function daySummary(tasks, day) {
    const list = completedOn(tasks, day);
    return {
      count: list.length,
      xp: list.reduce((s, t) => s + taskXp(t), 0)
    };
  }

  /** 本周（周一起）完成项数与 XP */
  function weekSummary(tasks, ref) {
    const now = ref ? new Date(ref) : new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const back = (start.getDay() + 6) % 7;
    start.setDate(start.getDate() - back);
    let count = 0, xp = 0;
    (tasks || []).forEach((t) => {
      if (!t.isCompleted || !t.completedAt) return;
      const d = new Date(t.completedAt);
      if (d >= start) { count++; xp += taskXp(t); }
    });
    return { count, xp };
  }

  /** 历史最佳单日 XP */
  function bestDayXp(tasks) {
    const map = {};
    (tasks || []).forEach((t) => {
      if (!t.isCompleted || !t.completedAt) return;
      const k = dateStr(new Date(t.completedAt));
      map[k] = (map[k] || 0) + taskXp(t);
    });
    return Math.max(0, ...Object.keys(map).map((k) => map[k]));
  }

  /** 连续完成天数（含今天；今天未完成则从昨天起算，与 stats 一致） */
  function streak(tasks) {
    let n = 0;
    const has = (d) => completedOn(tasks, d).length > 0;
    let cursor = new Date();
    if (!has(dateStr(cursor))) cursor.setDate(cursor.getDate() - 1);
    while (has(dateStr(cursor))) {
      n++;
      cursor.setDate(cursor.getDate() - 1);
    }
    return n;
  }

  /** 完成一项后调用：计算本次 XP（含欠账双倍），返回 { xp, overdue } */
  function onTaskCompleted(state, task) {
    const t = task || {};
    const overdue = isOverdue(t);
    return { xp: taskXp(t, { overdueBoost: true }), overdue };
  }

  /** 欠账补完计数（存 settings.rewards.comebackCount） */
  function bumpComeback(state) {
    const r = Object.assign({}, state.settings.rewards || {});
    r.comebackCount = (r.comebackCount || 0) + 1;
    g.Sugar.store.updateSettings({ rewards: r });
  }

  /** 徽章判定表 */
  function achievementMap(state) {
    const tasks = (state.tasks || []).filter((t) => !t.isDeleted);
    const sessions = (state.focusSessions || []);
    const done = tasks.filter((t) => t.isCompleted);
    const totalDone = done.length;
    const st = streak(tasks);
    const focusTotal = sessions.filter((s) => s.completed).length;
    const nightFocus = sessions.filter((s) => s.completed && s.endAt &&
      new Date(s.endAt).getHours() >= 21).length;
    const onTime = done.filter((t) => !t.dueDate ||
      String(t.dueDate) >= dateStr(new Date(t.completedAt))).length;
    const rate = done.length ? onTime / done.length : 0;
    const rewards = state.settings.rewards || {};
    const family = (state.settings.familyProfiles || []).length > 0;

    // 满分周：过去 52 周内存在某周，该周截止的作业全部完成且按时
    let perfectWeek = false;
    for (let w = 0; w < 52 && !perfectWeek; w++) {
      const now = new Date();
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      start.setDate(start.getDate() - (start.getDay() + 6) % 7 - w * 7);
      const end = new Date(start);
      end.setDate(start.getDate() + 7);
      const weekTasks = tasks.filter((t) => t.dueDate &&
        String(t.dueDate) >= dateStr(start) && String(t.dueDate) < dateStr(end));
      if (!weekTasks.length) continue;
      perfectWeek = weekTasks.every((t) => t.isCompleted && t.completedAt &&
        String(t.dueDate) >= dateStr(new Date(t.completedAt)));
    }

    return {
      'first-step': totalDone >= 1,
      'ten-strong': totalDone >= 10,
      'hundred': totalDone >= 100,
      'three-day': st >= 3,
      'week-streak': st >= 7,
      'month-king': st >= 30,
      'focus-100': focusTotal >= 100,
      'night-owl': nightFocus >= 50,
      'on-time': done.length >= 5 && rate >= 0.9,
      'comeback': (rewards.comebackCount || 0) >= 1,
      'perfect-week': perfectWeek,
      'family-helper': family && totalDone >= 20
    };
  }

  /** 已解锁徽章（settings.achievements 的 id → 解锁时间） */
  function unlocked(state) {
    return state.settings.achievements || {};
  }

  /** 检查并记录新解锁徽章，返回新解锁列表 */
  function recordBadges(state) {
    const cur = unlocked(state);
    const map = achievementMap(state);
    const next = Object.assign({}, cur);
    const fresh = [];
    BADGES.forEach((b) => {
      if (map[b.id] && !cur[b.id]) {
        next[b.id] = new Date().toISOString();
        fresh.push(b);
      }
    });
    if (fresh.length) {
      g.Sugar.store.updateSettings({ achievements: next });
    }
    return fresh;
  }

  g.Sugar.rewards = {
    BADGES,
    isOverdue,
    taskXp,
    daySummary,
    weekSummary,
    bestDayXp,
    streak,
    onTaskCompleted,
    bumpComeback,
    achievementMap,
    unlocked,
    recordBadges,
    todayStr,
    dateStr
  };
})(typeof window !== 'undefined' ? window : globalThis);
