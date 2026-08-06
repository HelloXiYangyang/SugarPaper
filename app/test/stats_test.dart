/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/stats_engine.dart';
import 'package:sugarpaper/models/task.dart';

Task mkTask({
  String id = 't1',
  String subject = '数学',
  String title = '作业',
  bool completed = false,
  DateTime? completedAt,
  DateTime? dueDate,
  bool deleted = false,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    subject: subject,
    title: title,
    isCompleted: completed,
    createdAt: now,
    updatedAt: now,
    completedAt: completedAt,
    dueDate: dueDate,
    isDeleted: deleted,
  );
}

void main() {
  group('StatsEngine.compute', () {
    test('基础统计：总数/完成/进行中/完成率', () {
      final now = DateTime.now();
      final tasks = [
        mkTask(id: 'a', completed: true, completedAt: now),
        mkTask(id: 'b', completed: true, completedAt: now),
        mkTask(id: 'c'),
      ];
      final s = StatsEngine.compute(tasks, 'all');
      expect(s.total, 3);
      expect(s.completed, 2);
      expect(s.active, 1);
      expect(s.rate, 67);
    });

    test('软删除任务不计入统计', () {
      final tasks = [
        mkTask(id: 'a', completed: true),
        mkTask(id: 'b', deleted: true),
      ];
      final s = StatsEngine.compute(tasks, 'all');
      expect(s.total, 1);
      expect(s.completed, 1);
    });

    test('科目分布百分比', () {
      final tasks = [
        mkTask(id: 'a', subject: '数学'),
        mkTask(id: 'b', subject: '语文'),
        mkTask(id: 'c', subject: '数学'),
      ];
      final s = StatsEngine.compute(tasks, 'all');
      expect(s.subjectDist.length, 2);
      expect(s.subjectDist.first.name, '数学');
      expect(s.subjectDist.first.count, 2);
      expect(s.subjectDist.first.pct, 67);
    });

    test('高频未完成 Top3 按数量排序', () {
      final tasks = [
        mkTask(id: 'a', subject: '数学'),
        mkTask(id: 'b', subject: '数学'),
        mkTask(id: 'c', subject: '语文'),
        mkTask(id: 'd', subject: '语文'),
        mkTask(id: 'e', subject: '语文'),
      ];
      final s = StatsEngine.compute(tasks, 'all');
      expect(s.topUnfinished.length, 2);
      expect(s.topUnfinished.first.name, '语文');
      expect(s.topUnfinished.first.count, 3);
    });

    test('趋势数据长度正确', () {
      final s = StatsEngine.compute(const [], 'week');
      expect(s.dailyTrend.length, 7);
      expect(s.weekTrend.length, 7);
      expect(s.weeklyTrend.length, 8);
    });
  });
}
