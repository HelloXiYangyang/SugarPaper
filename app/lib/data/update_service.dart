/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'device_capabilities.dart';
import '../models/update_info.dart';

/// 零服务器自动更新（v0.27.0，对齐《零服务器多平台发布·自动更新·官网方案 v2.0》）：
/// 读 GitHub Pages 上的 updates/latest.json → 比较 build 号 →
/// 流式下载 → SHA-256 校验 → 交给系统安装器。
class UpdateService {
  /// 元数据地址（GitHub Pages 静态托管，无 API 限流）。
  static const String defaultMetadataUrl =
      'https://helloxiyangyang.github.io/SugarPaper/updates/latest.json';

  final String metadataUrl;

  const UpdateService({this.metadataUrl = defaultMetadataUrl});

  // 后台下载待校验信息（下载前记录，完成后按文件名匹配）
  static String? _pendingFile;
  static String? _pendingSha256;

  /// 检查更新：远端 build > 本地 build 时返回更新信息，否则返回 null。
  Future<UpdateInfo?> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final localBuild = int.tryParse(info.buildNumber) ?? 0;
    final resp = await Dio().get<Map<String, dynamic>>(
      metadataUrl,
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    final data = resp.data;
    if (data == null) return null;
    final update = UpdateInfo.fromJson(data);
    if (update == null || update.build <= localBuild) return null;
    return update;
  }

  /// 流式下载 + SHA-256 校验，返回下载好的文件。
  Future<File> downloadAndVerify(
    UpdatePlatformEntry entry, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = _extFromUrl(entry.url);
    final file = File(
      '${dir.path}${Platform.pathSeparator}sugarpaper-update-$ext',
    );
    await Dio().download(
      entry.url,
      file.path,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );
    final hash = await _sha256File(file);
    if (entry.sha256.isNotEmpty &&
        !hash.toLowerCase().startsWith(entry.sha256.toLowerCase())) {
      throw StateError('SHA-256 校验失败，已中止安装');
    }
    return file;
  }

  /// v0.31.0：系统下载管理器后台下载（通知栏进度，不占前台）。
  /// 下载完成后系统通知栏出现「下载完成」，点击可直接安装；
  /// 同时通过 [handleBackgroundDownloadComplete] 校验后自动拉起安装器。
  Future<void> startBackgroundDownload(
    UpdatePlatformEntry entry,
    String version,
  ) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('桌面端使用前台下载（update_dialog 内显示进度）');
    }
    final fileName = 'sugarpaper-update-$version.apk';
    _pendingFile = fileName;
    _pendingSha256 = entry.sha256;
    final id = await DeviceCapabilities.startBackgroundDownload(
      url: entry.url,
      fileName: fileName,
      title: '糖纸 · SugarPaper v$version 更新',
    );
    if (id < 0) throw StateError('后台下载启动失败');
  }

  /// 后台下载完成回调：SHA-256 校验 → 拉起系统安装器。
  Future<void> handleBackgroundDownloadComplete(
    bool success,
    String fileName,
  ) async {
    if (!Platform.isAndroid) return; // 仅 Android 系统下载管理器使用
    if (!success || fileName != _pendingFile) return;
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      if (!await file.exists()) return;
      final hash = await _sha256File(file);
      final expected = _pendingSha256 ?? '';
      if (expected.isNotEmpty &&
          !hash.toLowerCase().startsWith(expected.toLowerCase())) {
        return; // 校验失败：不安装（用户可点系统通知重试）
      }
      await install(file);
    } catch (_) {
      // 后台完成时若 App 不可见，系统通知仍可触发安装
    }
  }

  /// 交给系统安装器：Android 调起 APK 安装；Windows 启动 setup.exe 静默安装。
  Future<void> install(File file) async {
    if (Platform.isAndroid) {
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw StateError('无法打开安装器：${result.message}');
      }
    } else if (Platform.isWindows) {
      if (!file.path.toLowerCase().endsWith('.exe')) {
        throw StateError('Windows 更新包必须是 .exe 安装器');
      }
      // v0.32.0：Inno Setup 静默安装（/VERYSILENT /NORESTART），
      // detached 启动后本应用可安全退出。
      await Process.start(
        file.path,
        const ['/VERYSILENT', '/NORESTART'],
        mode: ProcessStartMode.detached,
      );
    } else {
      throw UnsupportedError('当前平台不支持自动安装');
    }
  }

  /// 根据下载 URL 推导文件名后缀（无匹配时按平台回退）。
  static String _extFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.apk')) return 'apk';
    if (lower.contains('.exe')) return 'exe';
    if (lower.contains('.zip')) return 'zip';
    if (Platform.isWindows) return 'exe';
    if (Platform.isAndroid) return 'apk';
    return 'bin';
  }

  Future<String> _sha256File(File file) async {
    // 流式计算，避免大安装包整包读入内存
    final sink = Sha256().newHashSink();
    final stream = file.openRead();
    await for (final chunk in stream) {
      sink.add(chunk);
    }
    sink.close();
    final digest = await sink.hash();
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
