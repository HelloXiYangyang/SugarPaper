/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 统计引擎（纯函数，可单测） */
(function (g) {
  'use strict';

  function pad(n) { return String(n).padStart(2, '0'); }
  function toDateStr(d) { return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()); }
  function parseDate(s) { const p = String(s).split('-').map(Number); return new Date(p[0], p[1] - 1, p[2]); }
  function addDays(d, n) { const x = new Date(d.getFullYear(), d.getMonth(), d.getDate()); x.setDate(x.getDate() + n); return x; }
  function startOfWeek(d) { const x = new Date(d.getFullYear(), d.getMonth(), d.getDate()); const wd = (x.getDay() + 6) % 7; x.setDate(x.getDate() - wd); return x; }

  function overdueDays(due) {
    if (!due) return 0;
    const t = parseDate(toDateStr(new Date()));
    const d = parseDate(due);
    return Math.max(0, Math.round((t - d) / 86400000));
  }

  function completedOn(t, dateStr) {
    if (!t.completedAt) return false;
    const d = new Date(t.completedAt);
    return toDateStr(d) === dateStr;
  }

  function countCompletedOn(tasks, dateStr) {
    return tasks.filter((t) => completedOn(t, dateStr)).length;
  }

  /** 日历标记（v0.24.0）：某日期是否有考试安排便签 + 当日专注分钟 */
  function dayMarkers(notes, sessions, dateStr) {
    const exam = (notes || []).some((n) =>
      !n.isDeleted &&
      n.remindAt &&
      toDateStr(new Date(n.remindAt)) === dateStr &&
      ((n.tags || []).includes('考试安排') || /考试|测验|检测|期末/.test((n.title || '') + ' ' + (n.content || '')))
    );
    const focusMin = (sessions || [])
      .filter((s) => s.completed && toDateStr(new Date(s.endAt)) === dateStr)
      .reduce((sum, s) => sum + (s.minutes || 0), 0);
    return { exam, focusMin };
  }

  /**
   * 计算统计指标
   * @param {{tasks:Array}} state 数据状态
   * @param {string} range today | week | month | all
   */
  function compute(state, range) {
    const tasks = (state.tasks || []).filter((t) => !t.isDeleted);
    const active = tasks.filter((t) => !t.isCompleted);
    const completed = tasks.filter((t) => t.isCompleted);
    const total = tasks.length;
    const rate = total ? Math.round((completed.length / total) * 100) : 0;
    const now = new Date();
    const today = toDateStr(now);
    const weekStart = startOfWeek(now);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    function inRange(t, startDate, endDate) {
      const d = parseDate(toDateStr(new Date(t.createdAt)));
      return d >= startDate && d <= endDate;
    }

    const rangeTasks = tasks.filter((t) => {
      if (range === 'today') return toDateStr(new Date(t.createdAt)) === today;
      if (range === 'week') return inRange(t, weekStart, now);
      if (range === 'month') return inRange(t, monthStart, now);
      return true;
    });
    const rangeCompleted = rangeTasks.filter((t) => t.isCompleted);

    // 每日完成趋势（最近 7 天）
    const dailyTrend = [];
    for (let i = 6; i >= 0; i--) {
      const d = addDays(now, -i);
      const ds = toDateStr(d);
      dailyTrend.push({
        date: ds,
        label: (d.getMonth() + 1) + '/' + d.getDate(),
        count: countCompletedOn(tasks, ds),
        isToday: ds === today
      });
    }

    // 本周每日趋势
    const weekTrend = [];
    for (let i = 0; i < 7; i++) {
      const d = addDays(weekStart, i);
      const ds = toDateStr(d);
      weekTrend.push({
        date: ds,
        label: '周' + ['一', '二', '三', '四', '五', '六', '日'][i],
        count: countCompletedOn(tasks, ds),
        isToday: ds === today
      });
    }

    // 本月每日趋势
    const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    const monthTrend = [];
    for (let i = 1; i <= daysInMonth; i++) {
      const d = new Date(now.getFullYear(), now.getMonth(), i);
      const ds = toDateStr(d);
      monthTrend.push({ date: ds, label: String(i), count: countCompletedOn(tasks, ds), isToday: ds === today });
    }

    // 历史趋势（最近 8 周）
    const weeklyTrend = [];
    for (let i = 7; i >= 0; i--) {
      const ws = addDays(weekStart, -i * 7);
      const we = addDays(ws, 6);
      const count = tasks.filter((t) => {
        if (!t.completedAt) return false;
        const d = new Date(t.completedAt);
        return d >= ws && d <= we;
      }).length;
      weeklyTrend.push({ label: (ws.getMonth() + 1) + '/' + ws.getDate(), count });
    }

    // 连续完成天数（含今天）
    let streak = 0;
    let cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    if (countCompletedOn(tasks, toDateStr(cursor)) === 0) cursor = addDays(cursor, -1);
    while (countCompletedOn(tasks, toDateStr(cursor)) > 0) {
      streak++;
      cursor = addDays(cursor, -1);
    }

    // 科目分布（全部任务）
    const subjectCounts = {};
    tasks.forEach((t) => {
      subjectCounts[t.subject] = (subjectCounts[t.subject] || 0) + 1;
    });
    const subjectDist = Object.keys(subjectCounts)
      .map((name) => ({ name, count: subjectCounts[name] }))
      .sort((a, b) => b.count - a.count);
    const subjectTotal = subjectDist.reduce((s, x) => s + x.count, 0);
    subjectDist.forEach((x) => { x.pct = subjectTotal ? Math.round((x.count / subjectTotal) * 100) : 0; });

    // 科目欠账排行（未完成 + 逾期天数加权，v0.17.0）
    const unCounts = {};
    const unWeights = {};
    active.forEach((t) => {
      unCounts[t.subject] = (unCounts[t.subject] || 0) + 1;
      unWeights[t.subject] = (unWeights[t.subject] || 0) + (1 + overdueDays(t.dueDate) * 2);
    });
    const topUnfinished = Object.keys(unCounts)
      .map((name) => ({
        name,
        count: unCounts[name],
        pri: maxPriorityOf(active, name),
        weight: Math.round(unWeights[name])
      }))
      .sort((a, b) => b.weight - a.weight || b.count - a.count)
      .slice(0, 3);

    // 准时率（v0.17.0）：有截止日期的已完成任务中，完成日 ≤ 截止日的占比
    const dueCompleted = completed.filter((t) => t.dueDate);
    const onTimeCount = dueCompleted.filter((t) => toDateStr(new Date(t.completedAt)) <= t.dueDate).length;
    const onTimeRate = dueCompleted.length ? Math.round((onTimeCount / dueCompleted.length) * 100) : null;

    // 周平均完成率（本周每日完成率均值）
    const weekRate = weekTrend.length
      ? Math.round(weekTrend.reduce((s, d) => s + (d.count ? 100 : 0), 0) / weekTrend.length)
      : 0;

    // 专注统计（v0.15.0）：来自番茄钟 / 倒计时 / 无限专注的已完成会话
    const sessions = (state.focusSessions || []).filter((s) => s.completed);
    const focusToday = sessions.filter((s) => toDateStr(new Date(s.endAt)) === today);
    const focusWeek = sessions.filter((s) => {
      const d = new Date(s.endAt);
      return d >= weekStart && d <= now;
    });
    const focusTodayMinutes = focusToday.reduce((sum, s) => sum + (s.minutes || 0), 0);
    const focusWeekMinutes = focusWeek.reduce((sum, s) => sum + (s.minutes || 0), 0);
    const focusTotalMinutes = sessions.reduce((sum, s) => sum + (s.minutes || 0), 0);

    // 连续专注天数（含今天；今天还没有则从昨天起算）
    let focusStreak = 0;
    let fCursor = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const hasOn = (d) => sessions.some((s) => toDateStr(new Date(s.endAt)) === toDateStr(d));
    if (!hasOn(fCursor)) fCursor = addDays(fCursor, -1);
    while (hasOn(fCursor)) {
      focusStreak++;
      fCursor = addDays(fCursor, -1);
    }

    const focusBySubject = {};
    sessions.forEach((s) => {
      if (s.subject) focusBySubject[s.subject] = (focusBySubject[s.subject] || 0) + (s.minutes || 0);
    });
    const focusSubjectTop = Object.keys(focusBySubject)
      .map((name) => ({ name, minutes: focusBySubject[name] }))
      .sort((a, b) => b.minutes - a.minutes)
      .slice(0, 3);

    const barTrend = range === 'today' ? dailyTrend.slice(-1)
      : range === 'week' ? weekTrend
        : range === 'month' ? monthTrend
          : dailyTrend;

    const lineTrend = weeklyTrend;

    return {
      total,
      completed: completed.length,
      active: active.length,
      rate,
      rangeTotal: rangeTasks.length,
      rangeCompleted: rangeCompleted.length,
      rangeRate: rangeTasks.length ? Math.round((rangeCompleted.length / rangeTasks.length) * 100) : 0,
      todayCompleted: countCompletedOn(tasks, today),
      todayActive: tasks.filter((t) => t.dueDate === today && !t.isCompleted).length,
      weekCompleted: countCompletedOn(tasks, today) + weekTrend.slice(0, -1).reduce((s, d) => s + d.count, 0),
      streak,
      weekRate,
      focusTodayMinutes,
      focusTodayCount: focusToday.length,
      focusWeekMinutes,
      focusWeekCount: focusWeek.length,
      focusTotalMinutes,
      focusTotalCount: sessions.length,
      focusStreak,
      focusSubjectTop,
      dailyTrend,
      weekTrend,
      monthTrend,
      weeklyTrend: lineTrend,
      barTrend,
      subjectDist,
      subjectTotal,
      topUnfinished,
      onTimeRate,
      onTimeCount,
      dueCompletedCount: dueCompleted.length
    };
  }

  function maxPriorityOf(tasks, subject) {
    return tasks.filter((t) => t.subject === subject).reduce((mx, t) => Math.max(mx, t.priority || 0), 0);
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.stats = { compute, dayMarkers };
  if (typeof module !== 'undefined' && module.exports) module.exports = { compute, dayMarkers };
})(typeof window !== 'undefined' ? window : globalThis);
