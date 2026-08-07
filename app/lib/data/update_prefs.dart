/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// v0.31.0：更新偏好（忽略的版本号等），独立持久化。
class UpdatePrefs {
  static const String _fileName = 'sugarpaper_update_prefs.json';

  String ignoredVersion = ''; // 用户选择「忽略此版本」的版本号

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
          ignoredVersion = (raw['ignoredVersion'] as String?) ?? '';
        }
      }
    } catch (_) {}
  }

  Future<void> setIgnoredVersion(String version) async {
    ignoredVersion = version;
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'ignoredVersion': ignoredVersion,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }
}
