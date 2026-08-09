/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 教师模式：布置作业弹窗（v0.25.0） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  function openTeacherModal() {
    const dlg = S.ui.modal.open({
      title: '教师模式 · 布置作业',
      footer: '',
      wide: true
    });
    const subjects = store.state.subjects.filter((s) => s.enabled).map((s) => s.name);
    dlg.bodyEl.innerHTML =
      '<div class="teacher-hint">' + S.icons.icon('sparkles', 12) + ' 排好作业后复制或下载，发到班级群；学生粘贴进糖纸即可一键解析导入。</div>' +
      '<div class="teacher-row">' +
      '<select id="t-subject">' + subjects.map((n) => '<option value="' + util.escapeHtml(n) + '">' + util.escapeHtml(n) + '</option>').join('') + '</select>' +
      '<input type="text" id="t-title" placeholder="作业内容（例如：试卷一张）">' +
      '<input type="date" id="t-due" title="截止日期（可选）">' +
      '<select id="t-prio"><option value="1">中优先级</option><option value="2">高优先级</option><option value="0">低优先级</option></select>' +
      '<button class="btn primary small" data-action="t-add">' + S.icons.icon('plus', 13) + ' 添加</button>' +
      '</div>' +
      '<div id="t-list" class="teacher-list"></div>' +
      '<div class="field"><button class="btn soft-pink" data-action="t-generate">' + S.icons.icon('bolt', 13) + ' 生成文本</button>' +
      '<textarea id="t-output" readonly placeholder="点击「生成文本」预览班级群格式……" style="margin-top:8px"></textarea></div>';
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="copy">' + S.icons.icon('paperclip', 13) + ' 复制文本</button>' +
      '<button class="btn" data-action="download">' + S.icons.icon('download', 13) + ' 下载 .txt</button>' +
      '<button class="btn primary" data-action="close">完成</button>';

    const items = [];
    const listEl = () => dlg.bodyEl.querySelector('#t-list');
    const outputEl = () => dlg.bodyEl.querySelector('#t-output');

    function renderList() {
      listEl().innerHTML = items.length
        ? items.map((it, i) =>
            '<span class="teacher-chip">' + util.escapeHtml(it.subject) + ' · ' + util.escapeHtml(it.title) +
            (it.dueDate ? ' · ' + util.fmtDate(it.dueDate) + '交' : '') +
            (it.priority === 2 ? ' · 必做' : it.priority === 0 ? ' · 选做' : '') +
            '<button type="button" data-t-del="' + i + '">' + S.icons.icon('close', 11) + '</button></span>').join('')
        : '<div style="font-size:12px;color:var(--text-3)">还没有条目，添加后点「生成文本」。</div>';
    }
    renderList();

    dlg.bodyEl.addEventListener('click', (e) => {
      const addBtn = e.target.closest('[data-action="t-add"]');
      if (addBtn) {
        const title = dlg.bodyEl.querySelector('#t-title').value.trim();
        if (!title) { S.ui.toast('请填写作业内容'); return; }
        items.push({
          subject: dlg.bodyEl.querySelector('#t-subject').value,
          title,
          dueDate: dlg.bodyEl.querySelector('#t-due').value || null,
          priority: +dlg.bodyEl.querySelector('#t-prio').value
        });
        dlg.bodyEl.querySelector('#t-title').value = '';
        dlg.bodyEl.querySelector('#t-due').value = '';
        renderList();
        return;
      }
      const del = e.target.closest('[data-t-del]');
      if (del) {
        items.splice(+del.dataset.tDel, 1);
        renderList();
      }
    });
    dlg.bodyEl.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && e.target && e.target.id === 't-title') {
        e.preventDefault();
        dlg.bodyEl.querySelector('[data-action="t-add"]').click();
      }
    });

    dlg.bodyEl.querySelector('[data-action="t-generate"]').addEventListener('click', () => {
      if (!items.length) { S.ui.toast('请先添加作业条目'); return; }
      outputEl().value = S.teacher.buildHomeworkText(items);
      S.ui.toast('文本已生成，可复制到班级群');
    });
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      const a = btn.dataset.action;
      if (a === 'close') { dlg.close(); return; }
      const text = outputEl().value;
      if (!text) { S.ui.toast('请先生成文本'); return; }
      if (a === 'copy') {
        if (g.navigator && g.navigator.clipboard) {
          g.navigator.clipboard.writeText(text).then(() => S.ui.toast('已复制，粘贴到班级群即可')).catch(() => S.ui.toast('复制失败，请手动选择复制'));
        } else {
          outputEl().select();
          document.execCommand('copy');
          S.ui.toast('已复制');
        }
      } else if (a === 'download') {
        const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = '糖纸-作业布置-' + util.todayStr() + '.txt';
        link.click();
        URL.revokeObjectURL(link.href);
        S.ui.toast('作业文本已下载');
      }
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.teacher = { openTeacherModal };
})(typeof window !== 'undefined' ? window : globalThis);
