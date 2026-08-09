/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter/services.dart';

/// 平台能力矩阵（v0.31.0 初建，desktop 扩展 v0.32.0）。
/// 同一版本号下按系统 API level 分级：高版本全功能，低版本隐藏不支持项。
class DeviceCapabilities {
  static const MethodChannel _channel = MethodChannel('sugarpaper/device');

  static int _sdkInt = 24;
  static bool _loaded = false;

  /// 桌面端：Windows 视为 desktop。
  static bool get isDesktop => !Platform.isAndroid;

  /// 启动时读取系统 API level 并缓存（settings 等页面同步读取）。
  static Future<void> init() async {
    try {
      _sdkInt = await _channel.invokeMethod<int>('sdkInt') ?? 24;
    } catch (_) {
      _sdkInt = 24;
    }
    _loaded = true;
  }

  static int get sdkInt => _loaded ? _sdkInt : 24;

  /// 通知提醒：Windows 系统通知 / Android 8.0+ 通知渠道。
  static bool get hasNotifications => isDesktop || sdkInt >= 26;

  /// Android 11+（API 30）：高刷新率档位（90/120 帧）
  static bool get hasHighRefreshRate => sdkInt >= 30;

  /// 系统下载管理器（Android 5.0+ 全版本可用）：后台下载更新。
  /// 桌面端使用前台下载（update_dialog 内直接显示进度）。
  static bool get hasBackgroundDownload => !isDesktop && sdkInt >= 21;

  /// 发起系统下载管理器后台下载（通知栏自动显示进度，不占前台）。
  /// 返回系统 download id。
  static Future<int> startBackgroundDownload({
    required String url,
    required String fileName,
    required String title,
  }) async {
    final id = await _channel.invokeMethod<int>('downloadInBackground', {
      'url': url,
      'fileName': fileName,
      'title': title,
    });
    return id ?? -1;
  }

  /// 设置后台下载完成回调（由 main.dart 启动时注册）。
  static void setDownloadCompleteHandler(Future<void> Function(bool, String) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDownloadComplete') {
        final args = call.arguments as Map?;
        await handler(args?['success'] == true, args?['fileName'] as String? ?? '');
      }
    });
  }
}
