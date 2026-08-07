/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* S12 专注页截图：node web/test/shot-focus.js */
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

async function main() {
  const server = await startServer();
  const base = 'http://127.0.0.1:' + server.address().port;
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true
  });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
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
  await page.evaluate(() => {
    const btn = document.querySelector('.bottom-nav button[data-nav="focus"]');
    if (btn) btn.click();
  });
  await page.waitForTimeout(600);
  const dir = path.join(root, 'test', 'shots');
  fs.mkdirSync(dir, { recursive: true });
  await page.screenshot({ path: path.join(dir, 'focus-page-mobile.png') });

  const wide = await browser.newPage({ viewport: { width: 900, height: 800 } });
  await wide.goto(base + '/index.html', { waitUntil: 'networkidle' });
  if (await wide.locator('#legal-gate').count()) {
    await wide.waitForFunction(() => {
      const b = document.querySelector('[data-legal-body]');
      return b && b.innerText.length > 100;
    });
    await wide.locator('[data-legal-check]').check();
    await wide.locator('[data-legal-accept]').click();
    await wide.waitForLoadState('networkidle');
    await wide.waitForTimeout(300);
  }
  await wide.evaluate(() => {
    const btn = document.querySelector('.top-tabs button[data-nav="focus"], .bottom-nav button[data-nav="focus"]');
    if (btn) btn.click();
  });
  await wide.waitForTimeout(600);
  await wide.screenshot({ path: path.join(dir, 'focus-page-wide.png') });

  await browser.close();
  server.close();
  console.log('专注页截图已生成：web/test/shots/focus-page-mobile.png / focus-page-wide.png');
}

main().catch((e) => { console.error(e); process.exit(1); });
