/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import '../models/task.dart';

class BarPoint {
  final String date;
  final String label;
  final int count;
  final bool isToday;
  const BarPoint({
    required this.date,
    required this.label,
    required this.count,
    this.isToday = false,
  });
}

class SubjectDist {
  final String name;
  final int count;
  final int pct;
  const SubjectDist({required this.name, required this.count, required this.pct});
}

class TopUnfinished {
  final String name;
  final int count;
  final int pri;
  const TopUnfinished({required this.name, required this.count, required this.pri});
}

class SubjectDebt {
  final String name;
  final int count;
  final int overdueDays;
  final int weight;
  const SubjectDebt({
    required this.name,
    required this.count,
    required this.overdueDays,
    required this.weight,
  });
}

class StatsReport {
  final int total;
  final int completed;
  final int active;
  final int rate;
  final int rangeTotal;
  final int rangeCompleted;
  final int rangeRate;
  final int todayCompleted;
  final int todayActive;
  final int weekCompleted;
  final int streak;
  final int weekRate;
  final int onTimeRate; // 准时完成率（v5.0）
  final List<BarPoint> dailyTrend;
  final List<BarPoint> weekTrend;
  final List<BarPoint> monthTrend;
  final List<BarPoint> weeklyTrend;
  final List<BarPoint> barTrend;
  final List<SubjectDist> subjectDist;
  final int subjectTotal;
  final List<TopUnfinished> topUnfinished;
  final List<SubjectDebt> subjectDebt; // 科目欠账排行（v5.0）

  const StatsReport({
    required this.total,
    required this.completed,
    required this.active,
    required this.rate,
    required this.rangeTotal,
    required this.rangeCompleted,
    required this.rangeRate,
    required this.todayCompleted,
    required this.todayActive,
    required this.weekCompleted,
    required this.streak,
    required this.weekRate,
    required this.onTimeRate,
    required this.dailyTrend,
    required this.weekTrend,
    required this.monthTrend,
    required this.weeklyTrend,
    required this.barTrend,
    required this.subjectDist,
    required this.subjectTotal,
    required this.topUnfinished,
    required this.subjectDebt,
  });
}

/// 统计引擎（纯函数，逻辑与 Web 版 `web/js/stats.js` 一致）。
class StatsEngine {
  static String _pad(int n) => n.toString().padLeft(2, '0');
  static String _dateStr(DateTime d) =>
      '${d.year}-${_pad(d.month)}-${_pad(d.day)}';
  static DateTime _parseDate(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1] - 1, p[2]);
  }

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static DateTime _startOfWeek(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    final wd = (x.weekday + 6) % 7; // 周一=0
    return _addDays(x, -wd);
  }

  static bool _completedOn(Task t, String dateStr) {
    if (t.completedAt == null) return false;
    return _dateStr(t.completedAt!) == dateStr;
  }

  static int _countCompletedOn(List<Task> tasks, String dateStr) =>
      tasks.where((t) => _completedOn(t, dateStr)).length;

  static StatsReport compute(List<Task> allTasks, String range) {
    final tasks = allTasks.where((t) => !t.isDeleted).toList();
    final active = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();
    final total = tasks.length;
    final rate = total == 0 ? 0 : (completed.length / total * 100).round();
    final now = DateTime.now();
    final today = _dateStr(now);
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month, 1);

    bool inRange(Task t, DateTime startDate, DateTime endDate) {
      final d = _parseDate(_dateStr(t.createdAt));
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }

    final rangeTasks = tasks.where((t) {
      switch (range) {
        case 'today':
          return _dateStr(t.createdAt) == today;
        case 'week':
          return inRange(t, weekStart, now);
        case 'month':
          return inRange(t, monthStart, now);
        default:
          return true;
      }
    }).toList();
    final rangeCompleted = rangeTasks.where((t) => t.isCompleted).toList();

    // 每日完成趋势（最近 7 天）
    final dailyTrend = <BarPoint>[];
    for (var i = 6; i >= 0; i--) {
      final d = _addDays(now, -i);
      final ds = _dateStr(d);
      dailyTrend.add(BarPoint(
        date: ds,
        label: '${d.month}/${d.day}',
        count: _countCompletedOn(tasks, ds),
        isToday: ds == today,
      ));
    }

    // 本周每日趋势
    const weekCn = ['一', '二', '三', '四', '五', '六', '日'];
    final weekTrend = <BarPoint>[];
    for (var i = 0; i < 7; i++) {
      final d = _addDays(weekStart, i);
      final ds = _dateStr(d);
      weekTrend.add(BarPoint(
        date: ds,
        label: '周${weekCn[i]}',
        count: _countCompletedOn(tasks, ds),
        isToday: ds == today,
      ));
    }

    // 本月每日趋势
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthTrend = <BarPoint>[];
    for (var i = 1; i <= daysInMonth; i++) {
      final d = DateTime(now.year, now.month, i);
      final ds = _dateStr(d);
      monthTrend.add(BarPoint(
        date: ds,
        label: '$i',
        count: _countCompletedOn(tasks, ds),
        isToday: ds == today,
      ));
    }

    // 历史趋势（最近 8 周）
    final weeklyTrend = <BarPoint>[];
    for (var i = 7; i >= 0; i--) {
      final ws = _addDays(weekStart, -i * 7);
      final we = _addDays(ws, 6);
      final count = tasks.where((t) {
        if (t.completedAt == null) return false;
        final d = t.completedAt!;
        return !d.isBefore(ws) && !d.isAfter(we);
      }).length;
      weeklyTrend.add(BarPoint(
        date: _dateStr(ws),
        label: '${ws.month}/${ws.day}',
        count: count,
      ));
    }

    // 连续完成天数（含今天）
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (_countCompletedOn(tasks, _dateStr(cursor)) == 0) {
      cursor = _addDays(cursor, -1);
    }
    while (_countCompletedOn(tasks, _dateStr(cursor)) > 0) {
      streak++;
      cursor = _addDays(cursor, -1);
    }

    // 科目分布（全部任务）
    final subjectCounts = <String, int>{};
    tasks.forEach((t) {
      subjectCounts[t.subject] = (subjectCounts[t.subject] ?? 0) + 1;
    });
    final subjectEntries = subjectCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final subjectTotal = subjectEntries.fold(0, (s, e) => s + e.value);
    final subjectDist = subjectEntries
        .map((e) => SubjectDist(
              name: e.key,
              count: e.value,
              pct: subjectTotal == 0 ? 0 : (e.value / subjectTotal * 100).round(),
            ))
        .toList();

    // 高频未完成科目 Top3
    final unCounts = <String, int>{};
    active.forEach((t) {
      unCounts[t.subject] = (unCounts[t.subject] ?? 0) + 1;
    });
    final topUnfinished = unCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topUnfinished
        .take(3)
        .map((e) => TopUnfinished(
              name: e.key,
              count: e.value,
              pri: _maxPriorityOf(active, e.key),
            ))
        .toList();

    // v5.0 准时完成率：按时完成数 / 应完成数（有截止日期的任务）
    final dueTasks = tasks.where((t) => t.dueDate != null).toList();
    var onTimeCount = 0;
    for (final t in dueTasks) {
      if (!t.isCompleted || t.completedAt == null) continue;
      final doneLocal = t.completedAt!.toLocal();
      final due = DateTime(
        t.dueDate!.year,
        t.dueDate!.month,
        t.dueDate!.day,
        23,
        59,
        59,
      );
      if (!doneLocal.isAfter(due)) onTimeCount++;
    }
    final int onTimeRate =
        dueTasks.isEmpty ? 0 : (onTimeCount / dueTasks.length * 100).round();

    // v5.0 科目欠账排行：未完成数 + 逾期天数加权（服务考前复习）
    final debtMap = <String, List<int>>{};
    for (final t in active) {
      final due = t.dueDate;
      if (due == null) continue;
      final e = debtMap.putIfAbsent(t.subject, () => [0, 0]);
      e[0] += 1;
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(due.year, due.month, due.day);
      final days = today.difference(d).inDays;
      if (days > 0) e[1] += days;
    }
    final subjectDebt = debtMap.entries
        .map((e) => SubjectDebt(
              name: e.key,
              count: e.value[0],
              overdueDays: e.value[1],
              weight: e.value[0] * 2 + e.value[1],
            ))
        .toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    final topDebt = subjectDebt.take(3).toList();

    // 周平均完成率（本周每日完成率均值）
    var weekRate = 0;
    if (weekTrend.isNotEmpty) {
      var total = 0;
      for (final d in weekTrend) {
        if (d.count > 0) total += 100;
      }
      weekRate = (total / weekTrend.length).round();
    }

    final barTrend = switch (range) {
      'today' => dailyTrend.sublist(dailyTrend.length - 1),
      'week' => weekTrend,
      'month' => monthTrend,
      _ => dailyTrend,
    };

    final int weekCompleted = _countCompletedOn(tasks, today) +
        weekTrend.sublist(0, weekTrend.length - 1).fold(0, (s, d) => s + d.count);

    return StatsReport(
      total: total,
      completed: completed.length,
      active: active.length,
      rate: rate,
      rangeTotal: rangeTasks.length,
      rangeCompleted: rangeCompleted.length,
      rangeRate: rangeTasks.isEmpty
          ? 0
          : (rangeCompleted.length / rangeTasks.length * 100).round(),
      todayCompleted: _countCompletedOn(tasks, today),
      todayActive: tasks
          .where((t) => t.dueDate != null &&
              _dateStr(t.dueDate!) == today &&
              !t.isCompleted)
          .length,
      weekCompleted: weekCompleted,
      streak: streak,
      weekRate: weekRate,
      onTimeRate: onTimeRate,
      dailyTrend: dailyTrend,
      weekTrend: weekTrend,
      monthTrend: monthTrend,
      weeklyTrend: weeklyTrend,
      barTrend: barTrend,
      subjectDist: subjectDist,
      subjectTotal: subjectTotal,
      topUnfinished: top3,
      subjectDebt: topDebt,
    );
  }

  static int _maxPriorityOf(List<Task> tasks, String subject) =>
      tasks
          .where((t) => t.subject == subject)
          .fold(0, (mx, t) => mx > t.priority ? mx : t.priority);
}
