/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/update_service.dart';
import '../../data/update_prefs.dart';
import '../../models/update_info.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';

/// 检查更新结果：无更新 → 提示已最新；有更新 → 弹出更新对话框。
Future<void> showCheckUpdateResult(
  BuildContext context, {
  UpdateInfo? update,
  UpdateService? service,
}) async {
  if (update == null) {
    showSugarToast(context, '已是最新版本');
    return;
  }
  await showUpdateDialog(context, update, service: service);
}

/// 更新对话框：版本号 + 更新说明 + 下载进度 + 安装。
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo update, {
  UpdateService? service,
  UpdatePrefs? prefs,
}) {
  return showSugarDialog(
    context,
    builder: (ctx) => SugarDialogBox(
      child: _UpdateDialog(
        update: update,
        service: service ?? const UpdateService(),
        prefs: prefs,
      ),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo update;
  final UpdateService service;
  final UpdatePrefs? prefs;

  const _UpdateDialog({
    required this.update,
    required this.service,
    this.prefs,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _starting = false;
  double? _progress;
  String? _error;

  /// 当前平台在 updates/latest.json 中的 key。
  static String get _platformKey {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    return 'other';
  }

  /// v0.31.0 起：立即升级。
  /// Android → 系统下载管理器后台下载（通知栏进度）；
  /// Windows/桌面 → 前台下载并显示进度，校验后拉起安装器。
  Future<void> _startUpdate() async {
    final entry = widget.update.platforms[_platformKey];
    if (entry == null) {
      setState(() => _error = '当前平台暂无可用安装包');
      return;
    }
    setState(() {
      _starting = true;
      _progress = null;
      _error = null;
    });
    try {
      if (Platform.isAndroid) {
        await widget.service.startBackgroundDownload(
          entry,
          widget.update.version,
        );
        if (!mounted) return;
        Navigator.pop(context);
        showSugarToast(context, '已开始后台下载，可在通知栏查看进度');
        return;
      }
      // 桌面端：前台下载 + 校验 + 拉起安装器
      final file = await widget.service.downloadAndVerify(
        entry,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await widget.service.install(file);
      if (!mounted) return;
      if (Platform.isWindows) {
        // 静默安装器已启动，本应用退出（安装器独立进程）
        exit(0);
      } else {
        Navigator.pop(context);
        showSugarToast(context, '安装器已启动，安装完成后即可使用新版本');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _ignoreVersion() async {
    await widget.prefs?.setIgnoredVersion(widget.update.version);
    if (!mounted) return;
    Navigator.pop(context);
    showSugarToast(context, '已忽略此版本，之后不再提醒');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SugarIcon('download', size: 17, color: t.iconMain),
              const SizedBox(width: 6),
              Text(
                '发现新版本 v${widget.update.version}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const Spacer(),
              PressableScale(
                onTap: () => Navigator.pop(context),
                child: SugarIcon('close', size: 18, color: t.text3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.update.notes.isNotEmpty) ...[
            Text(
              '更新说明',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.text2),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.update.notes,
                style: TextStyle(fontSize: 12, height: 1.6, color: t.text2),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(fontSize: 11.5, color: t.dangerStrong),
            ),
            const SizedBox(height: 8),
          ],
          if (_starting) ...[
            if (_progress != null) ...[
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: t.surface2,
                  color: t.iconMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '正在下载更新包… ${(_progress! * 100).round()}%',
                style: TextStyle(fontSize: 12, color: t.text2),
              ),
            ] else ...[
              Text(
                '正在准备下载…',
                style: TextStyle(fontSize: 12, color: t.text2),
              ),
            ],
          ] else ...[
            Text(
              Platform.isAndroid
                  ? '升级将在后台下载，通知栏可查看进度，不影响当前使用。'
                  : '将下载安装包并校验完整性，下载完成后自动启动安装器。',
              style: TextStyle(fontSize: 11.5, color: t.text3),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SugarButton(
                label: '忽略此版本',
                danger: true,
                compact: true,
                onTap: _starting ? null : _ignoreVersion,
              ),
              const SizedBox(width: 6),
              SugarButton(
                label: '稍后再说',
                compact: true,
                onTap: _starting ? null : () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              SugarButton(
                label: _starting
                    ? (_progress != null
                        ? '下载中 ${(_progress! * 100).round()}%'
                        : '启动中…')
                    : '立即升级',
                iconName: 'download',
                primary: true,
                onTap: _starting ? null : _startUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
