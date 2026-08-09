/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_icons.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'calendar/calendar_page.dart';
import 'focus/focus_page.dart';
import 'home/home_page.dart';
import 'notes/notes_page.dart';
import 'settings/settings_page.dart';
import 'stats/stats_page.dart';

const _tabs = [
  ('home', '首页', 'home'),
  ('notes', '便签', 'list'),
  ('focus', '专注', 'bolt'),
  ('calendar', '日历', 'calendar'),
  ('stats', '统计', 'chart-bar'),
  ('settings', '我的', 'user'),
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _pages = const [
    HomePage(),
    NotesPage(),
    FocusPage(embedded: true),
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  int _indexOf(String view) => _tabs.indexWhere((t) => t.$1 == view);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    final index = _indexOf(state.view).clamp(0, _tabs.length - 1);
    final prevIndex = _prevIndex;
    _prevIndex = index;
    // v0.32.0：宽屏（≥840px，桌面/平板横屏）使用侧边栏，与网页版断点一致
    final wide = MediaQuery.sizeOf(context).width >= kMediumMax;

    final content = SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: theme.animations
            ? AnimDurations.speed(
                AnimDurations.pageTransition, theme.frameRate)
            : Duration.zero,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => _PageTransition(
          anim: anim,
          index: index,
          prevIndex: prevIndex,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(state.view),
          child: _pages[index],
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: t.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              state: state,
              current: index,
              onTap: (i) => state.navigate(_tabs[i].$1),
              onSubject: (name) {
                state.setSubject(name);
                if (state.view != 'home') state.navigate('home');
              },
            ),
            VerticalDivider(width: 1, thickness: 1, color: t.border),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: content,
      bottomNavigationBar: _BottomNav(
        current: index,
        onTap: (i) => state.navigate(_tabs[i].$1),
      ),
    );
  }

  int _prevIndex = 0;
}

class _PageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> anim;
  final int index;
  final int prevIndex;

  const _PageTransition({
    required this.child,
    required this.anim,
    required this.index,
    required this.prevIndex,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < kCompactMax;
    final forward = index >= prevIndex;
    final offset =
        compact ? const Offset(0, 0.05) : Offset(forward ? 0.08 : -0.08, 0);
    return SlideTransition(
      position: Tween<Offset>(
        begin: offset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: compact ? 0.98 : 1.0, end: 1.0)
              .animate(anim),
          child: child,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Container(
      decoration: BoxDecoration(
        color: t.glass,
        border: Border(top: BorderSide(color: t.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final active = i == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: active ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: SugarIcon(
                          tab.$3,
                          size: 21,
                          color: active ? t.iconMain : t.text3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? t.iconMain : t.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 桌面侧边栏（≥840px）：品牌 + 导航 + 科目快捷筛选，对齐网页版侧边栏。
class _Sidebar extends StatelessWidget {
  final AppState state;
  final int current;
  final ValueChanged<int> onTap;
  final ValueChanged<String> onSubject;

  const _Sidebar({
    required this.state,
    required this.current,
    required this.onTap,
    required this.onSubject,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final counts = state.subjectCounts;
    final allCount = state.allTasks.length;

    Widget navItem(int i) {
      final tab = _tabs[i];
      final active = i == current;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Material(
          color: active ? t.iconMain.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SugarIcon(
                    tab.$3,
                    size: 17,
                    color: active ? t.iconMain : t.text3,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? t.iconMain : t.text2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget subjectItem(String name, Color dot, int count, {bool active = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Material(
          color: active ? t.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSubject(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? t.text : t.text2,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(fontSize: 11, color: t.text3),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 232,
      color: t.surface,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 14),
            child: Row(
              children: [
                SugarIcon('candy', size: 22, color: t.iconMain),
                const SizedBox(width: 8),
                Text(
                  '糖纸 · SugarPaper',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < _tabs.length; i++) navItem(i),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                  child: Text(
                    '科目',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: t.text3,
                    ),
                  ),
                ),
                subjectItem(
                  '全部',
                  const Color(0xFFE292B4),
                  allCount,
                  active: state.subject == '全部',
                ),
                for (final s in state.enabledSubjects)
                  subjectItem(
                    s.name,
                    SugarThemeData.hex(s.colorHex),
                    counts[s.name] ?? 0,
                    active: state.subject == s.name,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
