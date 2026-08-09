/*
 * 渲染 Logo 预览图：node test/render_logos.js（需本机已安装 Playwright Chromium / Edge）
 */
'use strict';

const path = require('path');
const http = require('http');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');

const root = path.join(__dirname, '..', '..');
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.svg': 'image/svg+xml'
};

function startServer() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let urlPath = decodeURIComponent(req.url.split('?')[0]);
      if (urlPath === '/') urlPath = '/logo-preview.html';
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

const logos = [
  ['a-simple', 'A 极简对勾'],
  ['b-bubble', 'B 任务气泡'],
  ['c-fold', 'C 折纸对勾'],
  ['d-plane', 'D 折纸飞机'],
  ['e-sugar', 'E 方糖对勾'],
  ['f-s', 'F S 形纸带']
];

async function main() {
  const server = await startServer();
  const port = server.address().port;
  const base = 'http://127.0.0.1:' + port;
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true
  });

  // 总览图
  const page = await browser.newPage({ viewport: { width: 1560, height: 1080 } });
  await page.goto(base + '/logo-preview.html', { waitUntil: 'networkidle' });
  await page.screenshot({ path: path.join(root, 'logo-preview.png'), fullPage: true });

  // 单款实物效果图（白卡片 + 圆角 + 投影）
  for (const [slug, label] of logos) {
    const svg = fs.readFileSync(path.join(root, 'logo-concept-' + slug + '.svg'), 'utf8');
    await page.setViewportSize({ width: 720, height: 720 });
    await page.setContent(
      '<!DOCTYPE html><html><head><style>' +
      'body{margin:0;background:#F7F7F7;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;font-family:-apple-system,"Segoe UI","Microsoft YaHei",sans-serif;}' +
      '.wrap{width:300px;height:300px;border-radius:68px;overflow:hidden;box-shadow:0 28px 70px rgba(18,52,110,.28);}' +
      '.wrap svg{width:100%;height:100%;display:block;}' +
      '.cap{margin-top:28px;font-size:22px;font-weight:600;color:#1F1F1F;}' +
      '.cap2{margin-top:6px;font-size:14px;color:#A0A0A0;}' +
      '</style></head><body>' +
      '<div class="wrap">' + svg + '</div>' +
      '<div class="cap">' + label + '</div>' +
      '<div class="cap2">糖纸 SugarPaper</div>' +
      '</body></html>'
    );
    await page.screenshot({ path: path.join(root, 'logo-' + slug + '-preview.png') });
  }

  await browser.close();
  server.close();
  console.log('done: logo-preview.png + 6 x logo-*-preview.png');
}

main().catch((e) => { console.error(e); process.exit(1); });
