/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import '../models/task.dart';
import 'store.dart';

/// 成就徽章定义。
class BadgeDef {
  final String id;
  final String name;
  final String desc;
  final String icon;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
  });
}

/// 激励引擎（v0.32.0，S18 模块一）：XP / 连胜 / 成就徽章 / 欠账复习。
/// 与网页版 `web/js/rewards.js` 逻辑完全一致；纯函数派生，不破坏数据模型。
class RewardsEngine {
  static const Map<String, int> xpBase = {
    'checkin': 10,
    'recite': 15,
    'written': 20,
  };

  static const List<BadgeDef> badges = [
    BadgeDef(id: 'first-step', name: '初来乍到', desc: '完成第 1 项作业', icon: 'star'),
    BadgeDef(id: 'ten-strong', name: '十全十美', desc: '累计完成 10 项作业', icon: 'check'),
    BadgeDef(id: 'hundred', name: '百炼成钢', desc: '累计完成 100 项作业', icon: 'flame'),
    BadgeDef(id: 'three-day', name: '三天打鱼', desc: '连续 3 天完成作业', icon: 'sparkles'),
    BadgeDef(id: 'week-streak', name: '一周连胜', desc: '连续 7 天完成作业', icon: 'candy'),
    BadgeDef(id: 'month-king', name: '全勤王', desc: '连续 30 天完成作业', icon: 'sun'),
    BadgeDef(id: 'focus-100', name: '专注达人', desc: '累计完成 100 个番茄', icon: 'bolt'),
    BadgeDef(id: 'night-owl', name: '夜猫子', desc: '累计 50 个番茄在 21 点后完成', icon: 'moon'),
    BadgeDef(id: 'on-time', name: '准时侠', desc: '完成 5 项以上且准时率 90%', icon: 'clock'),
    BadgeDef(id: 'comeback', name: '逆袭者', desc: '完成 1 次欠账补完', icon: 'undo'),
    BadgeDef(id: 'perfect-week', name: '满分周', desc: '某一周内作业全部按时完成', icon: 'target'),
    BadgeDef(id: 'family-helper', name: '家人好帮手', desc: '启用家庭模式且累计完成 20 项', icon: 'heart'),
  ];

  static String dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayStr() => dateStr(DateTime.now());

  static bool isOverdue(Task t, {String? ref}) {
    if (t.isCompleted || t.dueDate == null) return false;
    return dateStr(t.dueDate!).compareTo(ref ?? todayStr()) < 0;
  }

  static int taskXp(Task t, {bool overdueBoost = false}) {
    var xp = xpBase[t.taskType] ?? xpBase['written']!;
    if (t.priority == 2) xp = (xp * 1.5).round();
    if (overdueBoost && isOverdue(t)) xp *= 2;
    return xp;
  }

  static List<Task> completedOn(List<Task> tasks, {String? day}) {
    final ref = day ?? todayStr();
    return tasks
        .where((t) => t.isCompleted && t.completedAt != null)
        .where((t) => dateStr(t.completedAt!) == ref)
        .toList();
  }

  static ({int count, int xp}) daySummary(List<Task> tasks, {String? day}) {
    final list = completedOn(tasks, day: day);
    return (
      count: list.length,
      xp: list.fold(0, (s, t) => s + taskXp(t)),
    );
  }

  static ({int count, int xp}) weekSummary(List<Task> tasks) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: (now.weekday + 6) % 7));
    var count = 0, xp = 0;
    for (final t in tasks) {
      if (!t.isCompleted || t.completedAt == null) continue;
      if (t.completedAt!.isBefore(start)) continue;
      count++;
      xp += taskXp(t);
    }
    return (count: count, xp: xp);
  }

  static int bestDayXp(List<Task> tasks) {
    final map = <String, int>{};
    for (final t in tasks) {
      if (!t.isCompleted || t.completedAt == null) continue;
      final k = dateStr(t.completedAt!);
      map[k] = (map[k] ?? 0) + taskXp(t);
    }
    return map.values.fold(0, (mx, v) => v > mx ? v : mx);
  }

  static int streak(List<Task> tasks) {
    var n = 0;
    bool has(String d) => completedOn(tasks, day: d).isNotEmpty;
    var cursor = DateTime.now();
    if (!has(dateStr(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    while (has(dateStr(cursor))) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  static ({int xp, bool overdue}) onTaskCompleted(Task t) =>
      (xp: taskXp(t, overdueBoost: true), overdue: isOverdue(t));

  static void bumpComeback(AppStore store) {
    final r = Map<String, dynamic>.from(store.settings.rewards);
    r['comebackCount'] = ((r['comebackCount'] as num?) ?? 0) + 1;
    store.updateSettings({'rewards': r});
  }

  static Map<String, bool> achievementMap(AppStore store) {
    final tasks = store.tasks.where((t) => !t.isDeleted).toList();
    final done = tasks.where((t) => t.isCompleted).toList();
    final sessions = store.focusSessions;
    final totalDone = done.length;
    final st = streak(tasks);
    // FocusSession 只记录已完成的专注会话，无需 completed 字段
    final focusTotal = sessions.length;
    final nightFocus = sessions
        .where((s) =>
            s.startedAt.add(Duration(seconds: s.durationSec)).hour >= 21)
        .length;
    final onTime = done
        .where((t) =>
            t.dueDate == null ||
            dateStr(t.dueDate!).compareTo(dateStr(t.completedAt!)) >= 0)
        .length;
    final rate = done.isEmpty ? 0.0 : onTime / done.length;
    final comeback = (store.settings.rewards['comebackCount'] as num?) ?? 0;
    final family = store.settings.familyProfiles.isNotEmpty;

    var perfectWeek = false;
    final now = DateTime.now();
    for (var w = 0; w < 52 && !perfectWeek; w++) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: (now.weekday + 6) % 7 + w * 7));
      final end = start.add(const Duration(days: 7));
      final weekTasks = tasks.where((t) =>
          t.dueDate != null &&
          dateStr(t.dueDate!).compareTo(dateStr(start)) >= 0 &&
          dateStr(t.dueDate!).compareTo(dateStr(end)) < 0);
      final list = weekTasks.toList();
      if (list.isEmpty) continue;
      perfectWeek = list.every((t) =>
          t.isCompleted &&
          t.completedAt != null &&
          dateStr(t.dueDate!).compareTo(dateStr(t.completedAt!)) >= 0);
    }

    return {
      'first-step': totalDone >= 1,
      'ten-strong': totalDone >= 10,
      'hundred': totalDone >= 100,
      'three-day': st >= 3,
      'week-streak': st >= 7,
      'month-king': st >= 30,
      'focus-100': focusTotal >= 100,
      'night-owl': nightFocus >= 50,
      'on-time': done.length >= 5 && rate >= 0.9,
      'comeback': comeback >= 1,
      'perfect-week': perfectWeek,
      'family-helper': family && totalDone >= 20,
    };
  }

  static Map<String, String> unlocked(AppStore store) =>
      Map<String, String>.from(store.settings.achievements);

  /// 检查并记录新解锁徽章，返回新解锁列表。
  static List<BadgeDef> recordBadges(AppStore store) {
    final cur = unlocked(store);
    final map = achievementMap(store);
    final next = Map<String, String>.from(cur);
    final fresh = <BadgeDef>[];
    for (final b in badges) {
      if ((map[b.id] ?? false) && !cur.containsKey(b.id)) {
        next[b.id] = DateTime.now().toIso8601String();
        fresh.add(b);
      }
    }
    if (fresh.isNotEmpty) {
      store.updateSettings({'achievements': next});
    }
    return fresh;
  }
}
