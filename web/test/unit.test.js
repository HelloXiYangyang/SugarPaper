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

const subjects = [
  { name: '数学' }, { name: '语文' }, { name: '英语' },
  { name: '物理' }, { name: '化学' }
];

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('  ✅ ' + name);
  } catch (e) {
    console.error('  ❌ ' + name);
    console.error('     ' + e.message);
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

console.log('\n共 ' + passed + ' 项测试通过' + (process.exitCode ? '（存在失败）' : ''));
