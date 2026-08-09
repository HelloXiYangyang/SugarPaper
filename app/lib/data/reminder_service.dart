/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/note.dart';
import 'device_capabilities.dart';
import 'store.dart';

/// 本地通知提醒引擎（对齐网页版 `reminders.js`，v0.15.0）：
/// 作业截止（当天早 7-9 点 / 前一天晚 20 点后 / 逾期即时）+ 便签提醒。
/// 同一条提醒只触发一次（记录于 settings.notifiedDue / notifiedNotes）。
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(
      android: android,
      // v0.32.0：Windows 系统通知（toast）
      windows: WindowsInitializationSettings(
        appName: '糖纸 · SugarPaper',
        appUserModelId: 'HelloXiYangyang.SugarPaper',
        guid: '9B4F7C2E-3D8A-4E5F-9B1C-2A3D4E5F6A7B',
      ),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  Future<void> requestPermission() async {
    // Windows 无需申请通知权限（系统通知默认可用）
    if (DeviceCapabilities.isDesktop) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> _push(String title, String body) async {
    if (!_ready) return;
    const androidDetails = AndroidNotificationDetails(
      'sugarpaper_reminders',
      '糖纸提醒',
      channelDescription: '作业截止与便签提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      windows: const WindowsNotificationDetails(
        subtitle: '糖纸 · SugarPaper',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  /// 检查截止任务提醒（对齐网页版 checkDue）。
  Future<void> checkDue(AppStore store) async {
    if (!store.settings.notifications) return;
    final tasks = store.tasks.where((t) => !t.isDeleted && !t.isCompleted);
    if (tasks.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _dateStr(now);
    final minutes = now.hour * 60 + now.minute;
    final due = Map<String, bool>.from(store.settings.notifiedDue);
    // v0.22.0 提醒时间自定义：默认前一晚 20:00、当天早上 07:00 起 2 小时窗口
    final cfg = store.settings.reminder;
    final morningMin = _toMin(cfg.morning);
    final eveMin = _toMin(cfg.eve);
    var changed = false;

    for (final t in tasks) {
      final d = t.dueDate;
      if (d == null) continue;
      final dueDay = DateTime(d.year, d.month, d.day);
      final days = today.difference(dueDay).inDays;
      if (days > 0 && due['o:${t.id}'] != true) {
        await _push('作业已逾期 $days 天', '${t.title}（${d.month}月${d.day}日截止）');
        due['o:${t.id}'] = true;
        changed = true;
      } else if (todayStr == _dateStr(d) && due['t:${t.id}'] != true) {
        if (minutes >= morningMin && minutes <= morningMin + 120) {
          await _push('今天截止：${t.title}', '${d.month}月${d.day}日 · 记得完成');
          due['t:${t.id}'] = true;
          changed = true;
        }
      } else if (due['tm:${t.id}'] != true && _isTomorrow(d, today)) {
        if (minutes >= eveMin) {
          await _push('明天截止：${t.title}', '提前安排，别拖到最后');
          due['tm:${t.id}'] = true;
          changed = true;
        }
      }
    }
    if (changed) {
      store.updateSettings({'notifiedDue': due});
    }
  }

  /// 检查便签提醒（对齐网页版 checkNotes）。
  Future<void> checkNotes(AppStore store) async {
    if (!store.settings.notifications) return;
    final notes = store.notes.where((n) => !n.isDeleted && n.remindAt != null);
    final now = DateTime.now();
    final map = Map<String, bool>.from(store.settings.notifiedNotes);
    var changed = false;
    for (final Note n in notes) {
      if (map[n.id] != true && !now.isBefore(n.remindAt!)) {
        await _push(
          '便签提醒',
          n.title.isNotEmpty ? n.title : (n.content.length > 30 ? n.content.substring(0, 30) : n.content),
        );
        map[n.id] = true;
        changed = true;
      }
    }
    if (changed) {
      store.updateSettings({'notifiedNotes': map});
    }
  }

  Future<void> checkAll(AppStore store) async {
    await init();
    await checkDue(store);
    await checkNotes(store);
  }

  static bool _isTomorrow(DateTime d, DateTime today) {
    final tomorrow = today.add(const Duration(days: 1));
    return d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int _toMin(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 20;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return h * 60 + m;
  }
}
