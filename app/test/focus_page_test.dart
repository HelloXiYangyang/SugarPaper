/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sugarpaper/data/app_state.dart';
import 'package:sugarpaper/data/legal_store.dart';
import 'package:sugarpaper/data/store.dart';
import 'package:sugarpaper/main.dart';
import 'package:sugarpaper/ui/focus/focus_page.dart';

void main() {
  testWidgets('S12 专注页：embedded 模式渲染番茄钟卡片与环境噪音卡片', (tester) async {
    // v0.28.0：跳过首启协议门，直接进入应用主界面
    appLegalStore.agreedVersion = LegalStore.legalVersion;
    final store = AppStore();
    store.addFocusSession({
      'taskTitle': '自由专注',
      'durationSec': 25 * 60,
      'pomodoros': 1,
      'soundScene': 'rain',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWithValue(store)],
        child: const SugarPaperApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // 底部导航 6 项，专注居中突出
    expect(find.text('专注'), findsWidgets);

    // 点击「专注」Tab 进入独立页面
    await tester.tap(find.text('专注').first);
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);

    // 番茄钟卡片与卡片标题
    expect(find.text('番茄钟'), findsOneWidget);
    expect(find.text('环境与噪音'), findsOneWidget);

    // 场景卡片（对齐网页版场景集）
    expect(find.text('雨天'), findsOneWidget);
    expect(find.text('篝火'), findsOneWidget);
    expect(find.text('粉红噪音'), findsOneWidget);

    // 今日专注统计（25 分钟 · 1 番茄）
    expect(find.textContaining('分钟'), findsWidgets);

    // 滚动到「声音与氛围」卡片（ListView 懒加载，需滚动后可见）
    await tester.drag(
      find.descendant(
        of: find.byType(FocusPage),
        matching: find.byType(ListView),
      ),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('声音与氛围'), findsOneWidget);
    expect(find.text('呼吸引导'), findsOneWidget);
  });
}
