/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 下载区：读取 updates/latest.json 自动指向最新版本。
   同一份元数据既供客户端自动更新，也供官网下载按钮使用。 */
(function () {
  'use strict';

  var FALLBACK_RELEASE = 'https://github.com/HelloXiYangyang/SugarPaper/releases/latest';
  var SOURCES = [
    'updates/latest.json',                       // GitHub Pages 同站部署
    'https://raw.githubusercontent.com/HelloXiYangyang/SugarPaper/main/updates/latest.json'
  ];

  function $(s, root) { return (root || document).querySelector(s); }

  function setDownload(id, url, name) {
    var el = document.getElementById(id);
    if (el && url) { el.href = url; el.setAttribute('target', '_blank'); el.setAttribute('rel', 'noopener'); }
    var nameEl = document.getElementById(id + '-name');
    if (nameEl && name) nameEl.textContent = name;
  }

  function apply(data) {
    var latest = data.latest || {};
    var platforms = data.platforms || {};
    var ver = latest.version || '';
    var verEl = document.getElementById('dl-ver');
    if (verEl) verEl.textContent = '最新版本 v' + ver;
    document.title = document.title.replace(/\s*·\s*最新版.*$/, '') + ' · 最新版 v' + ver;

    if (platforms.android) {
      setDownload('dl-android', platforms.android.url,
        'Android APK v' + ver);
    } else {
      setDownload('dl-android', FALLBACK_RELEASE, 'Android APK');
    }
    if (platforms.windows) setDownload('dl-windows', platforms.windows.url, 'Windows');
    if (platforms.harmonyos) setDownload('dl-hap', platforms.harmonyos.url, '鸿蒙 HAP');

    var notes = latest.notes || '';
    var cl = document.getElementById('changelog-list');
    if (cl && notes) {
      var item = document.createElement('div');
      item.className = 'cl-item';
      item.innerHTML = '<div><span class="cl-ver">v' + ver + '</span>' +
        '<span class="cl-date">' + (latest.published_at || '') + '</span></div>' +
        '<ul>' + notes.split('\n').map(function (line) {
          return '<li>' + line.replace(/^-\s*/, '') + '</li>';
        }).join('') + '</ul>';
      cl.prepend(item);
    }
  }

  function trySource(i) {
    if (i >= SOURCES.length) {
      setDownload('dl-android', FALLBACK_RELEASE, 'Android APK');
      var verEl = document.getElementById('dl-ver');
      if (verEl) verEl.textContent = '查看 GitHub Releases 最新版';
      return;
    }
    fetch(SOURCES[i], { cache: 'no-store' })
      .then(function (r) { if (!r.ok) throw new Error('not ok'); return r.json(); })
      .then(function (data) {
        if (data && data.latest) apply(data);
        else trySource(i + 1);
      })
      .catch(function () { trySource(i + 1); });
  }

  trySource(0);
})();
