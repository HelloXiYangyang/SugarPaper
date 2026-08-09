/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/rewards.dart';
import 'package:sugarpaper/data/store.dart';
import 'package:sugarpaper/models/task.dart';

void main() {
  Task task({
    String id = 't1',
    String type = 'written',
    int priority = 1,
    DateTime? due,
    bool done = false,
    DateTime? completedAt,
  }) =>
      Task(
        id: id,
        subject: '数学',
        title: '作业',
        taskType: type,
        priority: priority,
        dueDate: due,
        isCompleted: done,
        completedAt: completedAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  test('任务 XP：类型基础分 + 高优先级加成 + 欠账补完双倍', () {
    expect(RewardsEngine.taskXp(task(type: 'checkin')), 10);
    expect(RewardsEngine.taskXp(task(type: 'recite')), 15);
    expect(RewardsEngine.taskXp(task(type: 'written')), 20);
    expect(RewardsEngine.taskXp(task(type: 'written', priority: 2)), 30);

    final overdue = task(
      due: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(RewardsEngine.isOverdue(overdue), isTrue);
    expect(RewardsEngine.taskXp(overdue, overdueBoost: true), 40);
  });

  test('连胜：连续完成天数（今天未完成则从昨天起算）', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tasks = [
      task(id: 'a', done: true, completedAt: yesterday),
      task(id: 'b', done: true, completedAt: now),
    ];
    expect(RewardsEngine.streak(tasks), 2);

    final old = now.subtract(const Duration(days: 3));
    expect(RewardsEngine.streak([task(id: 'c', done: true, completedAt: old)]), 0);
  });

  test('日/周汇总与最佳单日 XP', () {
    final now = DateTime.now();
    final tasks = [
      task(id: 'a', done: true, completedAt: now, type: 'written'),
      task(id: 'b', done: true, completedAt: now, type: 'checkin'),
      task(
        id: 'c',
        done: true,
        completedAt: now.subtract(const Duration(days: 3)),
        type: 'written',
        priority: 2,
      ),
    ];
    final today = RewardsEngine.daySummary(tasks);
    expect(today.count, 2);
    expect(today.xp, 30);
    final week = RewardsEngine.weekSummary(tasks);
    expect(week.count, 3);
    expect(RewardsEngine.bestDayXp(tasks), 30);
  });

  test('徽章：首次完成解锁初来乍到，欠账补完记录逆袭者', () {
    final store = AppStore();
    store.addTasks([
      {
        'id': 'x',
        'subject': '数学',
        'title': '试卷',
        'taskType': 'written',
        'isCompleted': true,
        'completedAt': DateTime.now().toIso8601String(),
      },
    ]);
    final fresh = RewardsEngine.recordBadges(store);
    expect(fresh.map((b) => b.id), contains('first-step'));
    expect(store.settings.achievements.containsKey('first-step'), isTrue);

    // 再次记录不重复解锁
    final fresh2 = RewardsEngine.recordBadges(store);
    expect(fresh2.any((b) => b.id == 'first-step'), isFalse);
  });
}
