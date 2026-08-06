/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 教师模式：作业文本生成器（v0.25.0）
   把条目按「科目行 + 编号条目」标准格式排版，学生粘贴进糖纸即可一键解析导入。 */
(function (g) {
  'use strict';

  function fmtDate(s) {
    if (!s) return '';
    const parts = String(s).split('-').map(Number);
    return parts[1] + '月' + parts[2] + '日';
  }

  /**
   * 生成作业文本
   * @param {Array<{subject:string,title:string,dueDate?:string,priority?:number}>} items
   * @returns {string}
   */
  function buildHomeworkText(items) {
    const groups = [];
    const index = new Map();
    (items || []).forEach((it) => {
      const subject = it.subject || '默认';
      if (!index.has(subject)) {
        index.set(subject, groups.length);
        groups.push({ subject, list: [] });
      }
      groups[index.get(subject)].list.push(it);
    });
    const lines = [];
    groups.forEach((grp) => {
      lines.push(grp.subject);
      grp.list.forEach((it, i) => {
        let title = String(it.title || '').trim();
        if (!title) return;
        const tags = [];
        if (it.dueDate) tags.push(fmtDate(it.dueDate) + '交');
        if (it.priority === 2) tags.push('必做');
        if (it.priority === 0) tags.push('选做');
        if (tags.length) title += '（' + tags.join('、') + '）';
        lines.push((i + 1) + '.' + title);
      });
    });
    return lines.join('\n');
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.teacher = { buildHomeworkText };
  if (typeof module !== 'undefined' && module.exports) module.exports = { buildHomeworkText };
})(typeof window !== 'undefined' ? window : globalThis);
