/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 首页：任务列表（核心） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  function activeCount() {
    return store.state.tasks.filter((t) => !t.isDeleted && !t.isCompleted).length;
  }

  function filterTasks() {
    const st = g.App.state;
    let tasks = store.state.tasks.filter((t) => !t.isDeleted);
    if (st.subject !== '全部') tasks = tasks.filter((t) => t.subject === st.subject);
    if (st.priority !== 'all') tasks = tasks.filter((t) => t.priority === Number(st.priority));
    const q = st.query.trim().toLowerCase();
    if (q) tasks = tasks.filter((t) => (t.title + ' ' + (t.subtitle || '')).toLowerCase().includes(q));
    return tasks;
  }

  function sortActive(list) {
    return list.slice().sort((a, b) =>
      (a.order || 0) - (b.order || 0) ||
      (a.createdAt < b.createdAt ? -1 : 1));
  }

  function sortDone(list) {
    return list.slice().sort((a, b) =>
      (a.completedAt || a.updatedAt) < (b.completedAt || b.updatedAt) ? -1 : 1);
  }

  // 截止分级（v0.15.0）：逾期置顶，依次为今天 / 明天 / 本周 / 长期
  const DUE_GROUPS = [
    { key: 'overdue', label: '已逾期', icon: 'flame', cls: 'due-overdue' },
    { key: 'today', label: '今天', icon: 'sun', cls: 'due-today' },
    { key: 'tomorrow', label: '明天', icon: 'clock', cls: 'due-tomorrow' },
    { key: 'week', label: '本周', icon: 'calendar', cls: 'due-week' },
    { key: 'long', label: '长期', icon: 'list', cls: 'due-long' }
  ];

  function sortActiveByDue(list) {
    const order = { overdue: 0, today: 1, tomorrow: 2, week: 3, long: 4 };
    return list.slice().sort((a, b) => {
      const ba = order[util.dueBucket(a.dueDate)];
      const bb = order[util.dueBucket(b.dueDate)];
      if (ba !== bb) return ba - bb;
      if ((b.priority || 0) !== (a.priority || 0)) return (b.priority || 0) - (a.priority || 0);
      return (a.order || 0) - (b.order || 0) || (a.createdAt < b.createdAt ? -1 : 1);
    });
  }

  function dueTagHtml(t) {
    if (!t.dueDate) return '';
    const today = util.todayStr();
    const overdue = !t.isCompleted && t.dueDate < today;
    const days = overdue ? util.overdueDays(t.dueDate) : 0;
    return '<span class="tag due' + (overdue ? ' overdue' : '') + '">' + S.icons.icon('calendar', 12) + ' ' + util.escapeHtml(util.fmtDate(t.dueDate)) +
      (overdue ? ' 已逾期 ' + days + ' 天' : '') + '</span>';
  }

  function prioTagHtml(p) {
    if (p === 2) return '<span class="tag pri-high">' + S.icons.icon('flag', 12) + ' 高</span>';
    if (p === 0) return '<span class="tag pri-low">' + S.icons.icon('flag', 12) + ' 低</span>';
    return '<span class="tag pri-mid">' + S.icons.icon('flag', 12) + ' 中</span>';
  }

  function cardHtml(t) {
    const color = store.getSubjectColor(t.subject);
    const cls = 'task-card reveal' + (t.isCompleted ? ' completed' : '');
    const typeBadge = t.taskType === 'checkin'
      ? '<span class="tag task-checkin">' + S.icons.icon('check', 12) + ' 打卡</span>'
      : t.taskType === 'recite'
        ? '<span class="tag task-recite">' + S.icons.icon('book', 12) + ' 背诵</span>'
        : '';
    const actions = t.isCompleted
      ? '<button class="action undo" data-action="toggle">' + S.icons.icon('undo', 13) + ' 撤销</button>' +
        '<button class="action edit" data-action="edit">' + S.icons.icon('edit', 13) + ' 编辑</button>' +
        '<button class="action del" data-action="del">' + S.icons.icon('trash', 13) + ' 删除</button>' +
        '<span class="grow"></span>' +
        '<span class="tag done-time">' + S.icons.icon('check', 12) + ' ' + util.escapeHtml(util.fmtDateTime(t.completedAt)) + '</span>'
      : (t.taskType === 'checkin'
          ? '<button class="action confirm' + (t.confirmed ? ' confirmed' : '') + '" data-action="confirm">' +
            S.icons.icon('check', 13) + (t.confirmed ? ' 已确认' : ' 确认') + '</button>'
          : '') +
        '<button class="action focus" data-action="focus">' + S.icons.icon('clock', 13) + ' 专注</button>' +
        '<button class="action done" data-action="toggle">' + S.icons.icon('check', 13) + ' 完成</button>' +
        '<button class="action edit" data-action="edit">' + S.icons.icon('edit', 13) + '</button>' +
        '<button class="action del" data-action="del">' + S.icons.icon('trash', 13) + '</button>' +
        '<span class="grow"></span>' +
        '<button class="action move" data-action="move-up" title="上移">' + S.icons.icon('chevron-up', 13) + '</button>' +
        '<button class="action move" data-action="move-down" title="下移">' + S.icons.icon('chevron-down', 13) + '</button>';

    const subjectHtml = t.subject
      ? '<span class="task-subject-badge" style="--subject-color:' + color + '">' + util.escapeHtml(t.subject) + '</span>'
      : '';
    const subtitleHtml = t.subtitle
      ? '<div class="task-subtitle">' + util.escapeHtml(t.subtitle) + '</div>'
      : '';
    const imagesHtml = (t.images || []).length
      ? '<div class="task-images">' + t.images.map((src) =>
          '<img class="task-img" src="' + src + '" alt="作业图片" loading="lazy" data-action="view-task-image" data-src="' + src + '">').join('') + '</div>'
      : '';

    return '<article class="' + cls + '" data-id="' + util.escapeHtml(t.id) + '"' +
      ' style="--subject-color:' + color + '"' +
      (t.isCompleted ? '' : ' draggable="true"') + '>' +
      '<div class="task-top">' + subjectHtml + '<div class="task-title">' + util.escapeHtml(t.title) + '</div></div>' +
      subtitleHtml +
      imagesHtml +
      '<div class="task-meta">' + prioTagHtml(t.priority) + dueTagHtml(t) + typeBadge +
      (t.taskType === 'checkin' && t.confirmed ? '<span class="tag done-time">' + S.icons.icon('check', 12) + ' 家长已确认</span>' : '') +
      '</div>' +
      '<div class="task-actions">' + actions + '</div>' +
      '</article>';
  }

  function chipsHtml() {
    const st = g.App.state;
    const all = store.state.tasks.filter((t) => !t.isDeleted);
    const counts = {};
    all.forEach((t) => { counts[t.subject] = (counts[t.subject] || 0) + 1; });
    const items = [];
    items.push('<button class="chip' + (st.subject === '全部' ? ' active' : '') + '" data-subject="全部">' + S.icons.icon('sparkles', 13) + ' 全部<span class="count">' + all.length + '</span></button>');
    store.state.subjects.filter((s) => s.enabled).forEach((s) => {
      items.push('<button class="chip' + (st.subject === s.name ? ' active' : '') + '" data-subject="' + util.escapeHtml(s.name) + '">' +
        '<span class="dot" style="background:' + s.color + '"></span>' +
        util.escapeHtml(s.name) + '<span class="count">' + (counts[s.name] || 0) + '</span></button>');
    });
    return items.join('');
  }

  // 数据安全网（v0.15.0）：超过 7 天未导出时在首页提示
  function backupBannerHtml() {
    const set = store.state.settings;
    const active = store.state.tasks.filter((t) => !t.isDeleted).length;
    if (!set.backupReminder || !active) return '';
    if (set.backupSnoozedAt === util.todayStr()) return '';
    const last = set.lastExportAt ? new Date(set.lastExportAt).getTime() : 0;
    const days = last ? Math.max(0, Math.floor((Date.now() - last) / 86400000)) : null;
    if (days !== null && days < 7) return '';
    return '<div class="backup-banner reveal">' +
      '<span class="bb-text">' + S.icons.icon('save', 14) + ' ' +
      (days === null ? '你还没有导出过备份，建议导出一份以防数据丢失' : '距上次备份已 ' + days + ' 天，建议导出一份备份') + '</span>' +
      '<button class="btn small soft-pink" data-action="export">立即备份</button>' +
      '<button class="icon-btn" data-action="snooze" title="今天先不了">' + S.icons.icon('close', 13) + '</button>' +
      '</div>';
  }

  function groupHtml(label, iconName, count, listHtml, cls) {
    return '<section class="task-group ' + cls + '">' +
      '<div class="task-group-head"><span class="g-label">' + S.icons.icon(iconName, 15) + ' ' + util.escapeHtml(label) + '</span>' +
      '<span class="g-count">' + count + '</span><span class="g-line"></span></div>' +
      '<div class="task-list">' + listHtml + '</div></section>';
  }

  function render(wrap) {
    const hadFocus = document.activeElement && document.activeElement.id === 'home-search';
    const tasks = filterTasks();
    const active = sortActiveByDue(tasks.filter((t) => !t.isCompleted));
    const done = sortDone(tasks.filter((t) => t.isCompleted));
    const allTasks = store.state.tasks.filter((t) => !t.isDeleted).length;

    let html = '';
    if (allTasks === 0) {
      html =
        '<div class="empty" style="margin-top:40px">' +
        '<div class="big" style="color:var(--pink-strong)">' + S.icons.icon('candy', 46) + '</div>' +
        '<b style="font-size:16px;color:var(--text)">欢迎使用糖纸</b><br>' +
        '粘贴老师发的作业消息，一键解析成清单。<br>' +
        '<button class="btn primary" data-action="import">' + S.icons.icon('file-text', 14) + ' 导入作业</button> ' +
        '<button class="btn" data-action="sample">' + S.icons.icon('sparkles', 14) + ' 载入示例数据</button>' +
        '</div>';
      wrap.innerHTML = html;
      bind(wrap);
      return;
    }

    const chips =
      '<div class="home-filterbar">' +
      '<div class="search-row compact-search">' +
      '<div class="search-box"><span class="s-icon">' + S.icons.icon('search', 14) + '</span><input id="home-search" placeholder="搜索作业..." value="' + util.escapeHtml(g.App.state.query) + '"></div>' +
      '<select class="priority-select" id="home-prio">' +
      '<option value="all"' + (g.App.state.priority === 'all' ? ' selected' : '') + '>全部优先级</option>' +
      '<option value="2"' + (g.App.state.priority === '2' ? ' selected' : '') + '>高</option>' +
      '<option value="1"' + (g.App.state.priority === '1' ? ' selected' : '') + '>中</option>' +
      '<option value="0"' + (g.App.state.priority === '0' ? ' selected' : '') + '>低</option>' +
      '</select></div>' +
      '<div class="chips">' + chipsHtml() + '</div>' +
      '</div>';

    const activeGroups = DUE_GROUPS
      .map((g) => {
        const list = active.filter((t) => util.dueBucket(t.dueDate) === g.key);
        if (!list.length) return '';
        return groupHtml(g.label, g.icon, list.length, list.map(cardHtml).join(''), g.cls);
      })
      .join('');
    const activeHtml = active.length
      ? activeGroups
      : '<div class="empty"><div class="big">' + S.icons.icon('sparkles', 40) + '</div>太棒啦，这里空空如也！</div>';
    const doneHtml = done.length
      ? done.map(cardHtml).join('')
      : '<div class="empty"><div class="big">' + S.icons.icon('sun', 40) + '</div>还没有完成的作业，加油！</div>';

    html = backupBannerHtml() + chips +
      '<div class="task-columns">' +
      activeHtml +
      groupHtml('已完成', 'check', done.length, doneHtml, 'done') +
      '</div>';

    wrap.innerHTML = html;
    bind(wrap);

    if (hadFocus) {
      const inp = wrap.querySelector('#home-search');
      if (inp) {
        inp.focus();
        const len = inp.value.length;
        inp.setSelectionRange(len, len);
      }
    }
  }

  function reorder(dragId, targetId) {
    const actives = sortActive(store.state.tasks.filter((t) => !t.isDeleted && !t.isCompleted));
    const from = actives.findIndex((t) => t.id === dragId);
    const to = actives.findIndex((t) => t.id === targetId);
    if (from < 0 || to < 0 || from === to) return;
    const [item] = actives.splice(from, 1);
    actives.splice(to, 0, item);
    actives.forEach((t, i) => {
      if (t.order !== i + 1) store.updateTask(t.id, { order: i + 1 });
    });
    g.App.renderView();
  }

  function bind(wrap) {
    const search = wrap.querySelector('#home-search');
    if (search) {
      search.addEventListener('input', util.debounce((e) => {
        g.App.state.query = e.target.value;
        g.App.renderView();
      }, 180));
    }
    const prio = wrap.querySelector('#home-prio');
    if (prio) {
      prio.addEventListener('change', (e) => {
        g.App.state.priority = e.target.value;
        g.App.renderView();
      });
    }
    wrap.querySelectorAll('.chip').forEach((c) => {
      c.addEventListener('click', () => {
        g.App.state.subject = c.dataset.subject;
        g.App.renderView();
      });
    });

    wrap.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      const action = btn.dataset.action;
      if (action === 'import') { S.ui.modal.openImport(); return; }
      if (action === 'sample') { g.App.loadSample(); return; }
      if (action === 'export') {
        const blob = new Blob([store.exportJSON()], { type: 'application/json;charset=utf-8' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = '糖纸-备份-' + util.todayStr() + '.json';
        link.click();
        URL.revokeObjectURL(link.href);
        store.updateSettings({ lastExportAt: new Date().toISOString() });
        S.ui.toast('📤 数据已导出');
        g.App.renderView();
        return;
      }
      if (action === 'snooze') {
        store.updateSettings({ backupSnoozedAt: util.todayStr() });
        g.App.renderView();
        return;
      }
      const card = btn.closest('.task-card');
      if (!card) return;
      const id = card.dataset.id;
      if (action === 'toggle') {
        const before = activeCount();
        card.classList.add('leaving');
        setTimeout(() => {
          store.toggleComplete(id);
          if (before > 0 && activeCount() === 0) g.App.celebrate();
        }, 230);
      } else if (action === 'edit') {
        S.ui.modal.openEdit(id);
      } else if (action === 'focus') {
        S.ui.focus.open(id);
      } else if (action === 'confirm') {
        store.toggleConfirm(id);
      } else if (action === 'del') {
        const t = store.state.tasks.find((x) => x.id === id);
        S.ui.modal.confirm({
          title: '删除作业',
          message: '确定删除「' + (t ? t.title : '') + '」吗？删除后可重新导入。',
          confirmText: '删除',
          danger: true,
          onConfirm: () => store.deleteTask(id)
        });
      } else if (action === 'move-up') {
        store.moveTask(id, -1);
      } else if (action === 'move-down') {
        store.moveTask(id, 1);
      }
      const timg = e.target.closest('[data-action="view-task-image"]');
      if (timg) {
        S.ui.modal.open({
          title: '作业图片',
          body: '<img src="' + timg.dataset.src + '" style="width:100%;border-radius:12px;display:block" alt="作业图片">',
          footer: ''
        });
        return;
      }
    });

    // 拖拽排序（桌面/平板）
    let dragId = null;
    wrap.addEventListener('dragstart', (e) => {
      const card = e.target.closest('.task-card[draggable]');
      if (!card) return;
      dragId = card.dataset.id;
      card.classList.add('dragging');
      e.dataTransfer.effectAllowed = 'move';
      try { e.dataTransfer.setData('text/plain', dragId); } catch (err) { /* 忽略 */ }
    });
    wrap.addEventListener('dragend', (e) => {
      const card = e.target.closest('.task-card');
      if (card) card.classList.remove('dragging');
      wrap.querySelectorAll('.task-card.drop-target').forEach((c) => c.classList.remove('drop-target'));
      dragId = null;
    });
    wrap.addEventListener('dragover', (e) => {
      const card = e.target.closest('.task-card[draggable]');
      if (!card || !dragId || card.dataset.id === dragId) return;
      e.preventDefault();
      wrap.querySelectorAll('.task-card.drop-target').forEach((c) => c.classList.remove('drop-target'));
      card.classList.add('drop-target');
    });
    wrap.addEventListener('drop', (e) => {
      e.preventDefault();
      const card = e.target.closest('.task-card[draggable]');
      if (card && dragId) reorder(dragId, card.dataset.id);
      dragId = null;
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.home = { render, filterTasks, activeCount };
})(typeof window !== 'undefined' ? window : globalThis);
