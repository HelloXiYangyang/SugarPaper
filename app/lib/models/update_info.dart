/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/// 更新元数据（对齐《零服务器多平台发布·自动更新·官网方案 v2.0》的 update.json）。
class UpdateInfo {
  final String app;
  final String version;
  final int build;
  final String publishedAt;
  final String notes;
  final Map<String, UpdatePlatformEntry> platforms;

  const UpdateInfo({
    required this.app,
    required this.version,
    required this.build,
    required this.publishedAt,
    required this.notes,
    required this.platforms,
  });

  static UpdateInfo? fromJson(Map<String, dynamic> json) {
    final latest = json['latest'];
    if (latest is! Map) return null;
    final platforms = <String, UpdatePlatformEntry>{};
    final p = json['platforms'];
    if (p is Map) {
      p.forEach((key, value) {
        if (value is Map && value['url'] != null) {
          platforms[key.toString()] = UpdatePlatformEntry(
            url: value['url'] as String,
            sha256: (value['sha256'] as String?) ?? '',
          );
        }
      });
    }
    return UpdateInfo(
      app: (json['app'] as String?) ?? 'SugarPaper',
      version: (latest['version'] as String?) ?? '',
      build: (latest['build'] as num?)?.toInt() ?? 0,
      publishedAt: (latest['published_at'] as String?) ?? '',
      notes: (latest['notes'] as String?) ?? '',
      platforms: platforms,
    );
  }
}

/// 单个平台的下载条目。
class UpdatePlatformEntry {
  final String url;
  final String sha256;

  const UpdatePlatformEntry({required this.url, required this.sha256});
}
