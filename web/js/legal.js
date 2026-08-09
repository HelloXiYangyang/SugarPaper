/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 用户协议 / 隐私政策（v0.28.0）
   首次打开必须阅读并勾选同意后才能使用；同意状态存本地，之后不再弹出。
   设置页「法律与隐私」可随时查看两份协议。
   协议正文源：web/legal/terms.md、web/legal/privacy.md（与仓库根文档同步维护）。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const esc = S.util.escapeHtml;
  const LEGAL_VERSION = 'v1.0.0';
  const KEY = 'sugarpaper:legal:v1';
  const FILES = {
    terms: './legal/terms.md',
    privacy: './legal/privacy.md'
  };
  const TITLES = {
    terms: '用户协议',
    privacy: '隐私政策'
  };

  function isAgreed() {
    try {
      return g.localStorage && g.localStorage.getItem(KEY) === LEGAL_VERSION;
    } catch (e) {
      return false;
    }
  }

  function agree() {
    try {
      if (g.localStorage) g.localStorage.setItem(KEY, LEGAL_VERSION);
    } catch (e) { /* 隐私模式等场景：保持未同意，不进入应用 */ }
  }

  /** 加载协议 Markdown 并渲染为 HTML */
  function loadHtml(kind) {
    return fetch(FILES[kind] || FILES.terms, { cache: 'no-store' })
      .then((res) => {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.text();
      })
      .then((text) => S.markdown ? S.markdown.render(text) : esc(text));
  }

  /** 首次打开强制同意遮罩（未同意时阻止进入应用） */
  function showGate() {
    if (document.getElementById('legal-gate')) return;
    const gate = document.createElement('div');
    gate.id = 'legal-gate';
    gate.className = 'legal-gate';
    gate.innerHTML =
      '<div class="legal-gate-card">' +
      '<div class="legal-head">' +
      '<img class="legal-logo" src="icon.svg" alt="糖纸">' +
      '<div class="legal-title">糖纸 · SugarPaper</div>' +
      '<div class="legal-sub">欢迎使用！请阅读并同意以下协议后继续使用</div>' +
      '</div>' +
      '<div class="legal-tabs">' +
      '<button type="button" class="legal-tab active" data-legal-tab="terms">用户协议</button>' +
      '<button type="button" class="legal-tab" data-legal-tab="privacy">隐私政策</button>' +
      '</div>' +
      '<div class="legal-body" data-legal-body>' +
      '<div class="legal-loading">协议加载中…</div>' +
      '</div>' +
      '<div class="legal-foot">' +
      '<label class="legal-check">' +
      '<input type="checkbox" data-legal-check>' +
      '<span>我已阅读并同意<a class="legal-link" data-legal-open="terms" role="button">《用户协议》</a>和<a class="legal-link" data-legal-open="privacy" role="button">《隐私政策》</a></span>' +
      '</label>' +
      '<div class="legal-actions">' +
      '<button type="button" class="btn soft-danger" data-legal-decline>不同意并退出</button>' +
      '<button type="button" class="btn primary" data-legal-accept disabled>同意并继续使用</button>' +
      '</div>' +
      '</div>' +
      '</div>';
    document.body.appendChild(gate);

    let kind = 'terms';
    const body = gate.querySelector('[data-legal-body]');
    const acceptBtn = gate.querySelector('[data-legal-accept]');
    const check = gate.querySelector('[data-legal-check]');

    function renderKind(k) {
      kind = k;
      body.innerHTML = '<div class="legal-loading">协议加载中…</div>';
      gate.querySelectorAll('.legal-tab').forEach((t) => {
        t.classList.toggle('active', t.dataset.legalTab === k);
      });
      loadHtml(k).then((html) => {
        body.innerHTML = html;
        body.scrollTop = 0;
      }).catch(() => {
        body.innerHTML = '<div class="legal-error">协议加载失败，请检查网络后点击重试</div>' +
          '<button type="button" class="btn small primary" data-legal-retry>重试</button>';
        const retry = body.querySelector('[data-legal-retry]');
        if (retry) retry.addEventListener('click', () => renderKind(kind));
      });
    }

    gate.addEventListener('click', (e) => {
      const tab = e.target.closest('[data-legal-tab]');
      if (tab) { renderKind(tab.dataset.legalTab); return; }
      const link = e.target.closest('[data-legal-open]');
      if (link) { renderKind(link.dataset.legalOpen); return; }
      if (e.target.closest('[data-legal-decline]')) {
        S.ui.toast('您未同意协议，无法使用本产品，请关闭本页面');
        return;
      }
      if (e.target.closest('[data-legal-accept]') && check.checked) {
        agree();
        window.location.reload();
      }
    });
    check.addEventListener('change', () => {
      acceptBtn.disabled = !check.checked;
    });
    renderKind('terms');
  }

  /** 设置页「法律与隐私」：随时查看协议 */
  function view(kind) {
    const dlg = S.ui.modal.open({
      title: TITLES[kind] || '协议',
      footer: '',
      wide: true
    });
    dlg.bodyEl.innerHTML = '<div class="legal-loading">协议加载中…</div>';
    dlg.bodyEl.className = (dlg.bodyEl.className || '') + ' legal-body';
    loadHtml(kind).then((html) => {
      dlg.bodyEl.innerHTML = html;
      dlg.bodyEl.scrollTop = 0;
    }).catch(() => {
      dlg.bodyEl.innerHTML = '<div class="legal-error">协议加载失败，请稍后重试</div>';
    });
    dlg.footEl.innerHTML = '<button class="btn" data-action="close">关闭</button>';
    dlg.footEl.addEventListener('click', (e) => {
      if (e.target.closest('[data-action="close"]')) dlg.close();
    });
  }

  g.Sugar.legal = { isAgreed, agree, showGate, view, LEGAL_VERSION };
})(typeof window !== 'undefined' ? window : globalThis);
