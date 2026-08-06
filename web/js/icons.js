/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 自绘 SVG 矢量图标库
   统一 24×24 视口；描边图标 stroke=currentColor，头像为填充图标。 */
(function (g) {
  'use strict';

  // 描边风格 UI 图标（fill:none / stroke:currentColor）
  const STROKE = {
    home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M9 21v-6h6v6"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M8 3v4M16 3v4M3 10h18"/>',
    'chart-bar': '<path d="M4 20v-9M10 20V5M16 20v-12"/><path d="M3 20h18"/>',
    'chart-line': '<path d="M3 20h18"/><path d="m4 16 5-6 4 3 6-8"/>',
    'chart-pie': '<path d="M12 3a9 9 0 1 0 9 9h-9z"/><path d="M15 3.5A9 9 0 0 1 20.5 9H15z"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-6 8-6s8 2 8 6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="m13 7 4 4"/>',
    trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
    check: '<path d="m5 12 5 5 9-10"/>',
    undo: '<path d="M9 14 4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
    'chevron-up': '<path d="m6 14 6-6 6 6"/>',
    'chevron-down': '<path d="m6 10 6 6 6-6"/>',
    'chevron-left': '<path d="m14 6-6 6 6 6"/>',
    'chevron-right': '<path d="m10 6 6 6-6 6"/>',
    pause: '<path d="M8 5v14M16 5v14"/>',
    music: '<path d="M9 18V5l10-2v13"/><circle cx="7" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
    mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
    flag: '<path d="M5 21V4"/><path d="M5 4h11l-2 4 2 4H5"/>',
    download: '<path d="M12 3v12M7 10l5 5 5-5M4 21h16"/>',
    upload: '<path d="M12 15V3M7 8l5-5 5 5M4 21h16"/>',
    moon: '<path d="M20 14A8 8 0 1 1 10 4a7 7 0 0 0 10 10z"/>',
    bell: '<path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10 20a2 2 0 0 0 4 0"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.6 4 5.7 4 9s-1.5 6.4-4 9c-2.5-2.6-4-5.7-4-9s1.5-6.4 4-9"/>',
    sparkles: '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/><path d="M18.5 14l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>',
    book: '<path d="M4 5a2 2 0 0 1 2-2h14v18H6a2 2 0 0 0-2 2z"/><path d="M4 19a2 2 0 0 1 2-2h14"/>',
    camera: '<path d="M4 8h3l2-3h6l2 3h3v12H4z"/><circle cx="12" cy="13" r="4"/>',
    image: '<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/><path d="m4 19 5-5 3 3 4-4 4 4"/>',
    close: '<path d="M6 6l12 12M18 6 6 18"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>',
    gauge: '<path d="M5 19a9 9 0 1 1 14 0"/><path d="M12 13l4-4"/><circle cx="12" cy="13" r="1.6"/>',
    bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',
    save: '<path d="M5 3h11l5 5v13H5z"/><path d="M8 3v6h8V3M8 21v-8h8v8"/>',
    'file-text': '<path d="M6 3h9l5 5v13H6z"/><path d="M14 3v6h6M9 12h6M9 16h6"/>',
    paperclip: '<path d="M9 4v11a4 4 0 0 0 8 0V6"/><path d="M17 6v9a6 6 0 0 1-12 0V5"/>',
    list: '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M9 8h6M9 12h6M9 16h4"/>',
    pin: '<path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    flame: '<path d="M12 2c.8 2.5-.8 3.7-.8 5.5a2.8 2.8 0 0 0 5.6 0C19 9.5 21 12.5 21 16a9 9 0 1 1-18 0c0-4 2.5-7.5 5-9-.3 1.6.5 2.6 1.6 3.2C9.2 6 10 3.5 12 2z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.6 2.2c-.7.4-1.1.9-1.1 1.8"/><path d="M12 17h.01"/>',
    target: '<circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r="1" fill="currentColor" stroke="none"/>',
    candy: '<circle cx="12" cy="10" r="5.5"/><path d="M12 15.5V21M9.5 18.5h5"/><path d="M12 4.5a5.5 5.5 0 0 1 5.5 5.5"/>'
  };

  // 填充风格头像（fill:currentColor）
  const FILL = {
    person: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.2 3.6-7 8-7s8 2.8 8 7z"/>',
    star: '<path d="M12 2l2.9 6.1 6.6.8-4.9 4.5 1.3 6.5L12 16.9 6.1 20l1.3-6.5L2.5 8.9l6.6-.8z"/>',
    heart: '<path d="M12 20.5S3.5 15.8 2 11C1 7.8 3.5 4.5 6.8 4.5c2.2 0 3.8 1.4 5.2 3.2 1.4-1.8 3-3.2 5.2-3.2C20.5 4.5 23 7.8 22 11c-1.5 4.8-10 9.5-10 9.5z"/>',
    cat: '<path d="M8.5 8 5 3.5l3.8 2M15.5 8 19 3.5l-3.8 2"/><path d="M5 13a7 7 0 0 1 14 0v4a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3z"/>',
    fox: '<path d="M6 3l4 5.5 2-2 2 2L18 3l-1.2 6A7 7 0 1 1 7.2 9z"/>',
    bear: '<circle cx="8" cy="8" r="2.2"/><circle cx="16" cy="8" r="2.2"/><path d="M4 13a8 8 0 0 1 16 0v4a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z"/>',
    candy: '<circle cx="12" cy="10" r="6"/><path d="M12 16v5.5M9.3 18.5h5.4"/>',
    sparkle: '<path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/>'
  };

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
  }

  /**
   * 描边图标
   * @param {string} name 图标名
   * @param {number} size 宽高（px）
   * @param {string} cls 额外类名
   */
  function icon(name, size, cls) {
    const d = STROKE[name];
    if (!d) return '';
    size = size || 18;
    return '<svg class="ico ico-' + esc(name) + (cls ? ' ' + cls : '') + '" viewBox="0 0 24 24" width="' + size + '" height="' + size + '" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' + d + '</svg>';
  }

  /**
   * 填充风格头像
   * @param {string} name 头像名（person/cat/fox/bear/star/heart/candy/sparkle）
   * @param {number} size
   */
  function avatar(name, size) {
    const d = FILL[name] || FILL.person;
    size = size || 26;
    return '<svg class="ico-avatar" viewBox="0 0 24 24" width="' + size + '" height="' + size + '" aria-hidden="true" fill="currentColor">' + d + '</svg>';
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.icons = { icon, avatar, STROKE, FILL };
})(typeof window !== 'undefined' ? window : globalThis);
