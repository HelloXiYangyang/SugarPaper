/* 端到端交互验证：node test/e2e.test.js */
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

let passed = 0;
let failed = 0;
function check(name, ok, extra) {
  if (ok) { passed++; console.log('  ✅ ' + name); }
  else { failed++; console.error('  ❌ ' + name + (extra ? ' —— ' + extra : '')); }
}

async function main() {
  const server = await startServer();
  const base = 'http://127.0.0.1:' + server.address().port;
  const browser = await chromium.launch({
    executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    headless: true
  });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/favicon|404/.test(m.text())) errors.push(m.text()); });

  await page.goto(base + '/index.html', { waitUntil: 'networkidle' });
  await page.evaluate(() => window.App.loadSample());
  await page.waitForTimeout(300);

  console.log('📱 首页（手机 390x844）');
  check('底部导航可见', await page.isVisible('.bottom-nav'));
  check('底部导航使用 SVG 图标', await page.locator('.bottom-nav svg.ico').count() === 4);
  check('导航不再使用 emoji 图标', (await page.locator('.bottom-nav').innerText()).replace(/\s+/g, '') === '首页日历统计我的');
  check('顶栏品牌 Logo 使用应用图标', await page.locator('#topbar .brand img.brand-logo[src="icon.svg"]').count() === 1);
  check('加载示例后共有 9 张任务卡', await page.locator('.task-card').count() === 9);
  check('进度胶囊显示 33%', (await page.locator('.progress-pill').innerText()).includes('33%'));
  check('进行中 6 项', (await page.locator('.task-group.ongoing .g-count').innerText()) === '6');
  check('已完成 3 项', (await page.locator('.task-group.done .g-count').innerText()) === '3');
  check('科目 Chip 已渲染（全部 + 16 科）', await page.locator('.chip').count() === 17);
  check('包含“体育与健康”科目 Chip', await page.locator('.chip[data-subject="体育与健康"]').count() === 1);

  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  check('无横向溢出', overflow <= 0, '溢出 ' + overflow + 'px');

  console.log('🖱 交互');
  await page.locator('.task-group.ongoing .action.done').first().click();
  await page.waitForTimeout(450); // 等待完成滑出动画（240ms）后分组切换
  check('点击完成 → 进行中减为 5', (await page.locator('.task-group.ongoing .g-count').innerText()) === '5');
  check('点击完成 → 已完成增为 4', (await page.locator('.task-group.done .g-count').innerText()) === '4');

  await page.locator('#home-search').fill('试卷');
  await page.waitForTimeout(300);
  const filtered = await page.locator('.task-card').count();
  check('搜索“试卷”过滤生效', filtered >= 1 && filtered < 9, '实际 ' + filtered);
  await page.locator('#home-search').fill('');
  await page.waitForTimeout(300);

  await page.locator('.chip[data-subject="数学"]').click();
  await page.waitForTimeout(200);
  const mathCards = await page.locator('.task-card').count();
  check('科目筛选“数学”生效', mathCards >= 1 && mathCards < 9, '实际 ' + mathCards);
  await page.locator('.chip[data-subject="全部"]').click();
  await page.waitForTimeout(200);

  console.log('🎬 动态动画');
  const dirLeft = await page.evaluate(() => {
    window.App.navigate('calendar');
    return document.getElementById('view-wrap').className;
  });
  check('前进切换触发右滑入动画', dirLeft.includes('view-enter-left'));
  const dirRight = await page.evaluate(() => {
    window.App.navigate('home');
    return document.getElementById('view-wrap').className;
  });
  check('后退切换触发左滑入动画', dirRight.includes('view-enter-right'));
  check('任务卡片启用滚动显现', await page.locator('.task-card.reveal').count() >= 1);
  await page.waitForTimeout(400);
  check('可见卡片已显现（reveal-in）', await page.locator('.task-card.reveal.reveal-in').count() >= 1);
  await page.emulateMedia({ reducedMotion: 'reduce' });
  const reducedDur = await page.evaluate(() => getComputedStyle(document.querySelector('.progress-pill .bar > i')).animationDuration);
  check('减弱动效时动画时长趋近 0', parseFloat(reducedDur) < 0.001);
  await page.emulateMedia({ reducedMotion: null });

  console.log('📅 日历');
  await page.evaluate(() => window.App.navigate('calendar'));
  await page.waitForTimeout(200);
  check('月视图网格渲染', await page.locator('.cal-cell').count() >= 28);
  check('有任务点的日期', await page.locator('.day-dots').count() >= 3);
  await page.locator('.cal-cell[data-date]').nth(10).click();
  await page.waitForTimeout(200);
  check('点击日期出现当日任务列表', await page.locator('.cal-day-list').isVisible());
  await page.locator('[data-mode="week"]').click();
  await page.waitForTimeout(200);
  check('周视图渲染', await page.locator('.cal-week-col').count() === 7);

  console.log('📊 统计');
  await page.evaluate(() => window.App.navigate('stats'));
  await page.waitForTimeout(300);
  check('进度环渲染', await page.locator('.progress-ring svg').count() >= 1);
  check('柱状图渲染', await page.locator('.stats-card svg').count() >= 2);
  check('饼图图例渲染', await page.locator('.legend-item').count() >= 3);
  check('高频未完成科目 Top3 渲染', await page.locator('.top3-item').count() >= 1);
  const pieAnim = await page.evaluate(() => {
    const p = document.querySelector('.pie-canvas path');
    if (!p) return null;
    const s = getComputedStyle(p);
    return { name: s.animationName, delay: parseFloat(s.animationDelay) };
  });
  check('饼图扇区绽放动画', !!pieAnim && pieAnim.name === 'slice-in');
  check('饼图扇区错峰加载（延迟≥0.4s）', !!pieAnim && pieAnim.delay >= 0.4);
  const summaryAnim = await page.evaluate(() => getComputedStyle(document.querySelector('.summary-item')).animationName);
  check('统计摘要逐项淡入', summaryAnim === 'fade-up');
  await page.locator('[data-range="today"]').click();
  await page.waitForTimeout(200);
  check('切换时间范围生效', (await page.locator('.cal-seg [data-range="today"]').getAttribute('class')).includes('active'));

  console.log('⚙️ 设置');
  await page.evaluate(() => window.App.navigate('settings'));
  await page.waitForTimeout(200);
  await page.locator('input[data-toggle="darkMode"]').check();
  await page.waitForTimeout(200);
  const theme = await page.evaluate(() => document.documentElement.dataset.theme);
  check('深色模式切换生效', theme === 'dark', 'theme=' + theme);
  await page.locator('input[data-toggle="darkMode"]').uncheck();
  await page.waitForTimeout(150);
  check('科目管理列表渲染 16 科', await page.locator('.subject-row').count() === 16);
  await page.locator('input[data-toggle="animations"]').uncheck();
  await page.waitForTimeout(200);
  check('关闭动画后 html 带 no-anim', await page.evaluate(() => document.documentElement.classList.contains('no-anim')));
  const noAnimDur = await page.evaluate(() => getComputedStyle(document.querySelector('.progress-pill .bar > i')).animationDuration);
  check('关闭动画后动画时长趋近 0', parseFloat(noAnimDur) < 0.001);
  await page.locator('input[data-toggle="animations"]').check();
  await page.waitForTimeout(200);
  check('重新开启动画后移除 no-anim', !(await page.evaluate(() => document.documentElement.classList.contains('no-anim'))));
  await page.locator('[data-frame-rate="60"]').click();
  await page.waitForTimeout(250);
  check('帧率切换到 60 档生效', await page.evaluate(() => document.documentElement.dataset.fps === '60'));
  const switchStyle = await page.evaluate(() => {
    const s = getComputedStyle(document.querySelector('.switch .thumb'));
    return { dur: parseFloat(s.transitionDuration), fn: s.transitionTimingFunction };
  });
  check('开关拇指弹簧过渡（≥0.28s）', switchStyle.dur >= 0.28);
  check('开关使用回弹曲线', switchStyle.fn.includes('1.56'));
  const revealDur = await page.evaluate(() => {
    const el = document.querySelector('.settings-card.reveal');
    return el ? parseFloat(getComputedStyle(el).transitionDuration) : 0;
  });
  check('滚动显现带平滑过渡（≥0.4s）', revealDur >= 0.4);
  await page.locator('[data-frame-rate="120"]').click();
  await page.waitForTimeout(250);
  check('帧率切换 120 生效', await page.evaluate(() => document.documentElement.dataset.fps === '120'));
  await page.locator('[data-frame-rate="auto"]').click();
  await page.waitForTimeout(250);
  const autoFps = await page.evaluate(() => document.documentElement.dataset.fps);
  check('帧率切换自动（跟随系统）生效', ['60', '90', '120', '144'].includes(autoFps));
  check('流畅度自测按钮存在', await page.locator('[data-action="fps-test"]').count() === 1);
  check('关于页展示实际应用图标', await page.locator('.about-icon').count() === 1);

  console.log('🖼 头像');
  await page.locator('[data-action="change-avatar"]').click();
  await page.waitForTimeout(200);
  check('头像弹窗打开（含 emoji 库）', await page.locator('.avatar-grid .avatar-option').count() >= 16);
  await page.locator('.avatar-option[data-avatar="🦊"]').click();
  await page.locator('.modal-foot [data-action="save"]').click();
  await page.waitForTimeout(250);
  const avatarVal = await page.evaluate(() => window.Sugar.store.state.settings.avatar);
  check('头像保存为 🦊', avatarVal === '🦊');
  check('顶栏显示新头像', (await page.locator('#topbar [data-nav="settings"]').innerText()).includes('🦊'));
  check('设备卡片显示新头像', (await page.locator('.device-card').innerText()).includes('🦊'));
  await page.locator('[data-action="change-avatar"]').click();
  await page.waitForTimeout(200);
  check('头像弹窗含自绘 SVG 头像区', await page.locator('.avatar-option[data-avatar="svg:cat"]').count() === 1);
  await page.locator('.avatar-option[data-avatar="svg:cat"]').click();
  await page.locator('.modal-foot [data-action="save"]').click();
  await page.waitForTimeout(250);
  const avatarSvg = await page.evaluate(() => window.Sugar.store.state.settings.avatar);
  check('自绘 SVG 头像保存为 svg:cat', avatarSvg === 'svg:cat');
  check('顶栏显示 SVG 头像', await page.locator('#topbar [data-nav="settings"] svg.ico-avatar').count() === 1);
  await page.locator('[data-action="change-avatar"]').click();
  await page.waitForTimeout(200);
  await page.locator('.modal-foot [data-action="reset"]').click();
  await page.locator('.modal-foot [data-action="save"]').click();
  await page.waitForTimeout(250);
  const avatarReset = await page.evaluate(() => window.Sugar.store.state.settings.avatar);
  check('恢复默认头像生效', avatarReset === null);
  await page.locator('[data-action="change-avatar"]').click();
  await page.waitForTimeout(200);
  await page.setInputFiles('#avatar-file', {
    name: 'avatar.png',
    mimeType: 'image/png',
    buffer: Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64')
  });
  await page.waitForTimeout(400);
  await page.locator('.modal-foot [data-action="save"]').click();
  await page.waitForTimeout(250);
  const avatarImg = await page.evaluate(() => window.Sugar.store.state.settings.avatar);
  check('自定义图片上传并压缩保存', typeof avatarImg === 'string' && avatarImg.startsWith('data:image/jpeg'));
  check('顶栏显示图片头像', await page.locator('#topbar [data-nav="settings"] img.avatar').count() === 1);
  await page.locator('[data-action="change-avatar"]').click();
  await page.waitForTimeout(200);
  await page.locator('.modal-foot [data-action="reset"]').click();
  await page.locator('.modal-foot [data-action="save"]').click();
  await page.waitForTimeout(200);

  console.log('📥 导入弹窗');
  await page.evaluate(() => window.Sugar.ui.modal.openImport());
  await page.waitForTimeout(200);
  await page.locator('#import-text').fill('数学\n1.口算 2 页\n2.订正错题\n语文\n1.背诵古诗');
  await page.locator('[data-action="preview"]').click();
  await page.waitForTimeout(200);
  const previewItems = await page.locator('.preview-list .p-item').count();
  check('预览解析出 3 项', previewItems === 3, '实际 ' + previewItems);
  await page.locator('[data-action="append"]').click();
  await page.waitForTimeout(250);
  await page.evaluate(() => window.App.navigate('home'));
  await page.waitForTimeout(200);
  const totalAfter = await page.locator('.task-card').count();
  check('追加导入后任务增加 3 项', totalAfter === 12, '实际 ' + totalAfter);
  check('弹窗已关闭', (await page.locator('.modal-mask').count()) === 0);

  console.log('💻 响应式布局');
  for (const [w, h, nav] of [[768, 1024, '.top-tabs'], [1024, 900, '.sidebar'], [1440, 900, '.sidebar'], [1700, 1000, '.right-panel']]) {
    await page.setViewportSize({ width: w, height: h });
    await page.waitForTimeout(250);
    const o = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    check(w + 'px 无横向溢出', o <= 0, '溢出 ' + o + 'px');
    const visible = await page.isVisible(nav);
    check(w + 'px 显示 ' + nav, visible);
  }

  check('无页面 JS 错误', errors.length === 0, errors.join(' | '));

  console.log('\n通过 ' + passed + ' 项，失败 ' + failed + ' 项');
  await browser.close();
  server.close();
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
