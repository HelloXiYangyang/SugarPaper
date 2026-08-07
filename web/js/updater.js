/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 零服务器自动更新（网页版，v0.27.0）
   启动后读取 GitHub Pages 上的 updates/latest.json 元数据，与当前 APP_VERSION 对比：
   发现新版本时弹出「立即刷新 / 更新记录」横幅；Service Worker 检测到新版外壳时复用同一横幅。
   设置页「更新」卡片可手动检查并一键刷新。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const store = S.store;
  const esc = S.util.escapeHtml;

  // 元数据相对仓库根：网页版部署在 /app/ 下，向上两级即仓库根（本地测试根目录同样可用）
  const UPDATES_URL = '../../updates/latest.json';
  const RELEASES_URL = 'https://github.com/HelloXiYangyang/SugarPaper/releases';
  const DISMISS_KEY = 'sugarpaper:update-dismiss:v1';

  const state = {
    checked: false, // 是否已完成过至少一次检查
    checking: false, // 正在检查中
    latest: null, // 元数据中的最新版本信息
    updateAvailable: false, // 远端版本比本地新
    shellUpdate: false, // Service Worker 已下载新版外壳
    error: null
  };

  /** 解析 "v0.27.0" 这类版本号为主版本号数组 */
  function parseVersion(v) {
    const m = String(v || '').trim().match(/^v?(\d+)\.(\d+)\.(\d+)/);
    if (!m) return null;
    return m.slice(1).map((n) => parseInt(n, 10) || 0);
  }

  /** 语义化版本比较：a 是否比 b 新 */
  function isNewer(a, b) {
    const x = parseVersion(a);
    const y = parseVersion(b);
    if (!x || !y) return false;
    for (let i = 0; i < 3; i++) {
      if (x[i] > y[i]) return true;
      if (x[i] < y[i]) return false;
    }
    return false;
  }

  function dismissVersion() {
    try {
      return g.localStorage && g.localStorage.getItem(DISMISS_KEY) || '';
    } catch (e) {
      return '';
    }
  }

  function rememberDismiss(v) {
    try {
      if (g.localStorage) g.localStorage.setItem(DISMISS_KEY, v);
    } catch (e) { /* 隐私模式等场景静默忽略 */ }
  }

  /** v0.31.0：统一的新版本升级弹窗（版本检查 / SW 外壳更新共用） */
  function showUpdateDialog() {
    const v = state.latest && state.latest.version;
    const isVer = state.updateAvailable && v;
    const mark = isVer ? String(v) : '__shell__';
    if (dismissVersion() === mark) return;
    const root = document.body;
    if (root.querySelector('.update-dialog')) return;

    const mask = document.createElement('div');
    mask.className = 'update-dialog';
    mask.innerHTML = '<div class="ud-card">' +
      '<div class="ud-head">' +
      '<span class="ud-icon">' + S.icons.icon('download', 18) + '</span>' +
      '<div class="ud-title"><b>' + (isVer ? '发现新版本 v' + esc(v) : '已下载新版本，刷新后生效') + '</b>' +
      '<span class="ud-sub">' + (isVer ? '糖纸 · SugarPaper 有新版本可以升级' : '新版外壳已准备就绪') + '</span></div>' +
      '<button class="ud-close" data-update-dismiss title="稍后再说">' + S.icons.icon('close', 14) + '</button>' +
      '</div>' +
      (isVer ? '<div class="ud-notes">' + esc((state.latest.notes || '').replace(/\s+/g, ' ').slice(0, 120)) + '</div>' : '') +
      '<div class="ud-status" data-update-status>' + (isVer ? '新版本正在后台准备中…' : '') + '</div>' +
      '<div class="ud-actions">' +
      (isVer ? '<button class="btn small" data-update-ignore>忽略此版本</button>' : '') +
      '<button class="btn small" data-update-later>稍后再说</button>' +
      '<button class="btn small primary" data-update-refresh>' + S.icons.icon('download', 12) + ' 立即升级</button>' +
      '</div></div>';
    root.appendChild(mask);

    const refreshBtn = mask.querySelector('[data-update-refresh]');
    if (refreshBtn) refreshBtn.addEventListener('click', refresh);
    const laterBtn = mask.querySelector('[data-update-later]');
    if (laterBtn) laterBtn.addEventListener('click', () => mask.remove());
    const ignoreBtn = mask.querySelector('[data-update-ignore]');
    if (ignoreBtn) {
      ignoreBtn.addEventListener('click', () => {
        rememberDismiss(mark);
        mask.remove();
      });
    }
    const dismissBtn = mask.querySelector('[data-update-dismiss]');
    if (dismissBtn) dismissBtn.addEventListener('click', () => mask.remove());
  }

  /** SW 新外壳下载进度：installed 后提示已就绪 */
  function markShellReady() {
    const status = document.querySelector('[data-update-status]');
    if (status) status.textContent = '新版本已就绪，点击「立即升级」即可生效';
  }

  /** 兼容旧调用：新版本/外壳统一走升级弹窗 */
  function showBanner() {
    showUpdateDialog();
  }

  /**
   * 检查更新：读取 updates/latest.json 并比较版本号
   * @param {boolean} force 忽略已检查缓存，强制重新拉取
   */
  function check(force) {
    if (state.checking) return state._promise;
    if (!force && state.checked) return Promise.resolve(state);
    state.checking = true;
    state._promise = fetch(UPDATES_URL + '?t=' + Date.now(), { cache: 'no-store' })
      .then((res) => {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.json();
      })
      .then((meta) => {
        state.latest = meta && meta.latest ? meta.latest : null;
        state.updateAvailable = !!(state.latest && isNewer(state.latest.version, store.APP_VERSION));
        state.error = null;
        if (state.updateAvailable) showBanner();
        return state;
      })
      .catch((err) => {
        state.error = err && err.message ? err.message : String(err);
        state.updateAvailable = false;
        return state;
      })
      .then((s) => {
        state.checking = false;
        state.checked = true;
        return s;
      });
    return state._promise;
  }

  /** 立即刷新页面（新版外壳/新版代码生效） */
  function refresh() {
    window.location.reload();
  }

  /** 注册 Service Worker：发现新版外壳时提示；接管后自动刷新 */
  function registerSw() {
    if (!('serviceWorker' in navigator)) return;
    const start = () => {
      navigator.serviceWorker.register('sw.js').then((reg) => {
        reg.addEventListener('updatefound', () => {
          const nw = reg.installing;
          if (!nw) return;
          nw.addEventListener('statechange', () => {
            if (nw.state === 'installed' && navigator.serviceWorker.controller) {
              state.shellUpdate = true;
              showUpdateDialog();
              markShellReady();
            }
          });
        });
      }).catch(() => { /* 注册失败不影响使用 */ });
      let refreshing = false;
      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (refreshing) return;
        refreshing = true;
        window.location.reload();
      });
    };
    // init() 通常在 load 事件中调用；load 事件分发期间新增的同名监听器不会触发，
    // 因此按 readyState 判断：已加载完成则立即注册，否则等 load。
    if (document.readyState === 'complete') {
      start();
    } else {
      window.addEventListener('load', start);
    }
  }

  /** 应用启动入口：注册 SW + 3 秒后静默检查一次版本 */
  function init() {
    registerSw();
    setTimeout(() => check(), 3000);
  }

  g.Sugar.updater = { init, check, refresh, state };
})(typeof window !== 'undefined' ? window : globalThis);
