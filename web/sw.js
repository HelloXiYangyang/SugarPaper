/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— Service Worker（v0.27.0）
   缓存应用外壳实现 PWA 离线可用；网络不可用时兜底到 index.html。 */
'use strict';

// v0.27.1：手机端与电脑端导航图标样式统一后，bump 缓存名强制旧客户端重新拉取新外壳
const CACHE_NAME = 'sugarpaper-shell-v0.27.1';
const APP_SHELL = [
  './',
  './index.html',
  './css/theme.css',
  './css/app.css',
  './js/util.js',
  './js/markdown.js',
  './js/icons.js',
  './js/parser.js',
  './js/store.js',
  './js/updater.js',
  './js/account.js',
  './js/sync.js',
  './js/stats.js',
  './js/report.js',
  './js/teacher.js',
  './js/ui-modals.js',
  './js/ui-home.js',
  './js/ui-calendar.js',
  './js/ui-stats.js',
  './js/ui-settings.js',
  './js/ui-notes.js',
  './js/ui-teacher.js',
  './js/ui-focus.js',
  './js/ui-account.js',
  './js/reminders.js',
  './js/app.js',
  './manifest.webmanifest',
  './icon.svg',
  './assets/avatar-default.jpg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith('/relay')) return; // 本地测试中继不缓存
  const isMetadata = /\/updates\/latest\.json$/.test(url.pathname);
  event.respondWith(
    isMetadata
      ? fetch(req).catch(() => caches.match('./index.html'))
      : caches.match(req).then((hit) => {
        if (hit) return hit;
        return fetch(req).then((res) => {
          if (res.ok && req.url.indexOf('sw.js') < 0) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        }).catch(() => caches.match('./index.html'));
      })
  );
});
