/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 单元测试（Node 运行：node test/unit.test.js） */
'use strict';

const assert = require('assert');
const path = require('path');
const parser = require(path.join(__dirname, '..', 'js', 'parser.js'));
const stats = require(path.join(__dirname, '..', 'js', 'stats.js'));
const account = require(path.join(__dirname, '..', 'js', 'account.js'));
const syncmod = require(path.join(__dirname, '..', 'js', 'sync.js'));
const md = require(path.join(__dirname, '..', 'js', 'markdown.js'));
const report = require(path.join(__dirname, '..', 'js', 'report.js'));
const util = require(path.join(__dirname, '..', 'js', 'util.js'));
const teacher = require(path.join(__dirname, '..', 'js', 'teacher.js'));

const subjects = [
  { name: '数学' }, { name: '语文' }, { name: '英语' },
  { name: '物理' }, { name: '化学' }
];

let passed = 0;
const pending = [];
function test(name, fn) {
  try {
    const r = fn();
    if (r && typeof r.then === 'function') {
      pending.push(r.then(() => {
        passed++;
        console.log('  ✅ ' + name);
      }).catch((e) => {
        console.error('  ❌ ' + name);
        console.error('     ' + (e && e.message ? e.message : e));
        process.exitCode = 1;
      }));
    } else {
      passed++;
      console.log('  ✅ ' + name);
    }
  } catch (e) {
    console.error('  ❌ ' + name);
    console.error('     ' + (e && e.message ? e.message : e));
    process.exitCode = 1;
  }
}

console.log('📝 解析器测试');

test('解析典型老师消息：科目 + 编号 + 子行', () => {
  const text =
    '数学\n1.试卷一张\n2.默写平行四边形判定方法\n写在一张纸上 周一收\n' +
    '语文\n1.背《昆虫记》讲义\n自己印的';
  const tasks = parser.parse(text, subjects);
  assert.strictEqual(tasks.length, 3);
  assert.strictEqual(tasks[0].subject, '数学');
  assert.strictEqual(tasks[0].title, '试卷一张');
  assert.strictEqual(tasks[1].title, '默写平行四边形判定方法');
  assert.strictEqual(tasks[1].subtitle, '写在一张纸上 周一收');
  assert.strictEqual(tasks[2].subject, '语文');
  assert.strictEqual(tasks[2].title, '背《昆虫记》讲义');
  assert.strictEqual(tasks[2].subtitle, '自己印的');
});

test('识别多种编号符号：1、① - •', () => {
  const text = '英语\n1、默写单词\n①背诵课文\n- 完成练习册';
  const tasks = parser.parse(text, subjects);
  assert.strictEqual(tasks.length, 3);
  assert.deepStrictEqual(tasks.map((t) => t.title), ['默写单词', '背诵课文', '完成练习册']);
});

test('无科目时兜底为“默认”', () => {
  const tasks = parser.parse('1.完成作业\n2.预习新课', subjects);
  assert.strictEqual(tasks.length, 2);
  assert.ok(tasks.every((t) => t.subject === '默认'));
});

test('无结构文本整段视为一条任务', () => {
  const tasks = parser.parse('明天交数学练习册', subjects);
  assert.strictEqual(tasks.length, 1);
  assert.strictEqual(tasks[0].title, '明天交数学练习册');
});

test('提取截止日期：今天/明天/后天/6月30日/周六', () => {
  const now = new Date();
  const today = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
  const t1 = parser.parse('1.交作业（今天）', subjects)[0];
  assert.strictEqual(t1.dueDate, today);
  const t2 = parser.parse('1.交作业（明天）', subjects)[0];
  assert.ok(t2.dueDate > today);
  const t3 = parser.parse('1.6月30日交卷', subjects)[0];
  assert.match(t3.dueDate, /^\d{4}-06-30$/);
  const t4 = parser.parse('1.周六考试', subjects)[0];
  assert.ok(t4.dueDate >= today);
});

test('提取优先级关键词', () => {
  assert.strictEqual(parser.parse('1.重要通知必做', subjects)[0].priority, 2);
  assert.strictEqual(parser.parse('1.选做题目', subjects)[0].priority, 0);
  assert.strictEqual(parser.parse('1.普通作业', subjects)[0].priority, 1);
});

test('子行也能补充截止日期与优先级', () => {
  const tasks = parser.parse('数学\n1.试卷一张\n周一必须交', subjects);
  assert.strictEqual(tasks[0].subtitle, '周一必须交');
  assert.ok(tasks[0].dueDate);
  assert.strictEqual(tasks[0].priority, 2);
});

test('解析中文数字编号：一、二、三', () => {
  const tasks = parser.parse('数学\n一、试卷一张\n二、默写判定方法\n三、订正错题', subjects);
  assert.strictEqual(tasks.length, 3);
  assert.strictEqual(tasks[0].title, '试卷一张');
  assert.strictEqual(tasks[1].title, '默写判定方法');
});

test('任务类型识别：打卡 / 背诵 / 书面（v0.17.0）', () => {
  assert.strictEqual(parser.detectTaskType('每日英语打卡'), 'checkin');
  assert.strictEqual(parser.detectTaskType('背诵古诗三首'), 'recite');
  assert.strictEqual(parser.detectTaskType('试卷一张'), 'written');
  const tasks = parser.parse('语文\n1.背诵《望岳》\n英语\n1.每日打卡', subjects);
  assert.strictEqual(tasks[0].taskType, 'recite');
  assert.strictEqual(tasks[1].taskType, 'checkin');
});

test('parseDetailed 返回未解析行提示（导入纠错）', () => {
  const d = parser.parseDetailed('数学\n（无编号的零散行）\n1.试卷一张', subjects);
  assert.strictEqual(d.tasks.length, 1);
  assert.ok(d.skipped.includes('（无编号的零散行）'));
  assert.ok(d.warnings.length >= 1);
});

test('解析待办清单 - [ ] / - [x]（v0.20.0）', () => {
  const tasks = parser.parse('数学\n- [ ] 口算 2 页\n- [x] 订正错题', subjects);
  assert.strictEqual(tasks.length, 2);
  assert.strictEqual(tasks[0].isCompleted, false);
  assert.strictEqual(tasks[1].isCompleted, true);
});

console.log('\n📝 Markdown 渲染测试（v0.20.0）');

test('Markdown 转义 HTML 防注入', () => {
  const html = md.render('<script>alert(1)</script>');
  assert.ok(!html.includes('<script>alert'));
  assert.ok(html.includes('&lt;script&gt;'));
});

test('标题/加粗/列表/待办清单/链接渲染', () => {
  const html = md.render('# 明天安排\n\n- [ ] 数学口算\n- [x] 英语打卡\n\n**加粗** [链接](https://example.com)');
  assert.ok(html.includes('<h1>明天安排</h1>'));
  assert.ok(html.includes('<li class="md-check">'));
  assert.ok(html.includes('<li class="md-check checked">'));
  assert.ok(html.includes('<strong>加粗</strong>'));
  assert.ok(html.includes('<a href="https://example.com"'));
});

test('行内代码与引用渲染', () => {
  const html = md.render('> 老师通知\n\n使用 `Ctrl+N` 导入');
  assert.ok(html.includes('<blockquote>老师通知</blockquote>'));
  assert.ok(html.includes('<code>Ctrl+N</code>'));
});

console.log('\n📊 统计报告卡片测试（v0.21.0）');

test('报告卡片 SVG 包含核心元素', () => {
  const s = {
    total: 10, completed: 6, active: 4, rate: 60, onTimeRate: 80, streak: 3,
    focusTodayMinutes: 50, focusWeekMinutes: 120, focusTotalMinutes: 300, focusStreak: 2,
    topUnfinished: [{ name: '数学', count: 2, weight: 6 }]
  };
  const svg = report.buildReportSvg(s, '本周', '2026-08-07', () => '#F4A8C6');
  assert.ok(svg.startsWith('<svg'));
  assert.ok(svg.includes('糖纸 · SugarPaper 统计报告'));
  assert.ok(svg.includes('60%'));
  assert.ok(svg.includes('80%'));
  assert.ok(svg.includes('数学'));
  assert.ok(svg.includes('2 项'));
  assert.ok(svg.includes('专注（番茄钟）'));
});

test('报告卡片对特殊字符转义', () => {
  const s = {
    total: 1, completed: 0, active: 1, rate: 0, onTimeRate: null, streak: 0,
    focusTodayMinutes: 0, focusWeekMinutes: 0, focusTotalMinutes: 0, focusStreak: 0,
    topUnfinished: [{ name: '<b>数学</b>', count: 1, weight: 1 }]
  };
  const svg = report.buildReportSvg(s, '全部', '2026-08-07');
  assert.ok(!svg.includes('<b>数学</b>'));
  assert.ok(svg.includes('&lt;b&gt;数学&lt;/b&gt;'));
});

console.log('\n⏰ 提醒时间工具测试（v0.22.0）');

test('parseClock 解析与非法值', () => {
  assert.strictEqual(util.parseClock('20:00'), 1200);
  assert.strictEqual(util.parseClock('07:30'), 450);
  assert.strictEqual(util.parseClock('25:00'), null);
  assert.strictEqual(util.parseClock('abc'), null);
});

test('inReminderWindow 窗口判断', () => {
  assert.strictEqual(util.inReminderWindow(1200, '20:00', 1320), true);
  assert.strictEqual(util.inReminderWindow(1319, '20:00', 1320), true);
  assert.strictEqual(util.inReminderWindow(1320, '20:00', 1320), false);
  assert.strictEqual(util.inReminderWindow(420, '07:00'), true); // 默认 2 小时窗口
  assert.strictEqual(util.inReminderWindow(540, '07:00'), false);
  assert.strictEqual(util.inReminderWindow(500, 'bad'), false);
});

console.log('\n📅 日历标记测试（v0.24.0）');

test('dayMarkers：考试便签与专注分钟', () => {
  const fmt = (d) => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  const today = fmt(new Date());
  const yest = new Date();
  yest.setDate(yest.getDate() - 1);
  const yesterday = fmt(yest);
  const notes = [
    { id: 'n1', title: '数学期末考', content: '', tags: ['考试安排'], remindAt: new Date().toISOString(), isDeleted: false },
    { id: 'n2', title: '普通便签', content: '明天带彩纸', tags: [], remindAt: null, isDeleted: false }
  ];
  const sessions = [
    { id: 's1', endAt: new Date().toISOString(), minutes: 45, completed: true },
    { id: 's2', endAt: yest.toISOString(), minutes: 30, completed: true }
  ];
  const mk = stats.dayMarkers(notes, sessions, today);
  assert.strictEqual(mk.exam, true);
  assert.strictEqual(mk.focusMin, 45);
  const mk2 = stats.dayMarkers(notes, sessions, yesterday);
  assert.strictEqual(mk2.exam, false);
  assert.strictEqual(mk2.focusMin, 30);
});

console.log('\n🧑‍🏫 教师模式测试（v0.25.0）');

test('buildHomeworkText 按科目分组生成标准格式', () => {
  const text = teacher.buildHomeworkText([
    { subject: '数学', title: '试卷一张', dueDate: '2026-08-08', priority: 1 },
    { subject: '数学', title: '默写判定方法', priority: 2 },
    { subject: '语文', title: '背诵《望岳》', priority: 0 }
  ]);
  const lines = text.split('\n');
  assert.strictEqual(lines[0], '数学');
  assert.strictEqual(lines[1], '1.试卷一张（8月8日交）');
  assert.strictEqual(lines[2], '2.默写判定方法（必做）');
  assert.strictEqual(lines[3], '语文');
  assert.strictEqual(lines[4], '1.背诵《望岳》（选做）');
});

test('识别小初高 16 科默认词表（体育与健康/通用技术/综合实践活动等）', () => {
  const text =
    '体育与健康\n1.跑步 2 圈\n' +
    '通用技术\n1.完成小木工作品\n' +
    '综合实践活动\n1.社区服务记录\n' +
    '信息技术\n1.完成编程作业';
  const tasks = parser.parse(text, []);
  assert.deepStrictEqual(tasks.map((t) => t.subject),
    ['体育与健康', '通用技术', '综合实践活动', '信息技术']);
});

test('常见别名：道法 / 体育 / 信息 也能识别为科目行', () => {
  const tasks = parser.parse('道法\n1.背诵宪法要点\n体育\n1.跳绳 200 个', []);
  assert.deepStrictEqual(tasks.map((t) => t.subject), ['道法', '体育']);
});

console.log('\n📊 统计引擎测试');

function mkState() {
  const iso = (daysAgo, hour) => {
    const d = new Date();
    d.setDate(d.getDate() - daysAgo);
    d.setHours(hour || 10, 0, 0, 0);
    return d.toISOString();
  };
  return {
    tasks: [
      { id: 'a', subject: '数学', title: 'A', isCompleted: true, isDeleted: false, createdAt: iso(0), completedAt: iso(0) },
      { id: 'b', subject: '数学', title: 'B', isCompleted: true, isDeleted: false, createdAt: iso(1), completedAt: iso(1) },
      { id: 'c', subject: '语文', title: 'C', isCompleted: true, isDeleted: false, createdAt: iso(1), completedAt: iso(1) },
      { id: 'd', subject: '英语', title: 'D', isCompleted: false, isDeleted: false, createdAt: iso(2) },
      { id: 'e', subject: '物理', title: 'E', isCompleted: false, isDeleted: true, createdAt: iso(2) },
      { id: 'f', subject: '英语', title: 'F', isCompleted: false, isDeleted: false, createdAt: iso(3) }
    ]
  };
}

test('整体进度：总数/完成/未完成/完成率', () => {
  const s = stats.compute(mkState(), 'all');
  assert.strictEqual(s.total, 5); // 排除软删除
  assert.strictEqual(s.completed, 3);
  assert.strictEqual(s.active, 2);
  assert.strictEqual(s.rate, 60);
});

test('每日趋势为最近 7 天且今天有完成', () => {
  const s = stats.compute(mkState(), 'week');
  assert.strictEqual(s.dailyTrend.length, 7);
  assert.ok(s.dailyTrend.some((d) => d.isToday && d.count === 1));
});

test('连续完成天数计算', () => {
  const s = stats.compute(mkState(), 'all');
  assert.ok(s.streak >= 1);
});

test('科目分布与高频未完成科目', () => {
  const s = stats.compute(mkState(), 'all');
  const math = s.subjectDist.find((x) => x.name === '数学');
  assert.strictEqual(math.count, 2);
  assert.ok(s.topUnfinished.some((x) => x.name === '英语' && x.count === 2));
});

test('周趋势与月趋势结构', () => {
  const s = stats.compute(mkState(), 'all');
  assert.strictEqual(s.weeklyTrend.length, 8);
  assert.ok(s.monthTrend.length >= 28);
});

console.log('\n🍅 专注统计测试（v0.15.0）');

function mkFocusState() {
  const iso = (daysAgo) => {
    const d = new Date();
    d.setDate(d.getDate() - daysAgo);
    d.setHours(0, 0, 0, 0);
    return d.toISOString();
  };
  return {
    tasks: [],
    focusSessions: [
      { id: '1', taskId: 'a', subject: '数学', endAt: iso(0), minutes: 25, completed: true, source: 'pomodoro' },
      { id: '2', subject: '语文', endAt: iso(0), minutes: 25, completed: true, source: 'pomodoro' },
      { id: '3', subject: '数学', endAt: iso(1), minutes: 50, completed: true, source: 'pomodoro' },
      { id: '4', subject: '英语', endAt: iso(3), minutes: 25, completed: true, source: 'countdown' },
      { id: '5', subject: '数学', endAt: iso(3), minutes: 25, completed: false, source: 'pomodoro' }
    ]
  };
}

test('专注统计：今日/累计分钟与番茄数（未完成不计）', () => {
  const s = stats.compute(mkFocusState(), 'week');
  assert.strictEqual(s.focusTodayMinutes, 50);
  assert.strictEqual(s.focusTodayCount, 2);
  assert.ok(s.focusWeekMinutes >= 50 && s.focusWeekMinutes <= 125);
  assert.strictEqual(s.focusTotalCount, 4);
  assert.strictEqual(s.focusTotalMinutes, 125);
});

test('专注统计：连续专注天数与科目聚合', () => {
  const s = stats.compute(mkFocusState(), 'week');
  assert.ok(s.focusStreak >= 2);
  assert.strictEqual(s.focusSubjectTop[0].name, '数学');
  assert.strictEqual(s.focusSubjectTop[0].minutes, 75); // 25（今日）+ 50（昨日）；未完成会话不计
});

test('准时率：完成日 ≤ 截止日 记为准时（v0.17.0）', () => {
  const dateStr = (offset) => {
    const d = new Date();
    d.setDate(d.getDate() + offset);
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  };
  const iso = (offset) => {
    const d = new Date();
    d.setDate(d.getDate() + offset);
    d.setHours(18, 0, 0, 0);
    return d.toISOString();
  };
  const state = {
    tasks: [
      { id: 'a', subject: '数学', isCompleted: true, isDeleted: false, dueDate: dateStr(-1), completedAt: iso(-1) },
      { id: 'b', subject: '语文', isCompleted: true, isDeleted: false, dueDate: dateStr(-1), completedAt: iso(0) },
      { id: 'c', subject: '英语', isCompleted: true, isDeleted: false, dueDate: null, completedAt: iso(-1) },
      { id: 'd', subject: '物理', isCompleted: false, isDeleted: false, dueDate: dateStr(0) }
    ]
  };
  const s = stats.compute(state, 'all');
  assert.strictEqual(s.dueCompletedCount, 2);
  assert.strictEqual(s.onTimeCount, 1);
  assert.strictEqual(s.onTimeRate, 50);
});

test('科目欠账排行按未完成 + 逾期天数加权（v0.17.0）', () => {
  const dateStr = (offset) => {
    const d = new Date();
    d.setDate(d.getDate() + offset);
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  };
  const state = {
    tasks: [
      { id: 'a', subject: '数学', isCompleted: false, isDeleted: false, dueDate: dateStr(-2) },
      { id: 'b', subject: '数学', isCompleted: false, isDeleted: false, dueDate: null },
      { id: 'c', subject: '英语', isCompleted: false, isDeleted: false, dueDate: null },
      { id: 'd', subject: '物理', isCompleted: false, isDeleted: false, dueDate: dateStr(-3) }
    ]
  };
  const s = stats.compute(state, 'all');
  assert.strictEqual(s.topUnfinished[0].name, '物理');
  assert.strictEqual(s.topUnfinished[1].name, '数学');
  assert.strictEqual(s.topUnfinished[2].name, '英语');
});

console.log('\n🔑 账号与同步测试（v0.16.0）');

test('助记词往返：熵 → 词 → 熵一致，且全部在词表中', () => {
  const entropy = new Uint8Array(16);
  for (let i = 0; i < 16; i++) entropy[i] = i + 1;
  const words = account.entropyToMnemonic(entropy);
  assert.strictEqual(words.length, 12);
  assert.ok(words.every((w) => account.WORDS.includes(w)));
  const back = account.mnemonicToEntropy(words);
  assert.deepStrictEqual(Array.from(back), Array.from(entropy));
});

test('助记词生成确定性：相同熵 → 相同助记词', () => {
  const e1 = new Uint8Array(16).fill(7);
  const e2 = new Uint8Array(16).fill(7);
  assert.deepStrictEqual(account.entropyToMnemonic(e1), account.entropyToMnemonic(e2));
});

test('无效助记词被拒绝', () => {
  assert.throws(() => account.mnemonicToEntropy(['zzzz', 'x', 'y', 'w', 'v', 'u', 't', 's', 'r', 'q', 'p', 'o']));
  assert.throws(() => account.normalizeMnemonic('bob yac'));
});

test('账号创建与恢复：同一助记词得到同一公钥', async () => {
  const created = await account.createAccount();
  const restored = await account.restoreAccount(created.mnemonic.join(' '));
  assert.strictEqual(restored.kp.pubkey, created.kp.pubkey);
  assert.strictEqual(restored.seed.length, 32);
});

test('Ed25519 公钥推导符合 RFC 8032 测试向量', async () => {
  const seed = account.hexToBytes('9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60');
  const kp = await account.seedToKeyPair(seed);
  assert.strictEqual(
    account.bytesToHex(kp.publicKeyRaw),
    'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a'
  );
});

test('Nostr 公钥为 64 位 hex（跨端互通，公共中继 NIP-01）', async () => {
  const m = ['bac', 'bab', 'bac', 'bab', 'bac', 'bab', 'bac', 'bab', 'bac', 'bab', 'bac', 'bab'];
  const seed = await account.mnemonicToSeed(m);
  const kp = await account.seedToKeyPair(seed);
  const hex = account.bytesToHex(kp.publicKeyRaw);
  assert.match(hex, /^[a-f0-9]{64}$/);
  // 与安卓端同种子推导结果一致的互通校验向量
  assert.strictEqual(hex, '9695c460e97e86ac847ef972632a3fb8a2c503fd29efcc42d7a875ad27929316');
});

test('端到端加密解密往返', async () => {
  const created = await account.createAccount();
  const env = await account.encryptData({ tasks: [{ id: 'a', title: '数学作业' }] }, created.seed);
  const plain = await account.decryptData(env, created.seed);
  assert.strictEqual(plain.tasks[0].title, '数学作业');
});

test('签名验签：正确签名通过，篡改后拒绝', async () => {
  const created = await account.createAccount();
  const data = new TextEncoder().encode('hello-sugar');
  const sig = await account.signBytes(created.kp.privateKey, data, 'b64');
  assert.strictEqual(await account.verifyBytes(created.kp.pubkey, data, sig, false), true);
  const bad = new TextEncoder().encode('hello-sugaX');
  assert.strictEqual(await account.verifyBytes(created.kp.pubkey, bad, sig, false), false);
});

test('合并快照：后写覆盖 + 保留墓碑 + 补全新记录', () => {
  const local = {
    tasks: [
      { id: 'a', title: '旧', updatedAt: '2026-01-01T00:00:00Z' },
      { id: 'b', title: '本机新增', updatedAt: '2026-01-02T00:00:00Z' }
    ],
    notes: [{ id: 'n1', content: 'x', updatedAt: '2026-01-01T00:00:00Z' }],
    focusSessions: []
  };
  const remote = {
    tasks: [
      { id: 'a', title: '新', updatedAt: '2026-01-03T00:00:00Z' },
      { id: 'c', title: '远端新增', updatedAt: '2026-01-02T00:00:00Z' },
      { id: 'd', title: '已删除', isDeleted: true, updatedAt: '2026-01-02T00:00:00Z' }
    ],
    notes: [{ id: 'n1', content: 'y', updatedAt: '2026-01-02T00:00:00Z' }],
    focusSessions: []
  };
  const merged = syncmod.mergeSnapshot(local, remote);
  assert.strictEqual(merged.tasks.length, 4);
  assert.strictEqual(merged.tasks.find((t) => t.id === 'a').title, '新');
  assert.ok(merged.tasks.find((t) => t.id === 'd').isDeleted);
  assert.ok(merged.tasks.some((t) => t.id === 'b'));
  assert.strictEqual(merged.notes[0].content, 'y');
  assert.strictEqual(merged.changed, true);
});

Promise.all(pending).then(() => {
  console.log('\n共 ' + passed + ' 项测试通过' + (process.exitCode ? '（存在失败）' : ''));
});
