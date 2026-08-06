/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 日历视图（月 / 周） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const WEEK_CN = ['一', '二', '三', '四', '五', '六', '日'];

  function tasksByDate() {
    const map = {};
    store.state.tasks.forEach((t) => {
      if (t.isDeleted || !t.dueDate) return;
      (map[t.dueDate] = map[t.dueDate] || []).push(t);
    });
    return map;
  }

  function dotsHtml(list) {
    const max = 3;
    const shown = list.slice(0, max);
    const rest = list.length - shown.length;
    let html = '';
    shown.forEach((t) => {
      html += '<i class="' + (t.isCompleted ? 'green' : 'gray') + '"></i>';
    });
    if (rest > 0) html += '<i class="more">+' + rest + '</i>';
    return '<div class="day-dots">' + html + '</div>';
  }

  function monthGridHtml(year, month, selected, today) {
    const first = new Date(year, month, 1);
    const offset = (first.getDay() + 6) % 7; // 周一开头
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const byDate = tasksByDate();
    const cells = [];

    const weekdays = WEEK_CN.map((w) => '<div class="cal-weekday">' + w + '</div>').join('');
    for (let i = 0; i < offset; i++) {
      cells.push('<div class="cal-cell other-month"></div>');
    }
    let idx = 0;
    for (let d = 1; d <= daysInMonth; d++) {
      const ds = year + '-' + util.pad(month + 1) + '-' + util.pad(d);
      const list = byDate[ds] || [];
      const cls = 'cal-cell' +
        (ds === today ? ' today' : '') +
        (ds === selected ? ' selected' : '');
      cells.push(
        '<div class="' + cls + '" data-date="' + ds + '" style="--i:' + idx + '">' +
        '<span class="day-num">' + d + '</span>' +
        (list.length ? dotsHtml(list) : '') +
        '</div>');
      idx++;
    }
    while (cells.length % 7 !== 0) {
      cells.push('<div class="cal-cell other-month"></div>');
    }
    return '<div class="cal-grid">' + weekdays + cells.join('') + '</div>';
  }

  function weekGridHtml(anchor, today) {
    const start = util.startOfWeek(util.parseDate(anchor));
    const byDate = tasksByDate();
    let cols = '';
    for (let i = 0; i < 7; i++) {
      const d = util.addDays(start, i);
      const ds = util.toISODate(d);
      const list = byDate[ds] || [];
      const items = list.length
        ? list.map((t) => {
            const color = store.getSubjectColor(t.subject);
            return '<div class="w-task' + (t.isCompleted ? ' done' : '') + '" data-id="' + t.id + '" style="--subject-color:' + color + '">' +
              (t.isCompleted ? S.icons.icon('check', 11) + ' ' : '') + util.escapeHtml(t.title) + '</div>';
          }).join('')
        : '<div style="font-size:11px;color:var(--text-3)">—</div>';
      cols += '<div class="cal-week-col reveal" data-date="' + ds + '">' +
        '<div class="w-day' + (ds === today ? ' today' : '') + '">' + (ds === anchor ? S.icons.icon('pin', 12) + ' ' : '') + '周' + WEEK_CN[i] + ' ' + (d.getMonth() + 1) + '/' + d.getDate() + '</div>' +
        items + '</div>';
    }
    return '<div class="cal-week-view">' + cols + '</div>';
  }

  function dayListHtml(date, today) {
    const byDate = tasksByDate();
    const list = byDate[date] || [];
    const sorted = list.slice().sort((a, b) => (a.isCompleted - b.isCompleted) || (a.priority - b.priority));
    const done = list.filter((t) => t.isCompleted).length;
    const active = list.length - done;
    const d = util.parseDate(date);

    const items = sorted.length
      ? sorted.map((t) => {
          const color = store.getSubjectColor(t.subject);
          const flag = S.icons.icon('flag', 11);
          const prio = t.priority === 2 ? flag + ' 高' : t.priority === 0 ? flag + ' 低' : flag + ' 中';
          return '<article class="task-card' + (t.isCompleted ? ' completed' : '') + '" data-id="' + t.id + '" style="--subject-color:' + color + '">' +
            '<div class="task-top"><span class="task-subject-badge" style="--subject-color:' + color + '">' + util.escapeHtml(t.subject) + '</span>' +
            '<div class="task-title">' + util.escapeHtml(t.title) + '</div></div>' +
            (t.subtitle ? '<div class="task-subtitle">' + util.escapeHtml(t.subtitle) + '</div>' : '') +
            '<div class="task-actions">' +
            (t.isCompleted
              ? '<button class="action undo" data-action="toggle">' + S.icons.icon('undo', 13) + ' 撤销</button>'
              : '<button class="action done" data-action="toggle">' + S.icons.icon('check', 13) + ' 完成</button>') +
            '<button class="action edit" data-action="edit">' + S.icons.icon('edit', 13) + '</button>' +
            '<button class="action del" data-action="del">' + S.icons.icon('trash', 13) + '</button>' +
            '<span class="grow"></span><span class="tag ' + (t.priority === 2 ? 'pri-high' : t.priority === 0 ? 'pri-low' : 'pri-mid') + '">' + prio + '</span>' +
            '</div></article>';
        }).join('')
      : '<div class="empty"><div class="big">' + S.icons.icon('sun', 40) + '</div>这一天没有截止的作业</div>';

    return '<div class="cal-day-list reveal">' +
      '<div class="cal-day-head"><h3>' + S.icons.icon('list', 15) + ' ' + util.escapeHtml(date === today ? '今天' : util.fmtDate(date)) + ' 的任务</h3>' +
      '<span class="cal-summary"><span class="no">未完成 ' + active + '</span> · <span class="ok">已完成 ' + done + '</span></span>' +
      '<span class="grow" style="flex:1"></span>' +
      '<button class="btn soft-pink small" data-action="add-day">' + S.icons.icon('plus', 13) + ' 添加任务</button></div>' +
      '<div class="task-list">' + items + '</div></div>';
  }

  function render(wrap) {
    const st = g.App.state;
    const selected = st.calSelected || util.todayStr();
    const today = util.todayStr();
    const d = util.parseDate(selected);
    const year = d.getFullYear();
    const month = d.getMonth();

    const toolbar =
      '<div class="cal-toolbar">' +
      '<span class="cal-title">' + S.icons.icon('calendar', 16) + ' ' + year + '年 ' + (month + 1) + '月</span>' +
      '<div class="cal-nav">' +
      '<button class="icon-btn" data-action="prev">' + S.icons.icon('chevron-left', 16) + '</button>' +
      '<button class="btn small" data-action="today">今天</button>' +
      '<button class="icon-btn" data-action="next">' + S.icons.icon('chevron-right', 16) + '</button>' +
      '</div>' +
      '<span style="flex:1"></span>' +
      '<div class="cal-seg">' +
      '<button data-mode="month"' + (st.calMode === 'month' ? ' class="active"' : '') + '>' + S.icons.icon('calendar', 13) + ' 月</button>' +
      '<button data-mode="week"' + (st.calMode === 'week' ? ' class="active"' : '') + '>' + S.icons.icon('list', 13) + ' 周</button>' +
      '</div>' +
      '<button class="btn small" data-action="export">' + S.icons.icon('upload', 13) + ' 导出</button>' +
      '</div>';

    const grid = st.calMode === 'month'
      ? monthGridHtml(year, month, selected, today)
      : weekGridHtml(selected, today);

    const dayList = st.calMode === 'month'
      ? dayListHtml(selected, today)
      : '';

    wrap.innerHTML = toolbar + grid + dayList;
    bind(wrap);
  }

  function shiftMonth(dateStr, delta) {
    const d = util.parseDate(dateStr);
    return util.toISODate(new Date(d.getFullYear(), d.getMonth() + delta, 1));
  }

  function exportMonth(dateStr) {
    const d = util.parseDate(dateStr);
    const byDate = tasksByDate();
    const lines = ['糖纸 · 作业日历 ' + d.getFullYear() + '年' + (d.getMonth() + 1) + '月', ''];
    for (let day = 1; day <= new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); day++) {
      const ds = d.getFullYear() + '-' + util.pad(d.getMonth() + 1) + '-' + util.pad(day);
      const list = byDate[ds] || [];
      if (!list.length) continue;
      lines.push(util.fmtDate(ds) + '（' + list.length + ' 项）');
      list.forEach((t) => {
        lines.push('  ' + (t.isCompleted ? '[✓] ' : '[ ] ') + '[' + t.subject + '] ' + t.title + (t.subtitle ? ' —— ' + t.subtitle.replace(/\n/g, ' ') : ''));
      });
      lines.push('');
    }
    const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = '糖纸-日历-' + d.getFullYear() + '-' + util.pad(d.getMonth() + 1) + '.txt';
    a.click();
    URL.revokeObjectURL(a.href);
  }

  function bind(wrap) {
    wrap.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (btn) {
        const a = btn.dataset.action;
        const st = g.App.state;
        if (a === 'prev') { st.calSelected = shiftMonth(st.calSelected, -1); }
        else if (a === 'next') { st.calSelected = shiftMonth(st.calSelected, 1); }
        else if (a === 'today') { st.calSelected = util.todayStr(); }
        else if (a === 'export') { exportMonth(st.calSelected); return; }
        else if (a === 'add-day') {
          S.ui.modal.openEdit(null, { dueDate: st.calSelected });
          return;
        }
        g.App.renderView();
        return;
      }
      const modeBtn = e.target.closest('[data-mode]');
      if (modeBtn) {
        g.App.state.calMode = modeBtn.dataset.mode;
        g.App.renderView();
        return;
      }
      const cell = e.target.closest('.cal-cell[data-date], .cal-week-col[data-date]');
      if (cell) {
        g.App.state.calSelected = cell.dataset.date;
        g.App.renderView();
        return;
      }
      const wTask = e.target.closest('.w-task[data-id]');
      if (wTask) {
        const t = store.state.tasks.find((x) => x.id === wTask.dataset.id);
        if (t) S.ui.modal.openEdit(t.id);
        return;
      }
      const card = e.target.closest('.task-card[data-id]');
      if (card) {
        const id = card.dataset.id;
        const actionBtn = e.target.closest('[data-action]');
        const action = actionBtn ? actionBtn.dataset.action : null;
        const before = S.ui.home.activeCount();
        if (action === 'toggle') {
          card.classList.add('leaving');
          setTimeout(() => {
            store.toggleComplete(id);
            if (before > 0 && S.ui.home.activeCount() === 0) g.App.celebrate();
          }, 230);
        } else if (action === 'edit') {
          S.ui.modal.openEdit(id);
        } else if (action === 'del') {
          const t = store.state.tasks.find((x) => x.id === id);
          S.ui.modal.confirm({
            title: '删除作业',
            message: '确定删除「' + (t ? t.title : '') + '」吗？',
            confirmText: '删除',
            danger: true,
            onConfirm: () => store.deleteTask(id)
          });
        }
      }
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.calendar = { render };
})(typeof window !== 'undefined' ? window : globalThis);
