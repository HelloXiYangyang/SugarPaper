/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 截图验证脚本：node test/screenshot.js（需本机已安装 Playwright Chromium） */
'use strict';

const path = require('path');
const http = require('http');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');

const root = path.join(__dirname, '..');
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.webmanifest': 'application/manifest+json; charset=utf-8'
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let urlPath = decodeURIComponent(req.url.split('?')[0]);
      if (urlPath === '/') urlPath = '/index.html';
      const filePath = path.join(root, path.normalize(urlPath));
      fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('Not Found'); return; }
        res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
        res.end(data);
      });
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

const outDir = path.join(__dirname, 'shots');

async function main() {
  const server = await startServer();
  const port = server.address().port;
  const base = 'http://127.0.0.1:' + port;
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true
  });
  const errors = [];
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push('[console] ' + msg.text());
  });
  page.on('pageerror', (err) => errors.push('[pageerror] ' + err.message));

  await page.goto(base + '/index.html', { waitUntil: 'networkidle' });
  // v0.28.0：首启协议同意
  if (await page.locator('#legal-gate').count()) {
    await page.waitForFunction(() => {
      const b = document.querySelector('[data-legal-body]');
      return b && b.innerText.length > 100;
    });
    await page.locator('[data-legal-check]').check();
    await page.locator('[data-legal-accept]').click();
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(300);
  }
  await page.evaluate(() => window.App.loadSample());
  await page.waitForTimeout(400);
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const shots = [
    ['home-mobile', 390, 844, 'home'],
    ['home-medium', 768, 1024, 'home'],
    ['home-desktop', 1440, 900, 'home'],
    ['home-xl', 1700, 1000, 'home'],
    ['calendar-desktop', 1440, 900, 'calendar'],
    ['calendar-mobile', 390, 844, 'calendar'],
    ['stats-desktop', 1440, 900, 'stats'],
    ['stats-mobile', 390, 844, 'stats'],
    ['settings-desktop', 1440, 900, 'settings'],
    ['settings-mobile', 390, 844, 'settings'],
    ['theme-bluegreen', 1440, 900, 'settings', 'bluegreen'],
    ['theme-dark', 1440, 900, 'settings', 'dark'],
    ['import-modal', 390, 844, null],
    ['notes-mobile', 390, 844, 'notes'],
    ['notes-desktop', 1440, 900, 'notes'],
    ['focus-mobile', 390, 844, null],
    ['account-modal', 1440, 900, 'settings']
  ];

  for (const [name, w, h, view, theme] of shots) {
    await page.setViewportSize({ width: w, height: h });
    if (view) await page.evaluate((v) => window.App.navigate(v), view);
    if (theme) await page.evaluate((t) => window.Sugar.store.updateSettings({ theme: t }), theme);
    if (name === 'import-modal') await page.evaluate(() => window.Sugar.ui.modal.openImport());
    if (name === 'focus-mobile') {
      await page.evaluate(() => window.Sugar.ui.focus.open(null));
    }
    if (name === 'account-modal') {
      await page.evaluate(() => window.Sugar.ui.account.openCreate());
      await page.waitForTimeout(1400); // 等待 PBKDF2 派生与助记词弹窗
    }
    await page.waitForTimeout(350);
    await page.screenshot({ path: path.join(outDir, name + '.png'), fullPage: false });
    if (name === 'import-modal') await page.evaluate(() => window.Sugar.ui.modal.closeAll());
    if (name === 'focus-mobile') await page.evaluate(() => window.Sugar.ui.focus.close());
    if (name === 'account-modal') await page.evaluate(() => window.Sugar.ui.modal.closeAll());
    console.log('📸 ' + name + ' (' + w + 'x' + h + ')');
  }

  await page.evaluate(() => window.Sugar.store.updateSettings({ theme: 'classic' }));

  console.log('\n页面错误：' + (errors.length ? '\n' + errors.join('\n') : '无 ✅'));
  await browser.close();
  server.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
