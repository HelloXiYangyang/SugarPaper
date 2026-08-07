/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 统计报告 SVG 生成器（v0.21.0）
   纯函数：根据统计结果生成 640×880 报告卡片 SVG，供导出 PNG 使用。 */
(function (g) {
  'use strict';

  const C = {
    bg: '#FBF6F2',
    card: '#FFFFFF',
    border: '#F0E2E8',
    text: '#5A4A52',
    sub: '#8A7A82',
    faint: '#B9A9B0',
    pink: '#F4A8C6',
    mint: '#7ED3B2',
    lavender: '#B9A8E8'
  };

  function esc(s) {
    return String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function ringSvg(rate) {
    const r = 54;
    const c = 2 * Math.PI * r;
    const off = c * (1 - Math.min(rate, 100) / 100);
    return '<circle cx="150" cy="192" r="' + r + '" fill="none" stroke="#EFE3E8" stroke-width="12"/>' +
      '<circle cx="150" cy="192" r="' + r + '" fill="none" stroke="' + C.pink + '" stroke-width="12" stroke-linecap="round" ' +
      'stroke-dasharray="' + c.toFixed(1) + '" stroke-dashoffset="' + off.toFixed(1) + '" transform="rotate(-90 150 192)"/>' +
      '<text x="150" y="190" text-anchor="middle" font-size="30" font-weight="bold" fill="' + C.text + '">' + rate + '%</text>' +
      '<text x="150" y="212" text-anchor="middle" font-size="12" fill="' + C.sub + '">完成率</text>';
  }

  function rowHtml(label, value, i) {
    const y = 168 + i * 30;
    return '<text x="272" y="' + y + '" font-size="14" fill="' + C.sub + '">' + esc(label) + '</text>' +
      '<text x="578" y="' + y + '" text-anchor="end" font-size="15" font-weight="bold" fill="' + C.text + '">' + esc(value) + '</text>';
  }

  function cellHtml(label, value, x, y) {
    return '<text x="' + x + '" y="' + (y + 8) + '" text-anchor="middle" font-size="24" font-weight="bold" fill="' + C.pink + '">' + esc(value) + '</text>' +
      '<text x="' + x + '" y="' + (y + 30) + '" text-anchor="middle" font-size="12" fill="' + C.sub + '">' + esc(label) + '</text>';
  }

  function topRowHtml(item, i, getColor) {
    const y = 560 + i * 32;
    const color = getColor ? getColor(item.name) : C.pink;
    return '<circle cx="62" cy="' + (y - 5) + '" r="7" fill="' + color + '"/>' +
      '<text x="82" y="' + y + '" font-size="14" font-weight="bold" fill="' + C.text + '">' + esc(item.name) + '</text>' +
      '<text x="578" y="' + y + '" text-anchor="end" font-size="13" fill="' + C.sub + '">' + item.count + ' 项 · 权重 ' + (item.weight || item.count) + '</text>';
  }

  /**
   * 生成统计报告卡片 SVG
   * @param {object} s stats.compute 结果
   * @param {string} rangeLabel 统计范围（今日/本周/本月/全部）
   * @param {string} dateStr 生成日期
   * @param {Function} [getColor] 科目取色函数
   */
  function buildReportSvg(s, rangeLabel, dateStr, getColor) {
    const summary = [
      ['总任务', String(s.total)],
      ['已完成', s.completed + '（' + s.rate + '%）'],
      ['进行中', String(s.active)],
      ['准时完成率', s.onTimeRate == null ? '—' : s.onTimeRate + '%'],
      ['连续完成天数', s.streak + ' 天']
    ].map((r, i) => rowHtml(r[0], r[1], i)).join('');

    const focus = [
      ['今日专注', String(s.focusTodayMinutes) + ' 分钟'],
      ['本周专注', String(s.focusWeekMinutes) + ' 分钟'],
      ['累计专注', String(s.focusTotalMinutes) + ' 分钟'],
      ['连续专注', String(s.focusStreak) + ' 天']
    ];
    const focusHtml = [
      cellHtml(focus[0][0], focus[0][1], 130, 440),
      cellHtml(focus[1][0], focus[1][1], 290, 440),
      cellHtml(focus[2][0], focus[2][1], 450, 440),
      cellHtml(focus[3][0], focus[3][1], 560, 440)
    ].join('');

    const topHtml = s.topUnfinished && s.topUnfinished.length
      ? s.topUnfinished.map((x, i) => topRowHtml(x, i, getColor)).join('')
      : '<text x="62" y="585" font-size="14" fill="' + C.sub + '">没有未完成的作业</text>';

    return '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="880" viewBox="0 0 640 880" font-family="PingFang SC, Microsoft YaHei, sans-serif">' +
      '<rect width="640" height="880" fill="' + C.bg + '"/>' +
      '<text x="40" y="52" font-size="22" font-weight="bold" fill="' + C.text + '">糖纸 · SugarPaper 统计报告</text>' +
      '<text x="40" y="76" font-size="13" fill="' + C.faint + '">统计范围：' + esc(rangeLabel) + ' · 生成时间：' + esc(dateStr) + '</text>' +

      '<rect x="40" y="108" width="200" height="176" rx="16" fill="' + C.card + '" stroke="' + C.border + '"/>' +
      ringSvg(s.rate) +
      '<rect x="260" y="108" width="340" height="176" rx="16" fill="' + C.card + '" stroke="' + C.border + '"/>' +
      '<text x="272" y="138" font-size="13" font-weight="bold" fill="' + C.sub + '">整体进度</text>' +
      summary +

      '<rect x="40" y="310" width="560" height="150" rx="16" fill="' + C.card + '" stroke="' + C.border + '"/>' +
      '<text x="62" y="340" font-size="14" font-weight="bold" fill="' + C.text + '">专注（番茄钟）</text>' +
      focusHtml +

      '<rect x="40" y="486" width="560" height="170" rx="16" fill="' + C.card + '" stroke="' + C.border + '"/>' +
      '<text x="62" y="516" font-size="14" font-weight="bold" fill="' + C.text + '">科目欠账排行（未完成 + 逾期加权）</text>' +
      topHtml +

      '<text x="40" y="840" font-size="12" fill="' + C.faint + '">让作业管理像糖果一样甜美简单 · 离线优先 · 端到端加密 · 零服务器</text>' +
      '</svg>';
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.report = { buildReportSvg };
  if (typeof module !== 'undefined' && module.exports) module.exports = { buildReportSvg };
})(typeof window !== 'undefined' ? window : globalThis);
