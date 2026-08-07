/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/stats_engine.dart';
import '../../models/task.dart';
import '../home/dialogs.dart';
import '../home/edit_sheet.dart';
import '../widgets/basic.dart';
import '../widgets/progress_bar.dart';

const _weekCn = ['一', '二', '三', '四', '五', '六', '日'];

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final selected = state.calSelected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        _buildToolbar(context, ref, state, t),
        const SizedBox(height: 12),
        if (state.calMode == 'month')
          _MonthGrid(selected: selected)
        else
          _WeekView(anchor: selected),
        const SizedBox(height: 14),
        _DayList(date: selected),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
  ) {
    final selected = state.calSelected;
    return Row(
      children: [
        SugarIcon('calendar', size: 17, color: t.pinkStrong),
        const SizedBox(width: 6),
        Text(
          '${selected.year}年 ${selected.month}月',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
        ),
        const Spacer(),
        _IconBtn(
          icon: 'chevron-left',
          onTap: () {
            state.setCalSelected(
              DateTime(selected.year, selected.month - 1, 1),
            );
          },
        ),
        const SizedBox(width: 6),
        SugarButton(
          label: '今天',
          compact: true,
          onTap: () => state.setCalSelected(DateTime.now()),
        ),
        const SizedBox(width: 6),
        _IconBtn(
          icon: 'chevron-right',
          onTap: () {
            state.setCalSelected(
              DateTime(selected.year, selected.month + 1, 1),
            );
          },
        ),
        const SizedBox(width: 8),
        _Segmented(
          value: state.calMode,
          options: const [
            ('month', '月'),
            ('week', '周'),
          ],
          onChanged: (v) => state.setCalMode(v),
        ),
        const SizedBox(width: 8),
        SugarButton(
          label: '导出',
          iconName: 'upload',
          compact: true,
          onTap: () => _exportMonth(context, state),
        ),
      ],
    );
  }

  void _exportMonth(BuildContext context, AppState state) {
    final lines = <String>[
      '糖纸 · 作业日历 ${state.calSelected.year}年${state.calSelected.month}月',
      '',
    ];
    final byDate = _tasksByDate(state);
    final daysInMonth =
        DateTime(state.calSelected.year, state.calSelected.month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      final ds = DateTime(state.calSelected.year, state.calSelected.month, day);
      final list = byDate[ds] ?? [];
      if (list.isEmpty) continue;
      lines.add('${ds.month}月${ds.day}日（${list.length} 项）');
      for (final t in list) {
        lines.add(
          '  ${t.isCompleted ? '[✓]' : '[ ]'} [${t.subject}] ${t.title}'
          '${t.subtitle.isNotEmpty ? ' —— ${t.subtitle.replaceAll('\n', ' ')}' : ''}',
        );
      }
      lines.add('');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    showSugarToast(context, '当月日历已复制到剪贴板');
  }

  Map<DateTime, List<Task>> _tasksByDate(AppState state) {
    final map = <DateTime, List<Task>>{};
    for (final t in state.allTasks) {
      final due = t.dueDate;
      if (due == null) continue;
      final d = DateTime(due.year, due.month, due.day);
      map.putIfAbsent(d, () => []).add(t);
    }
    return map;
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.border),
        ),
        child: SugarIcon(icon, size: 15, color: t.text2),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = value == o.$1;
          return PressableScale(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  SugarIcon(
                    o.$1 == 'month' ? 'calendar' : 'list',
                    size: 12,
                    color: active ? t.pinkStrong : t.text3,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    o.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? t.pinkStrong : t.text3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  final DateTime selected;

  const _MonthGrid({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final byDate = <DateTime, List<Task>>{};
    for (final task in state.allTasks) {
      final due = task.dueDate;
      if (due == null) continue;
      byDate
          .putIfAbsent(DateTime(due.year, due.month, due.day), () => [])
          .add(task);
    }

    final first = DateTime(selected.year, selected.month, 1);
    final offset = (first.weekday + 6) % 7; // 周一开头
    final daysInMonth = DateTime(selected.year, selected.month + 1, 0).day;
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    final cells = <DateTime?>[];
    for (var i = 0; i < offset; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(selected.year, selected.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    // v0.24.0 日历增强：考试便签标记 + 专注分钟角标
    final markers = <DateTime, DayMarkers>{};
    for (final d in cells.whereType<DateTime>()) {
      final ds = DateTime(d.year, d.month, d.day);
      markers[ds] = StatsEngine.dayMarkers(
        state.store.notes,
        state.store.focusSessions,
        ds,
      );
    }

    return Column(
      children: [
        Row(
          children: _weekCn
              .map((w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: TextStyle(fontSize: 11, color: t.text3),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.86,
          ),
          itemCount: cells.length,
          itemBuilder: (context, i) {
            final d = cells[i];
            if (d == null) return const SizedBox.shrink();
            final ds = DateTime(d.year, d.month, d.day);
            final list = byDate[ds] ?? const <Task>[];
            final isToday = ds == todayD;
            final isSelected = ds.year == selected.year &&
                ds.month == selected.month &&
                ds.day == selected.day;
            final m = markers[ds];
            return Reveal(
              delayMs: i * 10,
              child: GestureDetector(
                onTap: () => state.setCalSelected(ds),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.pinkStrong
                        : isToday
                            ? t.pinkSoft
                            : t.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: isSelected
                          ? t.pinkStrong
                          : isToday
                              ? t.pink
                              : t.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? t.pinkStrong
                                  : t.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (list.isEmpty)
                        const SizedBox(height: 4)
                      else
                        Wrap(
                          spacing: 2,
                          children: [
                            ...list
                                .take(3)
                                .map((task) => Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: task.isCompleted
                                            ? t.success
                                            : t.text3,
                                        shape: BoxShape.circle,
                                      ),
                                    )),
                            if (list.length > 3)
                              Text(
                                '+${list.length - 3}',
                                style: TextStyle(fontSize: 8, color: t.text3),
                            ),
                          ],
                        ),
                      if (m != null && (m.exam || m.focusMin > 0)) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (m.exam)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 0.5,
                                ),
                                decoration: BoxDecoration(
                                  color: t.yellowSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '考',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w700,
                                    color: t.yellowStrong,
                                  ),
                                ),
                              ),
                            if (m.exam && m.focusMin > 0)
                              const SizedBox(width: 2),
                            if (m.focusMin > 0)
                              Text(
                                '$m.focusMin分',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.mintStrong,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekView extends ConsumerWidget {
  final DateTime anchor;

  const _WeekView({required this.anchor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final weekStart = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(Duration(days: (anchor.weekday + 6) % 7));
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(7, (i) {
        final d = weekStart.add(Duration(days: i));
        final ds = DateTime(d.year, d.month, d.day);
        final list = state.allTasks
            .where((task) =>
                task.dueDate != null &&
                task.dueDate!.year == ds.year &&
                task.dueDate!.month == ds.month &&
                task.dueDate!.day == ds.day)
            .toList();
        final isToday = ds == todayD;
        return Expanded(
          child: Reveal(
            delayMs: i * 30,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isToday ? t.pinkSoft : t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isToday ? t.pink : t.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '周${_weekCn[i]} ${d.month}/${d.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isToday ? t.pinkStrong : t.text2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (list.isEmpty)
                    Text(
                      '—',
                      style: TextStyle(fontSize: 11, color: t.text3),
                    )
                  else
                    ...list.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? t.mintSoft
                                  : SugarThemeData.hex(
                                          state.store.subjectColor(task.subject))
                                      .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: task.isCompleted ? t.mintStrong : t.text,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DayList extends ConsumerWidget {
  final DateTime date;

  const _DayList({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final isToday = DateTime(date.year, date.month, date.day) == todayD;
    final list = state.allTasks
        .where((task) =>
            task.dueDate != null &&
            task.dueDate!.year == date.year &&
            task.dueDate!.month == date.month &&
            task.dueDate!.day == date.day)
        .toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.priority.compareTo(a.priority);
      });
    final done = list.where((t) => t.isCompleted).length;
    final active = list.length - done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SugarIcon('list', size: 15, color: t.pinkStrong),
            const SizedBox(width: 6),
            Text(
              '${isToday ? '今天' : '${date.month}月${date.day}日'} 的任务',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(width: 8),
            Text(
              '未完成 $active · 已完成 $done',
              style: TextStyle(fontSize: 11, color: t.text3),
            ),
            const Spacer(),
            SugarButton(
              label: '添加任务',
              iconName: 'plus',
              compact: true,
              primary: true,
              onTap: () => showEditSheet(context, initialDueDate: date),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          EmptyState(iconName: 'sun', title: '这一天没有截止的作业')
        else
          ...list.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SugarCard(
                  child: Row(
                    children: [
                      PressableScale(
                        onTap: () {
                          state.store.toggleComplete(task.id);
                          state.notify();
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: task.isCompleted ? t.success : t.surface2,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: SugarIcon(
                            task.isCompleted ? 'check' : 'undo',
                            size: 15,
                            color: task.isCompleted ? Colors.white : t.text2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  task.subject,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: SugarThemeData.hex(
                                      state.store.subjectColor(task.subject),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: t.text,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.subtitle.isNotEmpty)
                              Text(
                                task.subtitle,
                                style: TextStyle(fontSize: 11, color: t.text3),
                              ),
                          ],
                        ),
                      ),
                      PriorityTag(priority: task.priority),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
