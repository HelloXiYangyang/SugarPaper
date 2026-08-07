/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/update_service.dart';
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
}) {
  return showSugarDialog(
    context,
    builder: (ctx) => SugarDialogBox(
      child: _UpdateDialog(
        update: update,
        service: service ?? const UpdateService(),
      ),
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo update;
  final UpdateService service;

  const _UpdateDialog({required this.update, required this.service});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    final platform = Platform.isAndroid ? 'android' : 'other';
    final entry = widget.update.platforms[platform];
    if (entry == null) {
      setState(() => _error = '当前平台暂无可用安装包');
      return;
    }
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    try {
      final file = await widget.service.downloadAndVerify(
        entry,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSugarToast(context, '下载完成，正在打开安装器…');
      await widget.service.install(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e.toString();
      });
    }
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
              SugarIcon('download', size: 17, color: t.pinkStrong),
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
          if (_downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: t.surface2,
                color: t.pinkStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_progress * 100).round()}%',
              style: TextStyle(fontSize: 11, color: t.text3),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SugarButton(
                label: _downloading ? '下载中…' : '稍后',
                onTap: _downloading ? null : () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              SugarButton(
                label: _downloading ? '正在下载' : '下载更新',
                iconName: 'download',
                primary: true,
                onTap: _downloading ? null : _download,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
