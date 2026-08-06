/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 提醒引擎（v0.15.0）
   浏览器 Notification：作业截止（前一天晚 20 点 / 当天早 7-9 点 / 逾期即时）+ 便签提醒。
   页面打开时与每分钟检查一次；同一条提醒只触发一次。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  function permissionGranted() {
    return 'Notification' in g && g.Notification.permission === 'granted';
  }

  function push(title, body) {
    if (permissionGranted()) {
      try {
        new g.Notification(title, { body: body || '', icon: 'icon.svg' });
      } catch (e) { /* 通知失败不影响使用 */ }
    }
    S.ui.toast('🔔 ' + title + (body ? ' · ' + body : ''));
  }

  function dueMap() {
    return Object.assign({}, store.state.settings.notifiedDue || {});
  }

  function noteMap() {
    return Object.assign({}, store.state.settings.notifiedNotes || {});
  }

  function checkDue() {
    const tasks = store.state.tasks.filter((t) => !t.isDeleted && !t.isCompleted);
    if (!tasks.length) return;
    const today = util.todayStr();
    const now = new Date();
    const minutes = now.getHours() * 60 + now.getMinutes();
    const due = dueMap();
    let changed = false;

    tasks.forEach((t) => {
      if (!t.dueDate) return;
      const days = util.overdueDays(t.dueDate);
      if (days > 0 && !due['o:' + t.id]) {
        push('作业已逾期 ' + days + ' 天', t.title + '（' + util.fmtDate(t.dueDate) + '截止）');
        due['o:' + t.id] = true;
        changed = true;
      } else if (t.dueDate === today && !due['t:' + t.id]) {
        // 当天早上 7:00-9:00 提醒一次
        if (minutes >= 420 && minutes <= 540) {
          push('今天截止：' + t.title, util.fmtDate(t.dueDate) + ' · 记得完成');
          due['t:' + t.id] = true;
          changed = true;
        }
      } else if (t.dueDate === util.toISODate(util.addDays(util.parseDate(today), 1)) && !due['tm:' + t.id]) {
        // 前一晚 20:00 后提醒
        if (minutes >= 1200) {
          push('明天截止：' + t.title, '提前安排，别拖到最后');
          due['tm:' + t.id] = true;
          changed = true;
        }
      }
    });

    if (changed) store.updateSettings({ notifiedDue: due });
  }

  function checkNotes() {
    const notes = store.state.notes.filter((n) => !n.isDeleted && n.remindAt);
    if (!notes.length) return;
    const now = Date.now();
    const map = noteMap();
    let changed = false;
    notes.forEach((n) => {
      if (!map[n.id] && now >= new Date(n.remindAt).getTime()) {
        push('便签提醒', n.title || (n.content || '').slice(0, 30));
        map[n.id] = true;
        changed = true;
      }
    });
    if (changed) store.updateSettings({ notifiedNotes: map });
  }

  function checkAll() {
    if (!store.state.settings.notifications) return;
    checkDue();
    checkNotes();
  }

  function init() {
    if (!('Notification' in g)) return;
    // 页面打开时检查一次，之后每分钟检查（浏览器打开期间有效）
    checkAll();
    setInterval(checkAll, 60000);
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.reminders = { init, checkAll, checkDue, checkNotes, push };
})(typeof window !== 'undefined' ? window : globalThis);
