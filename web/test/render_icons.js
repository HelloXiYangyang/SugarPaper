/*
 * 生成正式 Logo 全套资源（PNG / ICO）：
 * node test/render_icons.js（需本机已安装 Playwright Chromium / Edge）
 */
'use strict';

const path = require('path');
const fs = require('fs');
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');

const root = path.join(__dirname, '..', '..');
const andRes = path.join(root, 'app', 'android', 'app', 'src', 'main', 'res');

const SVG_FULL = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">' +
  '<defs><linearGradient id="bgA" x1="0" y1="0" x2="1" y2="1">' +
  '<stop offset="0" stop-color="#3B82F0"/><stop offset="1" stop-color="#1677FF"/>' +
  '</linearGradient></defs>' +
  '<rect width="128" height="128" rx="28" fill="url(#bgA)"/>' +
  '<path d="M40 66 L56 82 L90 46" stroke="#FFFFFF" stroke-width="13" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' +
  '</svg>';

const SVG_FORE = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">' +
  '<path d="M36 70 L54 88 L94 46" stroke="#FFFFFF" stroke-width="16" stroke-linecap="round" stroke-linejoin="round" fill="none"/>' +
  '</svg>';

function pngSize(buf) {
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}

async function shot(page, svg, size, out) {
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(
    '<!DOCTYPE html><html><head><style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}' +
    '#w{width:' + size + 'px;height:' + size + 'px}</style></head><body><div id="w">' + svg + '</div></body></html>'
  );
  await page.waitForTimeout(120);
  await page.locator('#w').screenshot({ path: out });
}

function buildIco(sizes, dir, outPath) {
  const images = sizes.map((s) => fs.readFileSync(path.join(dir, 'ico-' + s + '.png')));
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(images.length, 4);
  const entries = [];
  let offset = 6 + 16 * images.length;
  images.forEach((data, i) => {
    const size = sizes[i];
    const e = Buffer.alloc(16);
    e.writeUInt8(size === 256 ? 0 : size, 0);
    e.writeUInt8(size === 256 ? 0 : size, 1);
    e.writeUInt8(0, 2);
    e.writeUInt8(0, 3);
    e.writeUInt16LE(1, 4);
    e.writeUInt16LE(32, 6);
    e.writeUInt32LE(data.length, 8);
    e.writeUInt32LE(offset, 12);
    offset += data.length;
    entries.push(e);
  });
  fs.writeFileSync(outPath, Buffer.concat([header, ...entries, ...images]));
}

async function main() {
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true
  });
  const page = await browser.newPage();

  const mkdir = (p) => fs.mkdirSync(p, { recursive: true });

  // 1) Web PWA 图标
  mkdir(path.join(root, 'web', 'icons'));
  await shot(page, SVG_FULL, 512, path.join(root, 'web', 'icons', 'icon-512.png'));
  await shot(page, SVG_FULL, 192, path.join(root, 'web', 'icons', 'icon-192.png'));

  // 2) 安卓旧式图标（蓝底白勾，全图）
  const mipmap = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
  };
  for (const dir of Object.keys(mipmap)) {
    const size = mipmap[dir];
    const target = path.join(andRes, dir, 'ic_launcher.png');
    await shot(page, SVG_FULL, size, target);
  }

  // 3) 安卓 adaptive 前景（白勾透明底，按现有文件尺寸）
  const drawables = ['drawable-mdpi', 'drawable-hdpi', 'drawable-xhdpi', 'drawable-xxhdpi', 'drawable-xxxhdpi'];
  for (const dir of drawables) {
    const src = path.join(andRes, dir, 'ic_launcher_foreground.png');
    if (!fs.existsSync(src)) continue;
    const dim = pngSize(fs.readFileSync(src));
    await shot(page, SVG_FORE, Math.max(dim.w, dim.h), src);
  }

  // 4) Windows ICO
  const icoDir = path.join(root, 'web', 'test', 'ico-tmp');
  mkdir(icoDir);
  const sizes = [16, 32, 48, 64, 128, 256];
  for (const s of sizes) {
    await shot(page, SVG_FULL, s, path.join(icoDir, 'ico-' + s + '.png'));
  }
  buildIco(sizes, icoDir, path.join(root, 'app', 'windows', 'runner', 'resources', 'app_icon.ico'));
  fs.rmSync(icoDir, { recursive: true, force: true });

  await browser.close();
  console.log('done: web/icons/*.png, android ic_launcher*, windows app_icon.ico');
}

main().catch((e) => { console.error(e); process.exit(1); });
