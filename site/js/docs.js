/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * 文档站交互：主题切换、移动端目录抽屉、滚动高亮、图标注入与标题锚点。
 * 布局风格参考 ClassIsland 文档（VuePress Theme Hope）。
 */
(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- 图标集（data-icon 注入） ---------- */
  var ICONS = {
    home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/>',
    book: '<path d="M4 4.5A2.5 2.5 0 0 1 6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5z"/><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>',
    bulb: '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.8.6 1.5 1.4 1.5 2.6h4c0-1.2.7-2 1.5-2.6A6 6 0 0 0 12 3z"/>',
    server: '<rect x="3" y="4" width="18" height="6" rx="1.5"/><rect x="3" y="14" width="18" height="6" rx="1.5"/><path d="M6.5 7h.01M6.5 17h.01"/>',
    code: '<path d="M8 7l-5 5 5 5M16 7l5 5-5 5M13 4l-2 16"/>',
    users: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c0-3.5 2.9-6 6.5-6s6.5 2.5 6.5 6M16 5.2a3.5 3.5 0 0 1 0 6.6M17.5 14.3c2.4.8 4 2.8 4 5.7"/>',
    download: '<path d="M12 3v11M7 10l5 5 5-5M4 20h16"/>',
    rocket: '<path d="M4.5 16.5c-1 3 .5 4 3 3.5M8 21c3 .5 4-1 3.5-3M12 15l-4-4c2.5-4.5 6-6 10-5 .5 4-1 7.5-5 10z"/><circle cx="13.5" cy="10.5" r="1.3"/>',
    flag: '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/>',
    chart: '<path d="M5 20v-6M10 20V8M15 20v-9M20 20V4"/><path d="M3 20h18"/>',
    timer: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 2h6"/>',
    note: '<path d="M5 3h14v13l-4 4H5z"/><path d="M15 20v-4h4"/>',
    camera: '<path d="M4 7h3l2-2h6l2 2h3v13H4z"/><circle cx="12" cy="13" r="3.5"/>',
    star: '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
    palette: '<path d="M12 3a9 9 0 1 0 0 18c1.7 0 2.5-1.2 2.5-2.4 0-1.6-1.3-1.7-1.3-2.9 0-1.2 1.4-1.4 3.4-1.4 1.3 0 2.6.5 3.7.5 1.3 0 2.7-1 2.7-2.8A9 9 0 0 0 12 3z"/><circle cx="7.5" cy="11.5" r=".9"/><circle cx="10" cy="7.5" r=".9"/><circle cx="15" cy="7.5" r=".9"/>',
    teacher: '<path d="M3 9l9-5 9 5-9 5z"/><path d="M6.5 11.5V17c0 1.5 2.5 3 5.5 3s5.5-1.5 5.5-3v-5.5"/>',
    shield: '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M9 12l2 2 4-4"/>',
    sync: '<path d="M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7"/>',
    database: '<ellipse cx="12" cy="5.5" rx="8" ry="2.8"/><path d="M4 5.5v13c0 1.6 3.6 2.8 8 2.8s8-1.2 8-2.8v-13"/><path d="M4 12c0 1.6 3.6 2.8 8 2.8s8-1.2 8-2.8"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.6 4 5.7 4 9s-1.5 6.4-4 9c-2.5-2.6-4-5.7-4-9s1.5-6.4 4-9z"/>',
    search: '<circle cx="11" cy="11" r="6"/><path d="M15.5 15.5L20 20"/>',
    doc: '<path d="M5 3h9l5 5v13H5z"/><path d="M14 3v5h5"/>',
    arrow: '<path d="M4 12h16M14 6l6 6-6 6"/>',
    check: '<path d="M4 12.5l5 5L20 6.5"/>'
  };

  function iconSvg(name, size) {
    return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
      'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
      (ICONS[name] || ICONS.doc) + '</svg>';
  }

  document.querySelectorAll('[data-icon]').forEach(function (el) {
    var name = el.getAttribute('data-icon');
    var size = parseInt(el.getAttribute('data-icon-size') || '16', 10);
    el.innerHTML = iconSvg(name, size);
  });

  /* ---------- 主题切换 ---------- */
  var THEME_KEY = 'sugarpaper-docs-theme';
  var root = document.documentElement;
  var themeBtn = document.getElementById('theme-toggle');
  if (themeBtn) {
    themeBtn.addEventListener('click', function () {
      var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem(THEME_KEY, next); } catch (e) { /* 忽略 */ }
    });
  }

  /* ---------- 移动端目录抽屉 ---------- */
  var sidebar = document.getElementById('docs-sidebar');
  var menuBtn = document.getElementById('docs-menu-btn');
  var backdrop = document.getElementById('docs-backdrop');

  function closeSidebar() {
    if (!sidebar) return;
    sidebar.classList.remove('open');
    if (backdrop) backdrop.classList.remove('show');
    document.body.style.overflow = '';
  }
  function openSidebar() {
    if (!sidebar) return;
    sidebar.classList.add('open');
    if (backdrop) backdrop.classList.add('show');
    document.body.style.overflow = 'hidden';
  }
  if (menuBtn) menuBtn.addEventListener('click', function () {
    if (sidebar && sidebar.classList.contains('open')) closeSidebar();
    else openSidebar();
  });
  if (backdrop) backdrop.addEventListener('click', closeSidebar);
  if (sidebar) {
    sidebar.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', closeSidebar);
    });
  }
  window.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeSidebar();
  });

  /* ---------- 侧边栏滚动高亮 ---------- */
  var sidebarLinks = sidebar
    ? Array.prototype.slice.call(sidebar.querySelectorAll('a[href^="#"]'))
    : [];
  var targets = sidebarLinks
    .map(function (a) { return document.querySelector(a.getAttribute('href')); })
    .filter(Boolean);
  if (targets.length && 'IntersectionObserver' in window && !reduced) {
    var spy = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          sidebarLinks.forEach(function (a) {
            a.classList.toggle('active', a.getAttribute('href') === '#' + entry.target.id);
          });
        }
      });
    }, { rootMargin: '-72px 0px -62% 0px' });
    targets.forEach(function (t) { spy.observe(t); });
  }

  /* ---------- 标题锚点 ---------- */
  if (!reduced) {
    document.querySelectorAll('.vp-content h2, .vp-content h3').forEach(function (h) {
      if (!h.id) return;
      var a = document.createElement('a');
      a.className = 'header-anchor';
      a.href = '#' + h.id;
      a.setAttribute('aria-label', '链接到 ' + h.textContent);
      a.innerHTML = iconSvg('arrow', 14);
      h.insertBefore(a, h.firstChild);
    });
  }
})();
