/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/* 官网截图：node web/test/shot-site.js
   按 deploy-pages.yml 的部署结构做路径映射：
   根路径 → site/，/app/ → web/，/updates/ → updates/。 */
'use strict';

const path = require('path');
const http = require('http');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');

const repo = path.join(__dirname, '..', '..');
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml'
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let urlPath = decodeURIComponent(req.url.split('?')[0]);
      let filePath;
      if (urlPath === '/' || urlPath === '/index.html') {
        filePath = path.join(repo, 'site', 'index.html');
      } else if (urlPath.startsWith('/app/')) {
        filePath = path.join(repo, 'web', urlPath.slice('/app/'.length));
      } else if (urlPath.startsWith('/updates/')) {
        filePath = path.join(repo, 'updates', urlPath.slice('/updates/'.length));
      } else {
        filePath = path.join(repo, 'site', path.normalize(urlPath));
      }
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
  const page = await browser.newPage({ viewport: { width: 1200, height: 900 } });
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(base + '/', { waitUntil: 'networkidle' });
  await page.waitForTimeout(600);
  const dir = path.join(__dirname, 'shots');
  fs.mkdirSync(dir, { recursive: true });
  await page.screenshot({ path: path.join(dir, 'site-home.png'), fullPage: true });
  const ver = await page.locator('#dl-ver').textContent();
  await browser.close();
  server.close();
  console.log('官网截图已生成：web/test/shots/site-home.png');
  console.log('版本行：' + ver + '（' + (errors.length ? 'JS 错误：' + errors.join(' | ') : '无 JS 错误') + '）');
}

main().catch((e) => { console.error(e); process.exit(1); });
