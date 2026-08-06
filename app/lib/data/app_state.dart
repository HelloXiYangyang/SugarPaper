/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note.dart';
import '../models/subject_config.dart';
import '../models/task.dart';
import 'stats_engine.dart';
import 'store.dart';

/// 全局应用状态：数据 + 界面筛选状态。
class AppState extends ChangeNotifier {
  final AppStore store;

  // 界面状态（与 Web 版 App.state 对应）
  String view = 'home';
  String query = '';
  String subject = '全部';
  String priority = 'all';
  String calMode = 'month';
  DateTime calSelected = DateTime.now();
  String statsRange = 'week';
  int detectedFps = 60;

  AppState(this.store);

  void notify() => notifyListeners();

  void navigate(String v) {
    view = v;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void setSubject(String s) {
    subject = s;
    notifyListeners();
  }

  void setPriority(String p) {
    priority = p;
    notifyListeners();
  }

  void setCalMode(String m) {
    calMode = m;
    notifyListeners();
  }

  void setCalSelected(DateTime d) {
    calSelected = d;
    notifyListeners();
  }

  void setStatsRange(String r) {
    statsRange = r;
    notifyListeners();
  }

  /// 当前生效的帧率档位（auto 跟随系统）。
  String resolveFps() {
    final v = store.settings.frameRate;
    if (v.isNotEmpty && v != 'auto') return v;
    return detectedFps >= 120 ? '120' : '60';
  }

  // ---------- 派生数据 ----------

  List<Task> get allTasks =>
      store.tasks.where((t) => !t.isDeleted).toList();

  List<Task> get filteredTasks {
    var list = allTasks;
    if (subject != '全部') list = list.where((t) => t.subject == subject).toList();
    if (priority != 'all') {
      final p = int.parse(priority);
      list = list.where((t) => t.priority == p).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((t) => '${t.title} ${t.subtitle}'.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<Task> get activeTasks => filteredTasks
      .where((t) => !t.isCompleted)
      .toList()
    ..sort((a, b) {
      final c = a.order.compareTo(b.order);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });

  List<Task> get doneTasks => filteredTasks.where((t) => t.isCompleted).toList()
    ..sort((a, b) => (a.completedAt ?? a.updatedAt)
        .compareTo(b.completedAt ?? b.updatedAt));

  /// v5.0 截止分级：逾期 / 今天 / 明天 / 本周 / 长期 五组（未完成任务）。
  /// 逾期置顶标红；组内按优先级降序，再按手动 order。
  List<DueGroup> get groupedActiveTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - now.weekday));
    final groups = <DueGroup>[];

    void addTo(String key, String label, String icon, List<Task> tasks) {
      tasks.sort((a, b) {
        final c = b.priority.compareTo(a.priority);
        return c != 0 ? c : a.order.compareTo(b.order);
      });
      groups.add(DueGroup(
        key: key,
        label: label,
        icon: icon,
        tasks: tasks,
      ));
    }

    final active = filteredTasks.where((t) => !t.isCompleted).toList();
    final overdue = <Task>[];
    final todayTasks = <Task>[];
    final tomorrowTasks = <Task>[];
    final weekTasks = <Task>[];
    final longTasks = <Task>[];

    for (final t in active) {
      final due = t.dueDate;
      if (due == null) {
        longTasks.add(t);
        continue;
      }
      final d = DateTime(due.year, due.month, due.day);
      if (d.isBefore(today)) {
        overdue.add(t);
      } else if (d == today) {
        todayTasks.add(t);
      } else if (d == tomorrow) {
        tomorrowTasks.add(t);
      } else if (!d.isAfter(weekEnd)) {
        weekTasks.add(t);
      } else {
        longTasks.add(t);
      }
    }

    if (overdue.isNotEmpty) addTo('overdue', '已逾期', 'flag', overdue);
    if (todayTasks.isNotEmpty) addTo('today', '今天', 'pin', todayTasks);
    if (tomorrowTasks.isNotEmpty) addTo('tomorrow', '明天', 'sun', tomorrowTasks);
    if (weekTasks.isNotEmpty) addTo('week', '本周', 'calendar', weekTasks);
    if (longTasks.isNotEmpty) addTo('long', '长期', 'clock', longTasks);
    return groups;
  }

  int overdueDays(Task task) {
    final due = task.dueDate;
    if (due == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    return today.difference(d).inDays;
  }

  StatsReport get stats => StatsEngine.compute(allTasks, statsRange);

  Map<String, int> get subjectCounts {
    final m = <String, int>{};
    for (final t in allTasks) {
      m[t.subject] = (m[t.subject] ?? 0) + 1;
    }
    return m;
  }

  int get progressPercent {
    final all = allTasks;
    if (all.isEmpty) return 0;
    final done = all.where((t) => t.isCompleted).length;
    return (done / all.length * 100).round();
  }

  List<SubjectConfig> get enabledSubjects =>
      store.subjects.where((s) => s.enabled).toList();

  /// 便签列表：置顶优先、未归档在前（v5.0）。
  List<Note> get activeNotes {
    final list = store.notes.where((n) => !n.archived).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  List<Note> get archivedNotes =>
      store.notes.where((n) => n.archived).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

/// 截止分级分组（v5.0）。
class DueGroup {
  final String key;
  final String label;
  final String icon;
  final List<Task> tasks;

  const DueGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.tasks,
  });
}

final appStoreProvider = Provider<AppStore>((ref) {
  throw UnimplementedError('由 main.dart 通过 ProviderScope overrides 注入');
});

final appStateProvider =
    ChangeNotifierProvider<AppState>((ref) => AppState(ref.watch(appStoreProvider)));

final themeKeyProvider = Provider<String>((ref) => ref.watch(appStateProvider).store.settings.theme);

final animationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appStateProvider).store.settings.animations,
);

final frameRateProvider = Provider<String>(
  (ref) => ref.watch(appStateProvider).store.settings.frameRate,
);
