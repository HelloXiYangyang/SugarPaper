/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/parser.dart';
import 'package:sugarpaper/models/subject_config.dart';

void main() {
  const subjects = [
    SubjectConfig(name: '语文', colorHex: '#F4B8CE'),
    SubjectConfig(name: '数学', colorHex: '#B3D4F0'),
    SubjectConfig(name: '英语', colorHex: '#C9C7F0'),
  ];

  group('Parser.parse', () {
    test('解析科目行 + 编号条目', () {
      final r = Parser.parse('数学\n1.试卷一张\n2.默写判定方法', subjects);
      expect(r.length, 2);
      expect(r[0].subject, '数学');
      expect(r[0].title, '试卷一张');
      expect(r[1].subject, '数学');
      expect(r[1].title, '默写判定方法');
    });

    test('子行合并到上一个任务', () {
      final r = Parser.parse('语文\n1.背《昆虫记》讲义\n自己印的', subjects);
      expect(r.length, 1);
      expect(r[0].title, '背《昆虫记》讲义');
      expect(r[0].subtitle, '自己印的');
    });

    test('无科目时归入默认', () {
      final r = Parser.parse('1.交作业', const <SubjectConfig>[]);
      expect(r.length, 1);
      expect(r[0].subject, '默认');
      expect(r[0].title, '交作业');
    });

    test('优先级关键词', () {
      final r = Parser.parse('1.重点复习化学\n2.选做拓展题', const <SubjectConfig>[]);
      expect(r[0].priority, 2);
      expect(r[1].priority, 0);
    });

    test('截止日期提取（今天/明天/6月30日/周六）', () {
      expect(Parser.extractDueDate('今天交'), isNotNull);
      expect(Parser.extractDueDate('明天交'), isNotNull);
      final june30 = Parser.extractDueDate('6月30日交');
      expect(june30, isNotNull);
      expect(RegExp(r'^\d{4}-06-30$').hasMatch(june30!), isTrue);
      final sat = Parser.extractDueDate('周六交');
      expect(sat, isNotNull);
    });

    test('纯文本兜底为单任务', () {
      final r = Parser.parse('老师说明天记得带作业本', const <SubjectConfig>[]);
      expect(r.length, 1);
      expect(r[0].subject, '默认');
    });

    test('中文数字编号（v0.17.0）', () {
      final r = Parser.parse('数学\n一、试卷一张\n二、练习册 P10', subjects);
      expect(r.length, 2);
      expect(r[0].title, '试卷一张');
      expect(r[1].title, '练习册 P10');
      expect(r.every((t) => t.subject == '数学'), isTrue);
    });

    test('任务类型识别：打卡/背诵（v0.17.0）', () {
      expect(Parser.detectTaskType('每日打卡跳绳'), 'checkin');
      expect(Parser.detectTaskType('背诵古诗三首'), 'recite');
      expect(Parser.detectTaskType('试卷一张'), 'written');
    });

    test('parseDetailed 返回未解析行提示', () {
      final detail = Parser.parseDetailed(
        '数学\n这个行无法解析',
        subjects,
      );
      expect(detail.tasks.length, 0);
      expect(detail.skipped, contains('这个行无法解析'));
      expect(detail.warnings, isNotEmpty);
    });
  });
}
