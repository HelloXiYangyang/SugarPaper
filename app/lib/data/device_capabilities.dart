/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/services.dart';

/// v0.31.0：Android 版本能力矩阵。
/// 同一版本号下按系统 API level 分级：高版本全功能，低版本隐藏不支持项。
class DeviceCapabilities {
  static const MethodChannel _channel = MethodChannel('sugarpaper/device');

  static int _sdkInt = 24;
  static bool _loaded = false;

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

  /// Android 8.0+（API 26）：通知渠道 / 提醒功能完整
  static bool get hasNotifications => sdkInt >= 26;

  /// Android 11+（API 30）：高刷新率档位（90/120 帧）
  static bool get hasHighRefreshRate => sdkInt >= 30;

  /// 系统下载管理器（API 9+ 全版本可用）：后台下载更新
  static bool get hasBackgroundDownload => sdkInt >= 21;

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
