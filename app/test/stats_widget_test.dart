/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sugarpaper/core/theme.dart';
import 'package:sugarpaper/data/app_state.dart';
import 'package:sugarpaper/data/store.dart';
import 'package:sugarpaper/ui/stats/stats_page.dart';

void main() {
  testWidgets('统计页各图表组件在空数据与有数据时均可渲染', (tester) async {
    // 注：testWidgets 的 FakeAsync 环境下不做真实文件 IO，
    // 直接使用内存态（不调用 load，persist 为后台写入不阻塞）。
    final store = AppStore();

    final theme = SugarTheme(
      data: SugarThemeData.byKey('classic'),
      animations: false,
      frameRate: '60',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: [theme],
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.data.pinkStrong,
              surface: theme.data.surface,
            ),
            scaffoldBackgroundColor: theme.data.bg,
          ),
          home: const StatsPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull,
        reason: '空数据统计页不应报错');

    // 加入有数据
    final now = DateTime.now().toUtc();
    store.addTasks([
      {
        'id': 'a',
        'subject': '语文',
        'title': '背古诗',
        'isCompleted': true,
        'completedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 'b',
        'subject': '数学',
        'title': '试卷',
        'createdAt': now.toIso8601String(),
      },
    ]);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull,
        reason: '有数据统计页不应报错');

    // 切换范围
    for (final label in ['今日', '本周', '本月', '全部']) {
      await tester.tap(find.text(label), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull,
          reason: '切换到 $label 不应报错');
    }
  });
}
