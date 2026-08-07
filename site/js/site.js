/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 官网交互：Hero 入场动画、滚动显现、顶部导航高亮、移动端抽屉。 */
(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* Hero 入场动画 */
  var introContainer = document.querySelector('.introduction-container');
  if (introContainer && !reduced) {
    requestAnimationFrame(function () {
      introContainer.classList.add('intro-enter-active');
    });
  }

  /* 滚动显现 */
  var revealEls = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window && !reduced) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('revealed');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -48px 0px' });
    revealEls.forEach(function (el) { io.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add('revealed'); });
  }

  /* 顶部导航高亮（滚动监听） */
  var tabLinks = Array.prototype.slice.call(
    document.querySelectorAll('#app-bar-tabs .fluent-selector-bar__item')
  );
  var sections = tabLinks
    .map(function (a) {
      var id = (a.getAttribute('href') || '').replace(/^#/, '');
      return id ? document.getElementById(id) : null;
    })
    .filter(Boolean);
  var bar = document.getElementById('app-bar-tabs');

  function setActive(id) {
    tabLinks.forEach(function (a) {
      var active = a.getAttribute('href') === '#' + id;
      a.classList.toggle('router-link-active', active);
    });
  }

  function onScroll() {
    var pos = window.scrollY + 72;
    var current = null;
    sections.forEach(function (sec) {
      if (sec.offsetTop <= pos) current = sec.id;
    });
    if (!current && window.scrollY < sections[0].offsetTop) current = sections[0].id;
    if (current) setActive(current);
  }

  if (bar && sections.length) {
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* 移动端抽屉 */
  var overlay = document.getElementById('drawer-overlay');
  var openBtn = document.getElementById('nav-open');
  if (overlay && openBtn) {
    function closeDrawer() {
      overlay.hidden = true;
      document.body.style.overflow = '';
    }
    openBtn.addEventListener('click', function () {
      overlay.hidden = false;
      document.body.style.overflow = 'hidden';
    });
    overlay.addEventListener('click', function (e) {
      if (e.target === overlay) closeDrawer();
    });
    overlay.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', closeDrawer);
    });
    window.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !overlay.hidden) closeDrawer();
    });
  }

  /* 文档站：侧边栏（移动端抽屉 + 锚点高亮） */
  var docsSidebar = document.getElementById('docs-sidebar');
  var tocBtn = document.getElementById('docs-toc-btn');
  var docsBackdrop = document.querySelector('.docs-backdrop');
  if (docsSidebar && tocBtn) {
    function openDocsSidebar() {
      docsSidebar.classList.add('open');
      if (docsBackdrop) docsBackdrop.classList.add('show');
      document.body.style.overflow = 'hidden';
    }
    function closeDocsSidebar() {
      docsSidebar.classList.remove('open');
      if (docsBackdrop) docsBackdrop.classList.remove('show');
      document.body.style.overflow = '';
    }
    tocBtn.addEventListener('click', function () {
      if (docsSidebar.classList.contains('open')) closeDocsSidebar();
      else openDocsSidebar();
    });
    if (docsBackdrop) docsBackdrop.addEventListener('click', closeDocsSidebar);
    docsSidebar.querySelectorAll('a').forEach(function (a) {
      a.addEventListener('click', closeDocsSidebar);
    });

    var sidebarLinks = Array.prototype.slice.call(
      docsSidebar.querySelectorAll('a[href^="#"]')
    );
    var sidebarTargets = sidebarLinks
      .map(function (a) { return document.querySelector(a.getAttribute('href')); })
      .filter(Boolean);
    if (sidebarTargets.length && 'IntersectionObserver' in window) {
      var spy = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            sidebarLinks.forEach(function (a) {
              a.classList.toggle('active', a.getAttribute('href') === '#' + entry.target.id);
            });
          }
        });
      }, { rootMargin: '-72px 0px -62% 0px' });
      sidebarTargets.forEach(function (t) { spy.observe(t); });
    }
  }
})();
