/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_icons.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../data/app_state.dart';
import 'calendar/calendar_page.dart';
import 'home/home_page.dart';
import 'notes/notes_page.dart';
import 'settings/settings_page.dart';
import 'stats/stats_page.dart';

const _tabs = [
  ('home', '首页', 'home'),
  ('calendar', '日历', 'calendar'),
  ('stats', '统计', 'chart-bar'),
  ('notes', '便签', 'list'),
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
    CalendarPage(),
    StatsPage(),
    NotesPage(),
    SettingsPage(),
  ];

  int _indexOf(String view) => _tabs.indexWhere((t) => t.$1 == view);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    final index = _indexOf(state.view).clamp(0, 3);
    final prevIndex = _prevIndex;
    _prevIndex = index;

    return Scaffold(
      backgroundColor: t.bg,
      body: AnimatedSwitcher(
        duration: theme.animations
            ? AnimDurations.speed(AnimDurations.pageTransition, theme.frameRate)
            : Duration.zero,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => _PageTransition(
          child: child,
          anim: anim,
          index: index,
          prevIndex: prevIndex,
        ),
        child: KeyedSubtree(
          key: ValueKey(state.view),
          child: _pages[index],
        ),
      ),
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
    final offset = compact ? Offset(0, 0.05) : Offset(forward ? 0.08 : -0.08, 0);
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
          height: 58,
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
                          color: active ? t.pinkStrong : t.text3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? t.pinkStrong : t.text3,
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
