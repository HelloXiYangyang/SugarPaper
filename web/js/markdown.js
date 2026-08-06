/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 零依赖轻量 Markdown 渲染器（v0.20.0）
   用于便签正文排版：标题 / 加粗 / 斜体 / 行内代码 / 链接 / 列表（含待办清单）/ 引用 / 代码块 / 分隔线。
   先转义 HTML 再渲染，避免注入。 */
(function (g) {
  'use strict';

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  /** 行内格式：行内代码 → 加粗 → 斜体 → 链接 → 删除线 */
  function inline(text) {
    let s = String(text);
    s = s.replace(/`([^`]+)`/g, '<code>$1</code>');
    s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    s = s.replace(/(^|[^*])\*([^*\n]+)\*(?!\*)/g, '$1<em>$2</em>');
    s = s.replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    s = s.replace(/~~([^~]+)~~/g, '<del>$1</del>');
    return s;
  }

  function render(src) {
    const raw = String(src == null ? '' : src).replace(/\r\n/g, '\n').split('\n');
    const out = [];
    let inCode = false;
    let codeBuf = [];
    let inUl = false;
    let para = [];

    function flushPara() {
      if (para.length) {
        out.push('<p>' + para.map((l) => inline(escapeHtml(l))).join('<br>') + '</p>');
        para = [];
      }
    }
    function closeUl() {
      if (inUl) {
        out.push('</ul>');
        inUl = false;
      }
    }
    function pushLine(html) {
      flushPara();
      closeUl();
      out.push(html);
    }

    raw.forEach((line) => {
      const trimmed = line.trim();
      if (/^```/.test(trimmed)) {
        if (inCode) {
          out.push('<pre><code>' + escapeHtml(codeBuf.join('\n')) + '</code></pre>');
          codeBuf = [];
          inCode = false;
        } else {
          flushPara();
          closeUl();
          inCode = true;
        }
        return;
      }
      if (inCode) {
        codeBuf.push(line);
        return;
      }
      if (!trimmed) {
        flushPara();
        closeUl();
        return;
      }
      const h = trimmed.match(/^(#{1,3})\s+(.*)$/);
      if (h) {
        pushLine('<h' + h[1].length + '>' + inline(escapeHtml(h[2])) + '</h' + h[1].length + '>');
        return;
      }
      if (/^(---|\*\*\*)$/.test(trimmed)) {
        pushLine('<hr>');
        return;
      }
      const quote = trimmed.match(/^>\s?(.*)$/);
      if (quote) {
        pushLine('<blockquote>' + inline(escapeHtml(quote[1])) + '</blockquote>');
        return;
      }
      const check = trimmed.match(/^-\s*\[([ xX])\]\s+(.*)$/);
      if (check) {
        flushPara();
        if (!inUl) {
          out.push('<ul>');
          inUl = true;
        }
        out.push('<li class="md-check' + (check[1] !== ' ' ? ' checked' : '') + '">' +
          '<span class="md-box">' + (check[1] !== ' ' ? '✓' : '') + '</span>' + inline(escapeHtml(check[2])) + '</li>');
        return;
      }
      const ul = trimmed.match(/^[-*]\s+(.*)$/);
      if (ul) {
        flushPara();
        if (!inUl) {
          out.push('<ul>');
          inUl = true;
        }
        out.push('<li>' + inline(escapeHtml(ul[1])) + '</li>');
        return;
      }
      const ol = trimmed.match(/^\d+[.、．]\s+(.*)$/);
      if (ol) {
        flushPara();
        closeUl();
        out.push('<ol><li>' + inline(escapeHtml(ol[1])) + '</li></ol>');
        return;
      }
      para.push(trimmed);
    });

    if (inCode) out.push('<pre><code>' + escapeHtml(codeBuf.join('\n')) + '</code></pre>');
    flushPara();
    closeUl();
    return out.join('');
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.markdown = { render, escapeHtml, inline };
  if (typeof module !== 'undefined' && module.exports) module.exports = { render, escapeHtml, inline };
})(typeof window !== 'undefined' ? window : globalThis);
