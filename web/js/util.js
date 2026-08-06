/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 通用工具 */
(function (g) {
  'use strict';

  const pad = (n) => String(n).padStart(2, '0');

  function toISODate(d) {
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
  }

  function parseDate(s) {
    const parts = String(s).split('-').map(Number);
    return new Date(parts[0], parts[1] - 1, parts[2]);
  }

  function addDays(d, n) {
    const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    x.setDate(x.getDate() + n);
    return x;
  }

  function todayStr() {
    return toISODate(new Date());
  }

  function startOfWeek(d) {
    const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const wd = (x.getDay() + 6) % 7; // 周一为第一天
    x.setDate(x.getDate() - wd);
    return x;
  }

  function uuid() {
    if (g.crypto && typeof g.crypto.randomUUID === 'function') {
      return g.crypto.randomUUID();
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function fmtDate(s) {
    if (!s) return '';
    const d = parseDate(s);
    return d.getMonth() + 1 + '月' + d.getDate() + '日';
  }

  function fmtDateShort(s) {
    if (!s) return '';
    const d = parseDate(s);
    return (d.getMonth() + 1) + '-' + d.getDate();
  }

  function fmtDateTime(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
      ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
  }

  function debounce(fn, ms) {
    let t = null;
    return function () {
      const args = arguments;
      clearTimeout(t);
      t = setTimeout(() => fn.apply(null, args), ms);
    };
  }

  function isSameDay(d1, d2) {
    return toISODate(d1) === toISODate(d2);
  }

  function weekdayCn(d) {
    return ['日', '一', '二', '三', '四', '五', '六'][d.getDay()];
  }

  /**
   * 头像 HTML：null=默认头像图片（assets/avatar-default.jpg）；svg:名称=自绘 SVG 头像；emoji 字符串；data: 开头的自定义图片
   * @param {string|null} avatar
   * @param {string} cls 额外类名（如 avatar-sm / avatar-lg）
   */
  function avatarHtml(avatar, cls) {
    const base = 'avatar' + (cls ? ' ' + cls : '');
    if (avatar && String(avatar).startsWith('data:')) {
      return '<img class="' + base + '" src="' + escapeHtml(avatar) + '" alt="头像">';
    }
    if (avatar && String(avatar).startsWith('svg:')) {
      return '<span class="' + base + '">' + g.Sugar.icons.avatar(avatar.slice(4), 26) + '</span>';
    }
    if (!avatar) {
      // 默认头像：项目内置的喜羊羊图片
      return '<img class="' + base + '" src="assets/avatar-default.jpg" alt="默认头像">';
    }
    return '<span class="' + base + '">' + escapeHtml(avatar) + '</span>';
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.util = {
    toISODate, parseDate, addDays, todayStr, startOfWeek, uuid,
    escapeHtml, fmtDate, fmtDateShort, fmtDateTime, debounce, isSameDay, weekdayCn, pad,
    avatarHtml
  };
})(typeof window !== 'undefined' ? window : globalThis);
