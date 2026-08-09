/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sugarpaper/data/app_state.dart';
import 'package:sugarpaper/data/legal_store.dart';
import 'package:sugarpaper/data/store.dart';
import 'package:sugarpaper/main.dart';

void main() {
  testWidgets('统计页在有数据/无数据时均正常渲染', (tester) async {
    // v0.28.0：跳过首启协议门，直接进入应用主界面
    appLegalStore.agreedVersion = LegalStore.legalVersion;
    // FakeAsync 环境下不做真实文件 IO，直接使用内存态。
    final store = AppStore();

    // 造一批跨科目、跨日期、含完成/未完成的任务
    final now = DateTime.now().toUtc();
    store.addTasks([
      {
        'id': 't1',
        'subject': '语文',
        'title': '背古诗',
        'priority': 2,
        'dueDate': '2026-08-08',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'isCompleted': true,
        'completedAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 't2',
        'subject': '数学',
        'title': '试卷一张',
        'priority': 1,
        'dueDate': '2026-08-10',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 't3',
        'subject': '英语',
        'title': '默写单词',
        'priority': 0,
        'createdAt': now.toIso8601String(),
      },
      {
        'id': 't4',
        'subject': '物理',
        'title': '练习册 P45',
        'priority': 1,
        'dueDate': '2026-08-09',
        'createdAt': now.toIso8601String(),
      },
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appStoreProvider.overrideWithValue(store)],
        child: const SugarPaperApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // 切到统计页
    expect(tester.takeException(), isNull);

    // 直接点底部导航“统计”
    await tester.tap(find.text('统计'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);

    // 切换时间范围
    await tester.tap(find.text('今日'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('本月'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    // 清空后仍正常
    store.reset();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
