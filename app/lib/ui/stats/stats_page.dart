/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/rewards.dart';
import '../../data/stats_engine.dart';
import '../../models/focus_session.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';
import '../widgets/progress_bar.dart';
import 'charts.dart';
import 'report_card.dart';

const _rangeLabels = {
  'today': '今日',
  'week': '本周',
  'month': '本月',
  'all': '全部',
};

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final s = state.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        _toolbar(context, ref, state, t),
        const SizedBox(height: 12),
        _overviewCard(s, state, t),
        const SizedBox(height: 12),
        _pieCard(s, state, t),
        const SizedBox(height: 12),
        _card(
          icon: 'chart-bar',
          title: '每日完成趋势（柱状图）',
          child: BarChart(data: s.barTrend),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'chart-line',
          title: '历史完成趋势（折线图 · 最近 8 周）',
          child: LineChart(data: s.weeklyTrend),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'list',
          title: '高频未完成科目 Top 3',
          child: _top3(s, state, t),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'flag',
          title: '科目欠账排行（考前复习）',
          child: _debtCard(s, state, t),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'bolt',
          title: '激励（XP）',
          child: _rewardCard(state, t),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'bolt',
          title: '专注统计（番茄钟）',
          child: _focusCard(state, t),
          t: t,
        ),
        const SizedBox(height: 12),
        _card(
          icon: 'calendar',
          title: '${_rangeLabels[state.statsRange]}一览',
          child: _rangeSummary(s, t),
          t: t,
        ),
      ],
    );
  }

  /// v0.32.0：激励（XP）卡片
  Widget _rewardCard(AppState state, SugarThemeData t) {
    final tasks = state.store.tasks.where((x) => !x.isDeleted).toList();
    final today = RewardsEngine.daySummary(tasks);
    final week = RewardsEngine.weekSummary(tasks);
    final best = RewardsEngine.bestDayXp(tasks);
    final st = RewardsEngine.streak(tasks);
    final goals = Map<String, int>.from(state.store.settings.rewardsGoals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _summaryItem(0, 'bolt', '今日 XP', '${today.xp}', t),
            _summaryItem(1, 'chart-bar', '本周 XP', '${week.xp}', t),
            _summaryItem(2, 'star', '最佳单日', '$best', t),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '每日目标 ${goals['dailyXp'] ?? 50} XP · 完成 ${today.count}/${goals['dailyTasks'] ?? 3} 项 · 连续 $st 天',
          style: TextStyle(fontSize: 11, color: t.text3),
        ),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
  ) {
    return Row(
      children: [
        SugarIcon('chart-bar', size: 17, color: t.iconMain),
        const SizedBox(width: 6),
        Text(
          '统计',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
        ),
        const Spacer(),
        _rangeSeg(state, t),
        const SizedBox(width: 8),
        SugarButton(
          label: '导出',
          iconName: 'upload',
          compact: true,
          onTap: () => _exportReport(context, state),
        ),
      ],
    );
  }

  Widget _rangeSeg(AppState state, SugarThemeData t) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _rangeLabels.entries.map((e) {
          final active = state.statsRange == e.key;
          return PressableScale(
            onTap: () => state.setStatsRange(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? t.iconMain : t.text3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _overviewCard(StatsReport s, AppState state, SugarThemeData t) {
    final rangeNote = switch (state.statsRange) {
      'today' => '今天共 ${s.rangeTotal} 项作业，完成 ${s.rangeCompleted} 项',
      'week' => '本周新增 ${s.rangeTotal} 项，完成 ${s.rangeCompleted} 项',
      'month' => '本月新增 ${s.rangeTotal} 项，完成 ${s.rangeCompleted} 项',
      _ => '共 ${s.rangeTotal} 项作业，完成 ${s.rangeCompleted} 项',
    };
    return _card(
      icon: 'chart-line',
      title: '整体进度',
      child: Column(
        children: [
          Row(
            children: [
              RingChart(percent: s.rate),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _summaryItem(0, 'book', '总任务数', '${s.total}', t),
                    _summaryItem(1, 'check', '已完成', '${s.completed}（${s.rate}%）', t, ok: true),
                    _summaryItem(2, 'pin', '进行中', '${s.active}', t, no: true),
                    _summaryItem(3, 'flame', '连续完成天数', '${s.streak} 天', t),
                    _summaryItem(4, 'chart-line', '本周平均完成率', '${s.weekRate}%', t),
                    _summaryItem(5, 'clock', '准时完成率', '${s.onTimeRate}%', t, ok: s.onTimeRate >= 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SugarIcon('save', size: 12, color: t.text3),
              const SizedBox(width: 5),
              Text(
                rangeNote,
                style: TextStyle(fontSize: 11, color: t.text3),
              ),
            ],
          ),
        ],
      ),
      t: t,
    );
  }

  Widget _summaryItem(
    int i,
    String icon,
    String label,
    String value,
    SugarThemeData t, {
    bool ok = false,
    bool no = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Reveal(
        delayMs: i * 45,
        child: Row(
          children: [
            SugarIcon(icon, size: 13, color: t.text3),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: t.text2),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ok ? t.success : no ? t.dangerStrong : t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieCard(StatsReport s, AppState state, SugarThemeData t) {
    return _card(
      icon: 'chart-pie',
      title: '科目分布（饼图）',
      child: Row(
        children: [
          PieChart(
            data: s.subjectDist,
            colors: s.subjectDist
                .map((d) => state.store.subjectColor(d.name))
                .toList(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: s.subjectDist
                  .map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Reveal(
                          delayMs: 30 * s.subjectDist.indexOf(d),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: SugarThemeData.hex(
                                    state.store.subjectColor(d.name),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  d.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: t.text2),
                                ),
                              ),
                              Text(
                                '${d.pct}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: t.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      t: t,
    );
  }

  Widget _top3(StatsReport s, AppState state, SugarThemeData t) {
    if (s.topUnfinished.isEmpty) {
      return EmptyState(iconName: 'sparkles', title: '没有未完成的作业');
    }
    return Column(
      children: s.topUnfinished
          .map((x) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Reveal(
                  delayMs: 30 * s.topUnfinished.indexOf(x),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: SugarThemeData.hex(
                            state.store.subjectColor(x.name),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        x.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PriorityTag(priority: x.pri),
                      const Spacer(),
                      Text(
                        '${x.count} 项',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _debtCard(StatsReport s, AppState state, SugarThemeData t) {
    if (s.subjectDebt.isEmpty) {
      return EmptyState(iconName: 'sparkles', title: '没有欠账，太棒了！');
    }
    return Column(
      children: s.subjectDebt
          .map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Reveal(
                  delayMs: 30 * s.subjectDebt.indexOf(d),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: SugarThemeData.hex(
                            state.store.subjectColor(d.name),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                      ),
                      Text(
                        d.overdueDays > 0
                            ? '${d.count} 项 · 逾期 ${d.overdueDays} 天'
                            : '${d.count} 项',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: d.overdueDays > 0 ? t.dangerStrong : t.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _rangeSummary(StatsReport s, SugarThemeData t) {
    return Column(
      children: [
        _summaryItem(0, 'pin', '新增', '${s.rangeTotal}', t),
        _summaryItem(1, 'check', '完成', '${s.rangeCompleted}', t, ok: true),
        _summaryItem(2, 'chart-line', '完成率', '${s.rangeRate}%', t),
        _summaryItem(3, 'clock', '今日待完成', '${s.todayActive}', t, no: true),
      ],
    );
  }

  Widget _focusCard(AppState state, SugarThemeData t) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    int sum(List<FocusSession> list) =>
        list.fold(0, (s, x) => s + x.durationSec);
    final todaySec = sum(state.store.focusSessions
        .where((s) => !s.startedAt.isBefore(todayStart))
        .toList());
    final weekSec = sum(state.store.focusSessions
        .where((s) => !s.startedAt.isBefore(weekStart))
        .toList());
    final pomodoros = state.store.focusSessions.length;
    return Column(
      children: [
        _summaryItem(0, 'bolt', '今日专注', '${todaySec ~/ 60} 分钟', t),
        _summaryItem(1, 'chart-bar', '本周专注', '${weekSec ~/ 60} 分钟', t),
        _summaryItem(2, 'check', '完成番茄数', '$pomodoros 个', t, ok: true),
      ],
    );
  }

  Widget _card({
    required String icon,
    required String title,
    required Widget child,
    required SugarThemeData t,
  }) {
    return Reveal(
      child: SugarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SugarIcon(icon, size: 15, color: t.iconMain),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  void _exportReport(BuildContext context, AppState state) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '导出统计报告',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 14),
              SugarButton(
                label: '复制文本报告',
                iconName: 'paperclip',
                onTap: () {
                  Navigator.pop(ctx);
                  _copyReport(context, state);
                },
              ),
              const SizedBox(height: 8),
              SugarButton(
                label: '导出 PNG 图片',
                iconName: 'image',
                primary: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPng(context, state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyReport(BuildContext context, AppState state) {
    final s = state.stats;
    final lines = <String>[
      '糖纸 · SugarPaper 统计报告（${_rangeLabels[state.statsRange]}）',
      '生成时间：${DateTime.now()}',
      '',
      '【整体进度】',
      '  总任务：${s.total} 项',
      '  已完成：${s.completed} 项（${s.rate}%）',
      '  进行中：${s.active} 项',
      '  连续完成天数：${s.streak} 天',
      '',
      '【科目分布】',
      ...s.subjectDist.map(
        (x) => '  ${x.name}：${x.count} 项（${x.pct}%）',
      ),
      '',
      '【高频未完成科目】',
      ...(s.topUnfinished.isEmpty
          ? ['  无']
          : s.topUnfinished.map((x) => '  ${x.name}：${x.count} 项')),
      '',
      '【每日完成趋势（最近7天）】',
      ...s.dailyTrend.map((d) => '  ${d.date}：${d.count} 项'),
      '',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    showSugarToast(context, '统计报告已复制到剪贴板');
  }

  /// v0.21.0 统计报告 PNG 导出（对齐网页版 report.js → PNG 下载）。
  Future<void> _exportPng(BuildContext context, AppState state) async {
    final s = state.stats;
    final focusMin = state.store.focusSessions
        .fold<int>(0, (sum, x) => sum + x.durationSec) ~/
        60;
    final painter = ReportCardPainter(
      s: s,
      rangeLabel: _rangeLabels[state.statsRange]!,
      dateStr: '${DateTime.now().year}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().day.toString().padLeft(2, '0')}',
      focusMin: focusMin,
      subjectColor: (name) => state.store.subjectColor(name),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 640 / 880,
                child: CustomPaint(
                  painter: painter,
                  size: const Size(640, 880),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SugarButton(
              label: '保存并分享 PNG',
              iconName: 'download',
              primary: true,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final bytes = await renderReportPng(
                    s,
                    rangeLabel: _rangeLabels[state.statsRange]!,
                    focusMin: focusMin,
                    subjectColor: (name) => state.store.subjectColor(name),
                  );
                  if (bytes.isEmpty) {
                    if (!context.mounted) return;
                    showSugarToast(context, '生成失败，请重试');
                    return;
                  }
                  final dir = await getTemporaryDirectory();
                  final file = File(
                    '${dir.path}${Platform.pathSeparator}糖纸-统计报告.png',
                  );
                  await file.writeAsBytes(bytes);
                  await Share.shareXFiles(
                    [XFile(file.path, mimeType: 'image/png')],
                    text: '糖纸 · SugarPaper 统计报告',
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  showSugarToast(context, '导出失败，请重试');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
