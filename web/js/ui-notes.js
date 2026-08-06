/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 便签页（v0.15.0）
   轻量速记：置顶 / 归档 / 颜色 / 标签 / 提醒 / 一键转为作业 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const NOTE_COLORS = [
    '#F4B8CE', '#FBE6B9', '#BFE8C9', '#B3D4F0',
    '#C9C7F0', '#E8D5F0', '#FAD1B8', '#F0C9C9'
  ];
  const NOTE_TAGS = ['考试安排', '老师通知', '物品清单', '回执'];

  function visibleNotes() {
    const st = g.App.state;
    const q = (st.query || '').trim().toLowerCase();
    return store.state.notes.filter((n) => {
      if (n.isDeleted) return false;
      if (st.noteTag && st.noteTag !== '全部' && !n.tags.includes(st.noteTag)) return false;
      if (q) {
        const hay = (n.title + ' ' + n.content + ' ' + (n.tags || []).join(' ')).toLowerCase();
        if (!hay.includes(q)) return false;
      }
      return true;
    });
  }

  function tagChips() {
    const st = g.App.state;
    const counts = {};
    store.state.notes.filter((n) => !n.isDeleted && !n.archived).forEach((n) => {
      (n.tags || []).forEach((t) => { counts[t] = (counts[t] || 0) + 1; });
    });
    const items = ['全部'];
    NOTE_TAGS.forEach((t) => { if (counts[t]) items.push(t); });
    Object.keys(counts).forEach((t) => { if (!items.includes(t)) items.push(t); });
    return items.map((t) =>
      '<button class="chip' + (st.noteTag === t ? ' active' : '') + '" data-note-tag="' + util.escapeHtml(t) + '">' +
      util.escapeHtml(t) + (t !== '全部' ? '<span class="count">' + counts[t] + '</span>' : '') + '</button>').join('');
  }

  function noteCardHtml(n, i) {
    const color = n.color || '#F4B8CE';
    const tags = (n.tags || []).map((t) =>
      '<span class="note-tag" style="background:color-mix(in srgb,' + color + ' 22%, transparent);color:var(--text-2)">' +
      util.escapeHtml(t) + '</span>').join('');
    const remind = n.remindAt
      ? '<span class="note-remind">' + S.icons.icon('bell', 12) + ' ' + util.escapeHtml(util.fmtDateTime(n.remindAt)) + '</span>'
      : '';
    const images = (n.images || []).length
      ? '<div class="note-images">' + n.images.map((src) =>
          '<img class="note-img" src="' + src + '" alt="附件" loading="lazy" data-action="view-image" data-src="' + src + '">').join('') + '</div>'
      : '';
    const pinCls = n.pinned ? ' pinned' : '';
    return '<article class="note-card reveal' + pinCls + '" data-id="' + util.escapeHtml(n.id) + '" style="--i:' + (i % 8) + '">' +
      '<i class="note-color-bar" style="background:' + color + '"></i>' +
      '<div class="note-body">' +
      '<div class="note-top">' +
      (n.pinned ? '<span class="note-pin">' + S.icons.icon('pin', 13) + '</span>' : '') +
      '<b class="note-title">' + util.escapeHtml(n.title || '（无标题）') + '</b>' +
      '</div>' +
      (n.content ? '<div class="note-content">' + util.escapeHtml(n.content) + '</div>' : '') +
      images +
      '<div class="note-meta">' + tags + remind + '</div>' +
      '<div class="note-actions">' +
      '<button class="action" data-action="toggle-pin">' + S.icons.icon('pin', 13) + ' ' + (n.pinned ? '取消置顶' : '置顶') + '</button>' +
      '<button class="action" data-action="toggle-archive">' + S.icons.icon('save', 13) + ' ' + (n.archived ? '取消归档' : '归档') + '</button>' +
      '<button class="action" data-action="to-task">' + S.icons.icon('list', 13) + ' 转作业</button>' +
      '<button class="action" data-action="edit">' + S.icons.icon('edit', 13) + '</button>' +
      '<button class="action del" data-action="del">' + S.icons.icon('trash', 13) + '</button>' +
      '</div></div></article>';
  }

  function render(wrap) {
    const all = visibleNotes();
    const pinned = all.filter((n) => !n.archived && n.pinned).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
    const normal = all.filter((n) => !n.archived && !n.pinned).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
    const archived = all.filter((n) => n.archived).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
    const showArchived = !!g.App.state.showArchivedNotes;

    const section = (title, list) =>
      list.length
        ? '<section class="note-group"><div class="task-group-head"><span class="g-label">' + util.escapeHtml(title) + '</span>' +
          '<span class="g-count">' + list.length + '</span><span class="g-line"></span></div>' +
          '<div class="note-list">' + list.map(noteCardHtml).join('') + '</div></section>'
        : '';

    let html =
      '<div class="notes-toolbar">' +
      '<span class="cal-title">' + S.icons.icon('file-text', 16) + ' 便签</span>' +
      '<button class="btn primary small" data-action="new-note">' + S.icons.icon('plus', 13) + ' 新建便签</button>' +
      '</div>' +
      '<div class="home-filterbar"><div class="chips">' + tagChips() + '</div></div>';

    if (!all.length) {
      html += '<div class="empty" style="margin-top:24px"><div class="big">' + S.icons.icon('file-text', 40) + '</div>' +
        '随手记下考试安排、老师通知、明天带什么……<br>' +
        '<button class="btn primary" data-action="new-note">' + S.icons.icon('plus', 14) + ' 新建便签</button></div>';
    } else {
      html += section('📌 置顶', pinned) +
        section('便签', normal) +
        (archived.length
          ? '<div class="note-archived-row"><button class="btn small" data-action="toggle-archived">' +
            S.icons.icon('save', 13) + ' 已归档 ' + archived.length + ' 条' + (showArchived ? '（收起）' : '') + '</button></div>' +
            (showArchived ? section('🗂 归档', archived) : '')
          : '');
    }

    wrap.innerHTML = html;
    bind(wrap);
  }

  function bind(wrap) {
    wrap.addEventListener('click', (e) => {
      const tag = e.target.closest('[data-note-tag]');
      if (tag) {
        g.App.state.noteTag = tag.dataset.noteTag;
        g.App.renderView();
        return;
      }
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      const a = btn.dataset.action;
      if (a === 'new-note') { S.ui.modal.openNoteEditor(); return; }
      if (a === 'toggle-archived') {
        g.App.state.showArchivedNotes = !g.App.state.showArchivedNotes;
        g.App.renderView();
        return;
      }
      const card = btn.closest('.note-card');
      if (!card) return;
      const id = card.dataset.id;
      if (a === 'toggle-pin') store.toggleNotePin(id);
      else if (a === 'toggle-archive') store.toggleNoteArchive(id);
      else if (a === 'edit') S.ui.modal.openNoteEditor(id);
      else if (a === 'to-task') S.ui.modal.noteToTask(id);
      else if (a === 'del') {
        const n = store.state.notes.find((x) => x.id === id);
        S.ui.modal.confirm({
          title: '删除便签',
          message: '确定删除「' + (n && n.title ? n.title : '这条便签') + '」吗？',
          confirmText: '删除',
          danger: true,
          onConfirm: () => store.deleteNote(id)
        });
      }
      const img = e.target.closest('[data-action="view-image"]');
      if (img) {
        S.ui.modal.open({
          title: '图片附件',
          body: '<img src="' + img.dataset.src + '" style="width:100%;border-radius:12px;display:block" alt="附件">',
          footer: ''
        });
        return;
      }
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.notes = { render, NOTE_COLORS, NOTE_TAGS };
})(typeof window !== 'undefined' ? window : globalThis);
