/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 文档同步校验：node test/verify_docs.js
   确认 16 科默认学科 + 头像 + 动态动画已同步到 Web 代码 / PRD / README */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const SUBJECTS = [
  '语文', '数学', '英语', '物理', '化学', '生物', '历史', '地理', '政治',
  '体育与健康', '音乐', '美术', '信息技术', '通用技术', '劳动', '综合实践活动'
];

function read(p) {
  return fs.readFileSync(path.join(ROOT, p), 'utf-8');
}

const targets = [
  { name: 'store.js 默认科目', file: 'web/js/store.js', min: 1 },
  { name: 'parser.js 词表', file: 'web/js/parser.js', min: 1 },
  { name: 'PRD v4.1', file: '🧁 糖纸 · SugarPaper —— 全平台作业管理助手.md', min: 2 },
  { name: 'README', file: 'README.md', min: 1 }
];

let failed = 0;
for (const t of targets) {
  const content = read(t.file);
  const missing = SUBJECTS.filter((s) => content.split(s).length - 1 < t.min);
  if (missing.length) {
    failed++;
    console.error('  ❌ ' + t.name + ' 缺少：' + missing.join('、'));
  } else {
    console.log('  ✅ ' + t.name + ' 16 科齐全');
  }
}

const prd = read('🧁 糖纸 · SugarPaper —— 全平台作业管理助手.md');
if (!prd.includes('v4.1 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.1 变更记录'); }
else console.log('  ✅ PRD 含 v4.1 变更记录');
if (!prd.includes('默认学科清单')) { failed++; console.error('  ❌ PRD 缺少默认学科清单说明'); }
else console.log('  ✅ PRD 含默认学科清单说明');

const readme = read('README.md');
if (!readme.includes('v0.7.1')) { failed++; console.error('  ❌ README 缺少 v0.7.1 版本日志'); }
else console.log('  ✅ README 含 v0.7.1 版本日志');

console.log('🖼 头像功能同步检查');
if (!read('web/js/store.js').includes('avatar')) { failed++; console.error('  ❌ store.js 缺少 avatar 字段'); }
else console.log('  ✅ store.js 含 avatar 字段');
if (!prd.includes('v4.2 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.2 变更记录'); }
else console.log('  ✅ PRD 含 v4.2 变更记录');
if (!prd.includes('AppSettings.avatar') && !prd.includes('头像：null=默认')) { failed++; console.error('  ❌ PRD 数据模型缺少 avatar 字段'); }
else console.log('  ✅ PRD 数据模型含 avatar 字段');
if (!prd.includes('内置 emoji 头像库')) { failed++; console.error('  ❌ PRD 缺少头像规格说明'); }
else console.log('  ✅ PRD 含头像规格说明');
if (!readme.includes('v0.8.0')) { failed++; console.error('  ❌ README 缺少 v0.8.0 版本日志'); }
else console.log('  ✅ README 含 v0.8.0 版本日志');
if (!readme.includes('头像')) { failed++; console.error('  ❌ README 缺少头像说明'); }
else console.log('  ✅ README 含头像说明');

console.log('🎬 动态动画同步检查');
const css = read('web/css/app.css');
for (const cls of ['view-enter-left', 'view-enter-right', 'view-enter-up', 'prefers-reduced-motion']) {
  if (!css.includes(cls)) { failed++; console.error('  ❌ app.css 缺少 ' + cls); }
}
if (!css.includes('prefers-reduced-motion')) { failed++; console.error('  ❌ app.css 缺少减弱动效支持'); }
else console.log('  ✅ app.css 含方向过渡 / 卡片入场 / 减弱动效');
if (!prd.includes('v4.3 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.3 变更记录'); }
else console.log('  ✅ PRD 含 v4.3 变更记录');
if (!prd.includes('方向感知')) { failed++; console.error('  ❌ PRD 缺少方向感知过渡规范'); }
else console.log('  ✅ PRD 含方向感知过渡规范');
if (!prd.includes('动态动画统一规范')) { failed++; console.error('  ❌ PRD 缺少动态动画统一规范'); }
else console.log('  ✅ PRD 含动态动画统一规范');
if (!readme.includes('v0.9.0')) { failed++; console.error('  ❌ README 缺少 v0.9.0 版本日志'); }
else console.log('  ✅ README 含 v0.9.0 版本日志');
if (!readme.includes('动态动画')) { failed++; console.error('  ❌ README 缺少动态动画说明'); }
else console.log('  ✅ README 含动态动画说明');

console.log('🎚 动画开关同步检查');
if (!read('web/js/store.js').includes('animations')) { failed++; console.error('  ❌ store.js 缺少 animations 字段'); }
else console.log('  ✅ store.js 含 animations 字段');
if (!css.includes('no-anim')) { failed++; console.error('  ❌ app.css 缺少 no-anim 动画总开关'); }
else console.log('  ✅ app.css 含 no-anim 动画总开关');
if (!css.includes('.reveal')) { failed++; console.error('  ❌ app.css 缺少滚动显现 reveal'); }
else console.log('  ✅ app.css 含滚动显现 reveal');
if (!prd.includes('v4.4 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.4 变更记录'); }
else console.log('  ✅ PRD 含 v4.4 变更记录');
if (!prd.includes('动画总开关')) { failed++; console.error('  ❌ PRD 缺少动画总开关规范'); }
else console.log('  ✅ PRD 含动画总开关规范');
if (!prd.includes('组件微动画清单')) { failed++; console.error('  ❌ PRD 缺少组件微动画清单'); }
else console.log('  ✅ PRD 含组件微动画清单');
if (!readme.includes('v0.10.0')) { failed++; console.error('  ❌ README 缺少 v0.10.0 版本日志'); }
else console.log('  ✅ README 含 v0.10.0 版本日志');
if (!readme.includes('动画开关')) { failed++; console.error('  ❌ README 缺少动画开关说明'); }
else console.log('  ✅ README 含动画开关说明');

console.log('✨ 丝滑过渡与图表加载同步检查');
if (!css.includes('cubic-bezier(.34, 1.56')) { failed++; console.error('  ❌ app.css 缺少开关弹簧曲线'); }
else console.log('  ✅ app.css 含开关弹簧过渡');
if (!css.includes('slice-in')) { failed++; console.error('  ❌ app.css 缺少饼图扇区绽放动画'); }
else console.log('  ✅ app.css 含饼图扇区绽放动画');
if (!css.includes('pie-canvas')) { failed++; console.error('  ❌ app.css 缺少饼图加载环'); }
else console.log('  ✅ app.css 含饼图加载环');
if (!prd.includes('v4.5 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.5 变更记录'); }
else console.log('  ✅ PRD 含 v4.5 变更记录');
if (!prd.includes('扇区依次绽放')) { failed++; console.error('  ❌ PRD 缺少饼图加载动画规范'); }
else console.log('  ✅ PRD 含饼图加载动画规范');
if (!prd.includes('弹簧')) { failed++; console.error('  ❌ PRD 缺少开关弹簧过渡规范'); }
else console.log('  ✅ PRD 含开关弹簧过渡规范');
if (!readme.includes('v0.11.0')) { failed++; console.error('  ❌ README 缺少 v0.11.0 版本日志'); }
else console.log('  ✅ README 含 v0.11.0 版本日志');

console.log('⚡ 帧率与性能同步检查');
if (!read('web/js/store.js').includes('frameRate')) { failed++; console.error('  ❌ store.js 缺少 frameRate 字段'); }
else console.log('  ✅ store.js 含 frameRate 字段');
if (!css.includes('data-fps')) { failed++; console.error('  ❌ app.css 缺少帧率档位样式'); }
else console.log('  ✅ app.css 含帧率档位样式');
if (!css.includes('transition: opacity .45s ease, transform .45s cubic-bezier(.22, .9, .36, 1)')) { failed++; console.error('  ❌ app.css 滚动显现缺少平滑过渡'); }
else console.log('  ✅ app.css 滚动显现含平滑过渡');
if (!prd.includes('v4.6 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.6 变更记录'); }
else console.log('  ✅ PRD 含 v4.6 变更记录');
if (!prd.includes('帧率模式')) { failed++; console.error('  ❌ PRD 缺少帧率模式规范'); }
else console.log('  ✅ PRD 含帧率模式规范');
if (!prd.includes('流畅度自测')) { failed++; console.error('  ❌ PRD 缺少流畅度自测'); }
else console.log('  ✅ PRD 含流畅度自测');
if (!readme.includes('v0.12.0')) { failed++; console.error('  ❌ README 缺少 v0.12.0 版本日志'); }
else console.log('  ✅ README 含 v0.12.0 版本日志');
if (!readme.includes('帧率')) { failed++; console.error('  ❌ README 缺少帧率说明'); }
else console.log('  ✅ README 含帧率说明');

console.log('🎨 矢量图标同步检查');
if (!read('web/js/icons.js').includes('STROKE')) { failed++; console.error('  ❌ icons.js 图标库缺失'); }
else console.log('  ✅ icons.js 图标库存在');
if (!read('web/js/icons.js').includes('FILL')) { failed++; console.error('  ❌ icons.js 头像库缺失'); }
else console.log('  ✅ icons.js 头像库存在');
if (!read('web/index.html').includes('icons.js')) { failed++; console.error('  ❌ index.html 未引入 icons.js'); }
else console.log('  ✅ index.html 已引入 icons.js');
if (!read('web/js/app.js').includes('S.icons.icon')) { failed++; console.error('  ❌ app.js 未使用矢量图标'); }
else console.log('  ✅ app.js 使用矢量图标');
if (!read('web/js/app.js').includes('icon.svg')) { failed++; console.error('  ❌ 顶栏品牌 Logo 未使用应用图标'); }
else console.log('  ✅ 顶栏品牌 Logo 使用应用图标');
if (!read('web/js/ui-settings.js').includes('icon.svg')) { failed++; console.error('  ❌ 关于页未展示实际应用图标'); }
else console.log('  ✅ 关于页展示实际应用图标');
if (read('web/js/ui-settings.js').includes('AVATAR_EMOJIS') || read('web/js/ui-settings.js').includes('avatar-option')) { failed++; console.error('  ❌ 头像弹窗仍含内置 emoji 选项'); }
else console.log('  ✅ 内置 emoji 头像已移除');
if (!read('web/js/ui-settings.js').includes('#avatar-file')) { failed++; console.error('  ❌ 头像上传功能缺失'); }
else console.log('  ✅ 头像自定义上传已恢复');
if (!read('web/js/ui-settings.js').includes('avatar-upload')) { failed++; console.error('  ❌ 头像上传区未实现'); }
else console.log('  ✅ 头像上传区（点击/拖拽）已实现');
if (!read('web/js/util.js').includes('avatar-default.jpg')) { failed++; console.error('  ❌ 默认头像未指向喜羊羊图片'); }
else console.log('  ✅ 默认头像为喜羊羊图片');
if (!fs.existsSync(path.join(ROOT, 'web', 'assets', 'avatar-default.jpg'))) { failed++; console.error('  ❌ 默认头像资源缺失'); }
else console.log('  ✅ 默认头像资源存在（web/assets/avatar-default.jpg）');
if (!read('web/icon.svg').includes('<svg')) { failed++; console.error('  ❌ PWA 图标文件缺失'); }
else console.log('  ✅ PWA 图标文件存在（保留原糖果样式）');
if (!prd.includes('v4.7 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.7 变更记录'); }
else console.log('  ✅ PRD 含 v4.7 变更记录');
if (!prd.includes('矢量图标')) { failed++; console.error('  ❌ PRD 缺少矢量图标规范'); }
else console.log('  ✅ PRD 含矢量图标规范');
if (!readme.includes('v0.13.0')) { failed++; console.error('  ❌ README 缺少 v0.13.0 版本日志'); }
else console.log('  ✅ README 含 v0.13.0 版本日志');
if (!readme.includes('矢量图标')) { failed++; console.error('  ❌ README 缺少矢量图标说明'); }
else console.log('  ✅ README 含矢量图标说明');
if (!prd.includes('v4.8 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.8 变更记录'); }
else console.log('  ✅ PRD 含 v4.8 变更记录');
if (!prd.includes('头像（v4.11 收敛）')) { failed++; console.error('  ❌ PRD 缺少头像收敛规格'); }
else console.log('  ✅ PRD 含头像收敛规格');
if (!readme.includes('v0.13.3')) { failed++; console.error('  ❌ README 缺少 v0.13.3 版本日志'); }
else console.log('  ✅ README 含 v0.13.3 版本日志');
if (!prd.includes('v4.9 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.9 变更记录'); }
else console.log('  ✅ PRD 含 v4.9 变更记录');
if (!prd.includes('中性占位')) { failed++; console.error('  ❌ PRD 缺少中性占位规格'); }
else console.log('  ✅ PRD 含中性占位规格');
if (!readme.includes('v0.13.4')) { failed++; console.error('  ❌ README 缺少 v0.13.4 版本日志'); }
else console.log('  ✅ README 含 v0.13.4 版本日志');
if (!prd.includes('v4.10 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.10 变更记录'); }
else console.log('  ✅ PRD 含 v4.10 变更记录');
if (!prd.includes('avatar-default.jpg')) { failed++; console.error('  ❌ PRD 缺少默认头像图片说明'); }
else console.log('  ✅ PRD 含默认头像图片说明');
if (!readme.includes('v0.13.5')) { failed++; console.error('  ❌ README 缺少 v0.13.5 版本日志'); }
else console.log('  ✅ README 含 v0.13.5 版本日志');
if (!prd.includes('v4.11 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.11 变更记录'); }
else console.log('  ✅ PRD 含 v4.11 变更记录');
if (!readme.includes('v0.13.6')) { failed++; console.error('  ❌ README 缺少 v0.13.6 版本日志'); }
else console.log('  ✅ README 含 v0.13.6 版本日志');
if (!prd.includes('v4.12 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.12 变更记录'); }
else console.log('  ✅ PRD 含 v4.12 变更记录');
if (!readme.includes('v0.13.7')) { failed++; console.error('  ❌ README 缺少 v0.13.7 版本日志'); }
else console.log('  ✅ README 含 v0.13.7 版本日志');
console.log('🎨 主题配色同步检查');
if (!read('web/js/store.js').includes('theme')) { failed++; console.error('  ❌ store.js 缺少 theme 字段'); }
else console.log('  ✅ store.js 含 theme 字段');
const themeCss = read('web/css/theme.css');
for (const p of ['bluegreen', 'sunshine', 'rose', 'lavender', 'mint']) {
  if (!themeCss.includes('data-palette="' + p + '"')) { failed++; console.error('  ❌ theme.css 缺少配色 ' + p); }
}
if (!themeCss.includes('data-palette')) { failed++; }
else console.log('  ✅ theme.css 含多套马卡龙配色');
if (!read('web/js/ui-settings.js').includes('theme-picker')) { failed++; console.error('  ❌ 设置页缺少主题选择器'); }
else console.log('  ✅ 设置页含主题配色选择器');
if (!prd.includes('v4.13 变更')) { failed++; console.error('  ❌ PRD 缺少 v4.13 变更记录'); }
else console.log('  ✅ PRD 含 v4.13 变更记录');
if (!prd.includes('七套平行')) { failed++; console.error('  ❌ PRD 缺少主题规格'); }
else console.log('  ✅ PRD 含主题规格（七套平行）');
if (!readme.includes('v0.14.0')) { failed++; console.error('  ❌ README 缺少 v0.14.0 版本日志'); }
else console.log('  ✅ README 含 v0.14.0 版本日志');
if (!readme.includes('七套平行')) { failed++; console.error('  ❌ README 缺少主题说明'); }
else console.log('  ✅ README 含主题说明（七套平行）');

console.log(failed ? '\n共 ' + failed + ' 处不一致 ❌' : '\n全部同步一致 ✅');
process.exit(failed ? 1 : 0);
