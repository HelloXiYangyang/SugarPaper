/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— Service Worker（v0.19.0）
   缓存应用外壳实现 PWA 离线可用；网络不可用时兜底到 index.html。 */
'use strict';

const CACHE_NAME = 'sugarpaper-shell-v0.19.0';
const APP_SHELL = [
  './',
  './index.html',
  './css/theme.css',
  './css/app.css',
  './js/util.js',
  './js/icons.js',
  './js/parser.js',
  './js/store.js',
  './js/account.js',
  './js/sync.js',
  './js/stats.js',
  './js/ui-modals.js',
  './js/ui-home.js',
  './js/ui-calendar.js',
  './js/ui-stats.js',
  './js/ui-settings.js',
  './js/ui-notes.js',
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
  event.respondWith(
    caches.match(req).then((hit) => {
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
