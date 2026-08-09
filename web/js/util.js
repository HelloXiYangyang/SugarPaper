/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
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

  function endOfWeek(d) {
    return addDays(startOfWeek(d), 6);
  }

  /**
   * 截止时间分级：overdue(已逾期) / today(今天) / tomorrow(明天) / week(本周内) / long(本周以后或未设置)
   * @param {string|null|undefined} due ISO 日期（YYYY-MM-DD）
   * @returns {string}
   */
  function dueBucket(due) {
    if (!due) return 'long';
    const today = todayStr();
    if (due < today) return 'overdue';
    if (due === today) return 'today';
    if (due === toISODate(addDays(parseDate(today), 1))) return 'tomorrow';
    if (due <= toISODate(endOfWeek(new Date()))) return 'week';
    return 'long';
  }

  /** 'HH:MM' → 当天分钟数；非法返回 null */
  function parseClock(s) {
    const m = String(s == null ? '' : s).match(/^(\d{1,2}):(\d{2})$/);
    if (!m) return null;
    const h = +m[1];
    const min = +m[2];
    if (h > 23 || min > 59) return null;
    return h * 60 + min;
  }

  /** 当前分钟是否落在提醒窗口 [startStr, endMinutes) 内 */
  function inReminderWindow(minutes, startStr, endMinutes) {
    const s = parseClock(startStr);
    if (s == null) return false;
    return minutes >= s && minutes < (endMinutes == null ? s + 120 : endMinutes);
  }

  /** 逾期天数（>=1）；未逾期返回 0 */
  function overdueDays(due) {
    if (!due) return 0;
    const today = parseDate(todayStr());
    const d = parseDate(due);
    return Math.max(0, Math.round((today - d) / 86400000));
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
    toISODate, parseDate, addDays, todayStr, startOfWeek, endOfWeek, dueBucket, overdueDays, parseClock, inReminderWindow, uuid,
    escapeHtml, fmtDate, fmtDateShort, fmtDateTime, debounce, isSameDay, weekdayCn, pad,
    avatarHtml
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { toISODate, parseDate, addDays, todayStr, startOfWeek, endOfWeek, dueBucket, overdueDays, parseClock, inReminderWindow, uuid, escapeHtml, fmtDate, fmtDateShort, fmtDateTime, isSameDay, weekdayCn, pad };
  }
})(typeof window !== 'undefined' ? window : globalThis);
