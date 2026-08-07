/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'data/app_state.dart';
import 'data/reminder_service.dart';
import 'data/store.dart';
import 'data/sync_service.dart';
import 'data/update_service.dart';
import 'ui/settings/update_dialog.dart';
import 'ui/shell.dart';

/// 根导航 key：用于启动后自动检查更新弹窗。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  await ReminderService.instance.init();
  if (store.settings.notifications) {
    await ReminderService.instance.requestPermission();
  }
  store.onPersist = (s) => ReminderService.instance.checkAll(s);
  await ReminderService.instance.checkAll(store);
  // 自动同步：数据变化后 5 秒防抖触发一轮 Nostr 同步（开关开启且有账号时）
  final sync = SyncService();
  var syncTimer = Timer(const Duration(seconds: 1), () {});
  store.onPersist = (s) {
    ReminderService.instance.checkAll(s);
    if (s.settings.autoSync && s.account != null) {
      syncTimer.cancel();
      syncTimer = Timer(const Duration(seconds: 5), () {
        sync.syncOnce(s);
      });
    }
  };
  runApp(
    ProviderScope(
      overrides: [appStoreProvider.overrideWithValue(store)],
      child: const SugarPaperApp(),
    ),
  );
}

class SugarPaperApp extends ConsumerStatefulWidget {
  const SugarPaperApp({super.key});

  @override
  ConsumerState<SugarPaperApp> createState() => _SugarPaperAppState();
}

class _SugarPaperAppState extends ConsumerState<SugarPaperApp> {
  @override
  void initState() {
    super.initState();
    // 后台采样实际帧率（1.8s），供「自动」档位使用；仅启动时执行一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectFps(ref.read(appStateProvider));
    });
    // v0.27.0 零服务器自动更新：启动 6 秒后静默检查一次
    if (Platform.environment['FLUTTER_TEST'] != 'true') {
      Future.delayed(const Duration(seconds: 6), () {
        if (!mounted) return;
        _autoCheckUpdate();
      });
    }
  }

  Future<void> _autoCheckUpdate() async {
    try {
      final update = await const UpdateService().checkForUpdate();
      if (update == null) return;
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await showUpdateDialog(ctx, update);
    } catch (_) {
      // 自动检查失败静默忽略（设置页可手动重试）
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final state = ref.watch(appStateProvider);
    final themeKey = state.store.settings.theme;
    final data = SugarThemeData.byKey(themeKey);
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: data.pinkStrong,
        brightness: data.dark ? Brightness.dark : Brightness.light,
        surface: data.surface,
      ),
      scaffoldBackgroundColor: data.bg,
      splashFactory: NoSplash.splashFactory,
      extensions: [
        SugarTheme(
          data: data,
          animations: state.store.settings.animations,
          frameRate: state.resolveFps(),
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: data.glass,
        elevation: 0,
        foregroundColor: data.text,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: data.glass,
        selectedItemColor: data.pinkStrong,
        unselectedItemColor: data.text3,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: data.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: data.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: data.text,
        contentTextStyle: TextStyle(color: data.surface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: '糖纸 · SugarPaper',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }

  static bool _detecting = false;
  static bool _done = false;
  static void _detectFps(AppState state) {
    if (_detecting || _done) return;
    _detecting = true;
    final samples = <double>[];
    var last = SchedulerBinding.instance.currentFrameTimeStamp;
    var count = 0;
    void tick(Duration now) {
      final dt = now - last;
      last = now;
      if (dt > Duration.zero && dt < const Duration(milliseconds: 120)) {
        samples.add(1000 / dt.inMicroseconds * 1000);
      }
      count++;
      if (count < 90) {
        SchedulerBinding.instance.addPostFrameCallback(tick);
      } else {
        samples.sort();
        final med = samples.isEmpty
            ? 60.0
            : samples[samples.length ~/ 2];
        final fps = med.round();
        const buckets = [60, 90, 120, 144];
        var best = 60;
        for (final b in buckets) {
          if ((b - fps).abs() < (best - fps).abs()) best = b;
        }
        state.detectedFps = best;
        state.notify();
        _detecting = false;
        _done = true;
      }
    }
    SchedulerBinding.instance.addPostFrameCallback(tick);
  }
}
