/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 统计视图（SVG 图表） */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;
  const stats = S.stats;

  const RANGE_LABEL = { today: '今日', week: '本周', month: '本月', all: '全部' };

  function ringHtml(rate, gid) {
    const r = 52;
    const c = 2 * Math.PI * r;
    const offset = c * (1 - Math.min(rate, 100) / 100);
    return '<div class="progress-ring"><svg viewBox="0 0 128 128">' +
      '<defs><linearGradient id="' + gid + '" x1="0" y1="0" x2="1" y2="1">' +
      '<stop offset="0" stop-color="var(--pink-strong)"/>' +
      '<stop offset="1" stop-color="var(--mint-strong)"/>' +
      '</linearGradient></defs>' +
      '<circle class="ring-bg" cx="64" cy="64" r="' + r + '"/>' +
      '<circle class="ring-fg" cx="64" cy="64" r="' + r + '" stroke-dasharray="' + c.toFixed(1) + '" stroke-dashoffset="' + offset.toFixed(1) + '" style="stroke:url(#' + gid + ')"/>' +
      '</svg>' +
      '<div class="ring-text"><b>' + rate + '%</b><span>完成率</span></div></div>';
  }

  function barsHtml(trend) {
    const W = 700, H = 200, L = 28, R = 10, T = 26, B = 30;
    const max = Math.max(1, ...trend.map((d) => d.count));
    const n = trend.length;
    const step = (W - L - R) / n;
    const bw = step * 0.62;
    const bars = trend.map((d, i) => {
      const h = Math.max(2, (d.count / max) * (H - T - B));
      const x = L + i * step + (step - bw) / 2;
      const y = H - B - h;
      const fill = d.isToday ? 'var(--mint-strong)' : 'var(--pink)';
      const labelY = y - 6;
      return '<rect x="' + x.toFixed(1) + '" y="' + y.toFixed(1) + '" width="' + bw.toFixed(1) + '" height="' + h.toFixed(1) + '" rx="5" fill="' + fill + '">' +
        '<title>' + d.label + '：完成 ' + d.count + ' 项</title></rect>' +
        (d.count ? '<text x="' + (x + bw / 2).toFixed(1) + '" y="' + labelY + '" text-anchor="middle" font-size="11" font-weight="700" fill="var(--text-2)">' + d.count + '</text>' : '') +
        '<text x="' + (x + bw / 2).toFixed(1) + '" y="' + (H - 8) + '" text-anchor="middle" font-size="11" fill="var(--text-3)">' + d.label + '</text>';
    }).join('');
    return '<div class="chart-box"><svg viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="xMidYMid meet">' +
      '<line x1="' + L + '" y1="' + (H - B) + '" x2="' + (W - R) + '" y2="' + (H - B) + '" stroke="var(--border)" stroke-width="1"/>' +
      bars + '</svg></div>';
  }

  function pieHtml(dist) {
    const total = dist.reduce((s, x) => s + x.count, 0);
    if (!total) return '<div class="empty"><div class="big">' + S.icons.icon('chart-pie', 40) + '</div>暂无数据</div>';
    const cx = 110, cy = 110, r = 92;
    let angle = -Math.PI / 2;
    const slices = dist.map((x, i) => {
      const frac = x.count / total;
      const a2 = angle + frac * Math.PI * 2;
      const x1 = cx + r * Math.cos(angle);
      const y1 = cy + r * Math.sin(angle);
      const x2 = cx + r * Math.cos(a2);
      const y2 = cy + r * Math.sin(a2);
      const large = frac > 0.5 ? 1 : 0;
      const d = 'M' + cx + ' ' + cy + ' L' + x1.toFixed(1) + ' ' + y1.toFixed(1) +
        ' A' + r + ' ' + r + ' 0 ' + large + ' 1 ' + x2.toFixed(1) + ' ' + y2.toFixed(1) + ' Z';
      angle = a2;
      const color = store.getSubjectColor(x.name);
      return '<path style="--si:' + i + '" d="' + d + '" fill="' + color + '"><title>' + util.escapeHtml(x.name) + '：' + x.count + ' 项（' + x.pct + '%）</title></path>';
    }).join('');
    const legend = dist.map((x, i) =>
      '<span class="legend-item" style="--i:' + i + '"><span class="sw" style="background:' + store.getSubjectColor(x.name) + '"></span>' +
      util.escapeHtml(x.name) + ' ' + x.pct + '%</span>').join('');
    return '<div class="chart-box"><div class="pie-wrap"><div class="pie-canvas">' +
      '<svg viewBox="0 0 220 220" preserveAspectRatio="xMidYMid meet">' + slices + '</svg>' +
      '</div><div class="legend">' + legend + '</div></div></div>';
  }

  function lineHtml(trend) {
    const W = 700, H = 200, L = 30, R = 16, T = 20, B = 30;
    const max = Math.max(2, ...trend.map((d) => d.count));
    const n = trend.length;
    const step = (W - L - R) / Math.max(1, n - 1);
    const pts = trend.map((d, i) => {
      const x = L + i * step;
      const y = H - B - (d.count / max) * (H - T - B);
      return [x, y];
    });
    const poly = pts.map((p) => p[0].toFixed(1) + ',' + p[1].toFixed(1)).join(' ');
    const area = L + ',' + (H - B) + ' ' + poly + ' ' + (W - R) + ',' + (H - B);
    const dots = pts.map((p, i) =>
      '<circle cx="' + p[0].toFixed(1) + '" cy="' + p[1].toFixed(1) + '" r="3.5" fill="var(--lavender-strong)"><title>' +
      trend[i].label + '：' + trend[i].count + ' 项</title></circle>').join('');
    const labels = trend.map((d, i) => {
      const x = L + i * step;
      const show = n > 12 ? i % 2 === 0 : true;
      return show ? '<text x="' + x.toFixed(1) + '" y="' + (H - 8) + '" text-anchor="middle" font-size="10" fill="var(--text-3)">' + d.label + '</text>' : '';
    }).join('');
    return '<div class="chart-box"><svg viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="xMidYMid meet">' +
      '<polygon points="' + area + '" fill="var(--lavender-soft)"/>' +
      '<polyline points="' + poly + '" fill="none" stroke="var(--lavender-strong)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>' +
      dots + labels + '</svg></div>';
  }

  function render(wrap) {
    const range = g.App.state.statsRange;
    const st = store.state;
    const s = stats.compute(st, range);
    // v0.32.0：激励（XP / 连胜）派生数据
    const rw = S.rewards;
    const rwToday = rw ? rw.daySummary(st.tasks) : { xp: 0, count: 0 };
    const rwWeek = rw ? rw.weekSummary(st.tasks) : { xp: 0, count: 0 };
    const rwBest = rw ? rw.bestDayXp(st.tasks) : 0;
    const rwStreak = rw ? rw.streak(st.tasks) : 0;
    const rwGoals = Object.assign({ dailyXp: 50, dailyTasks: 3 }, st.settings.rewardsGoals || {});
    const today = util.todayStr();

    const rangeNote = range === 'today' ? '今天共 ' + s.rangeTotal + ' 项作业，完成 ' + s.rangeCompleted + ' 项'
      : range === 'week' ? '本周新增 ' + s.rangeTotal + ' 项，完成 ' + s.rangeCompleted + ' 项'
        : range === 'month' ? '本月新增 ' + s.rangeTotal + ' 项，完成 ' + s.rangeCompleted + ' 项'
          : '共 ' + s.rangeTotal + ' 项作业，完成 ' + s.rangeCompleted + ' 项';

    const top3 = s.topUnfinished.length
      ? s.topUnfinished.map((x) => {
          const prio = x.pri === 2 ? '<span class="tag pri-high">高优先级</span>' : x.pri === 0 ? '<span class="tag pri-low">低优先级</span>' : '<span class="tag pri-mid">中优先级</span>';
          return '<div class="top3-item"><span class="dot" style="background:' + store.getSubjectColor(x.name) + '"></span>' +
            util.escapeHtml(x.name) + prio + '<span class="cnt">' + x.count + ' 项</span></div>';
        }).join('')
      : '<div class="empty"><div class="big">' + S.icons.icon('sparkles', 40) + '</div>没有未完成的作业</div>';

    let summary =
      '<div class="summary-item" style="--i:0"><span>' + S.icons.icon('book', 13) + ' 总任务数</span><b>' + s.total + '</b></div>' +
      '<div class="summary-item" style="--i:1"><span>' + S.icons.icon('check', 13) + ' 已完成</span><b class="ok">' + s.completed + '（' + s.rate + '%）</b></div>' +
      '<div class="summary-item" style="--i:2"><span>' + S.icons.icon('pin', 13) + ' 进行中</span><b class="no">' + s.active + '</b></div>' +
      '<div class="summary-item" style="--i:3"><span>' + S.icons.icon('flame', 13) + ' 连续完成天数</span><b>' + s.streak + ' 天</b></div>' +
      '<div class="summary-item" style="--i:4"><span>' + S.icons.icon('chart-line', 13) + ' 本周平均完成率</span><b>' + s.weekRate + '%</b></div>';
    if (s.onTimeRate != null) {
      summary += '<div class="summary-item" style="--i:5"><span>' + S.icons.icon('check', 13) + ' 准时完成率</span><b class="ok">' + s.onTimeRate + '%</b></div>';
    }

    const toolbar =
      '<div class="stats-toolbar">' +
      '<span class="cal-title">' + S.icons.icon('chart-bar', 16) + ' 统计</span>' +
      '<div class="cal-seg">' +
      ['today', 'week', 'month', 'all'].map((r) =>
        '<button data-range="' + r + '"' + (r === range ? ' class="active"' : '') + '>' + RANGE_LABEL[r] + '</button>').join('') +
      '</div>' +
      '<span style="flex:1"></span>' +
      '<button class="btn small" data-action="export">' + S.icons.icon('upload', 13) + ' 导出统计报告</button>' +
      '<button class="btn small soft-pink" data-action="export-image">' + S.icons.icon('image', 13) + ' 导出图片</button>' +
      '</div>';

    wrap.innerHTML = toolbar +
      '<div class="stats-grid">' +
      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('chart-line', 15) + '</span>整体进度</h3>' +
      '<div class="progress-ring-wrap">' + ringHtml(s.rate, 'ringGradMain') + '<div class="summary-list">' + summary + '</div></div>' +
      '<div style="font-size:12px;color:var(--text-3);margin-top:10px">' + S.icons.icon('save', 12) + ' ' + rangeNote + '</div></div>' +

      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('bolt', 15) + '</span>激励（XP）</h3>' +
      '<div class="focus-summary">' +
      '<div class="focus-num"><b>' + rwToday.xp + '</b><span>今日 XP</span></div>' +
      '<div class="focus-num"><b>' + rwWeek.xp + '</b><span>本周 XP</span></div>' +
      '<div class="focus-num"><b>' + rwBest + '</b><span>最佳单日</span></div>' +
      '</div>' +
      '<div style="font-size:12px;color:var(--text-3);margin-top:10px">每日目标 ' + rwGoals.dailyXp + ' XP · 完成 ' + rwToday.count + '/' + rwGoals.dailyTasks + ' 项 · 连续 ' + rwStreak + ' 天</div>' +
      '</div>' +

      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('clock', 15) + '</span>专注（番茄钟）</h3>' +
      '<div class="focus-summary">' +
      '<div class="focus-num"><b>' + s.focusTodayMinutes + '</b><span>今日分钟</span></div>' +
      '<div class="focus-num"><b>' + s.focusTodayCount + '</b><span>今日番茄</span></div>' +
      '<div class="focus-num"><b>' + s.focusStreak + '</b><span>连续天数</span></div>' +
      '</div>' +
      '<div style="font-size:12px;color:var(--text-3);margin-top:10px">本周专注 ' + s.focusWeekMinutes + ' 分钟 · ' + s.focusWeekCount + ' 个番茄；累计 ' + s.focusTotalMinutes + ' 分钟</div>' +
      (s.focusSubjectTop.length
        ? '<div class="top3-list" style="margin-top:10px">' + s.focusSubjectTop.map((x) =>
            '<div class="top3-item"><span class="dot" style="background:' + store.getSubjectColor(x.name) + '"></span>' +
            util.escapeHtml(x.name) + '<span class="cnt">' + x.minutes + ' 分钟</span></div>').join('') + '</div>'
        : '<div style="font-size:12px;color:var(--text-3);margin-top:10px">还没有专注记录，从任务卡「专注」开始你的第一个番茄吧</div>') +
      '</div>' +

      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('chart-pie', 15) + '</span>科目分布（饼图）</h3>' + pieHtml(s.subjectDist) + '</div>' +

      '<div class="stats-card span-2 reveal"><h3><span class="e">' + S.icons.icon('chart-bar', 15) + '</span>每日完成趋势（柱状图）</h3>' + barsHtml(s.barTrend) + '</div>' +

      '<div class="stats-card span-2 reveal"><h3><span class="e">' + S.icons.icon('chart-line', 15) + '</span>历史完成趋势（折线图 · 最近 8 周）</h3>' + lineHtml(s.weeklyTrend) + '</div>' +

      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('list', 15) + '</span>科目欠账排行（未完成 + 逾期加权）</h3>' +
      '<div class="top3-list">' + top3 + '</div></div>' +

      '<div class="stats-card reveal"><h3><span class="e">' + S.icons.icon('calendar', 15) + '</span>' + RANGE_LABEL[range] + '一览</h3>' +
      '<div class="summary-list">' +
      '<div class="summary-item" style="--i:0"><span>' + S.icons.icon('pin', 13) + ' ' + RANGE_LABEL[range] + '新增</span><b>' + s.rangeTotal + '</b></div>' +
      '<div class="summary-item" style="--i:1"><span>' + S.icons.icon('check', 13) + ' 完成</span><b class="ok">' + s.rangeCompleted + '</b></div>' +
      '<div class="summary-item" style="--i:2"><span>' + S.icons.icon('chart-line', 13) + ' 完成率</span><b>' + s.rangeRate + '%</b></div>' +
      '<div class="summary-item" style="--i:3"><span>' + S.icons.icon('clock', 13) + ' 今日待完成</span><b class="no">' + s.todayActive + '</b></div>' +
      '</div></div>' +
      '</div>';

    bind(wrap);
  }

  function exportReport() {
    const range = g.App.state.statsRange;
    const s = stats.compute(store.state, range);
    const lines = [
      '糖纸 · SugarPaper 统计报告（' + RANGE_LABEL[range] + '）',
      '生成时间：' + util.fmtDateTime(new Date().toISOString()),
      '',
      '【整体进度】',
      '  总任务：' + s.total + ' 项',
      '  已完成：' + s.completed + ' 项（' + s.rate + '%）',
      '  进行中：' + s.active + ' 项',
      '  连续完成天数：' + s.streak + ' 天',
      (s.onTimeRate != null ? '  准时完成率：' + s.onTimeRate + '%（' + s.onTimeCount + '/' + s.dueCompletedCount + '）' : ''),
      '',
      '【专注】',
      '  今日专注：' + s.focusTodayMinutes + ' 分钟（' + s.focusTodayCount + ' 个番茄）',
      '  本周专注：' + s.focusWeekMinutes + ' 分钟（' + s.focusWeekCount + ' 个番茄）',
      '  累计专注：' + s.focusTotalMinutes + ' 分钟',
      '  连续专注天数：' + s.focusStreak + ' 天',
      '',
      '【科目分布】',
      ...s.subjectDist.map((x) => '  ' + x.name + '：' + x.count + ' 项（' + x.pct + '%）'),
      '',
      '【高频未完成科目】',
      ...(s.topUnfinished.length ? s.topUnfinished.map((x) => '  ' + x.name + '：' + x.count + ' 项') : ['  无']),
      '',
      '【每日完成趋势（最近7天）】',
      ...s.dailyTrend.map((d) => '  ' + d.date + '：' + d.count + ' 项'),
      ''
    ];
    const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = '糖纸-统计报告-' + util.todayStr() + '.txt';
    a.click();
    URL.revokeObjectURL(a.href);
    S.ui.toast('统计报告已导出');
  }

  /** 导出统计报告为 PNG 图片（v0.21.0）：SVG 报告卡片 → Canvas → PNG 下载 */
  function exportImage() {
    const range = g.App.state.statsRange;
    const s = stats.compute(store.state, range);
    const svg = S.report.buildReportSvg(s, RANGE_LABEL[range], util.todayStr(), (name) => store.getSubjectColor(name));
    const url = URL.createObjectURL(new Blob([svg], { type: 'image/svg+xml;charset=utf-8' }));
    const img = new Image();
    img.onload = () => {
      const scale = 2;
      const w = 640;
      const h = 880;
      const canvas = document.createElement('canvas');
      canvas.width = w * scale;
      canvas.height = h * scale;
      const ctx = canvas.getContext('2d');
      ctx.scale(scale, scale);
      ctx.drawImage(img, 0, 0, w, h);
      URL.revokeObjectURL(url);
      const a = document.createElement('a');
      a.href = canvas.toDataURL('image/png');
      a.download = '糖纸-统计报告-' + util.todayStr() + '.png';
      a.click();
    S.ui.toast('统计报告图片已导出');
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      S.ui.toast('图片生成失败，请重试');
    };
    img.src = url;
  }

  function bind(wrap) {
    wrap.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (btn && btn.dataset.action === 'export') { exportReport(); return; }
      if (btn && btn.dataset.action === 'export-image') { exportImage(); return; }
      const rangeBtn = e.target.closest('[data-range]');
      if (rangeBtn) {
        g.App.state.statsRange = rangeBtn.dataset.range;
        g.App.renderView();
      }
    });
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.stats = { render };
})(typeof window !== 'undefined' ? window : globalThis);
