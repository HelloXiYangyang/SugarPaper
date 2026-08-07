/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 用户协议 / 隐私政策同意状态（v0.28.0）。
/// 独立于业务数据备份文件持久化，避免与可导入导出的备份耦合。
class LegalStore {
  static const String legalVersion = 'v1.0.0';
  static const String _fileName = 'sugarpaper_legal.json';

  String agreedVersion = '';

  /// 用于测试时注入目录；null 时使用应用文档目录。
  Directory? overrideDir;

  Future<Directory> _dir() async {
    if (overrideDir != null) return overrideDir!;
    return getApplicationDocumentsDirectory();
  }

  Future<void> load() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is Map) {
          agreedVersion = (raw['agreedVersion'] as String?) ?? '';
        }
      }
    } catch (_) {
      // 读取失败视为未同意，不阻塞启动
    }
  }

  bool get isAgreed => agreedVersion == legalVersion;

  Future<void> agree() async {
    agreedVersion = legalVersion;
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'app': 'SugarPaper',
          'agreedVersion': agreedVersion,
          'agreedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // 写入失败：本次会话仍视为已同意，下次启动重新确认
    }
  }
}
