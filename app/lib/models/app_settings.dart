/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'subject_config.dart';
import 'family_profile.dart';

/// 应用设置（PRD §3 数据模型，v4.13 七套平行主题）。
class AppSettings {
  final bool notifications;
  final bool internetMode;
  final bool animations; // 动画总开关（false 时禁用全部动画，默认 true）
  final String frameRate; // 帧率模式：auto(跟随系统) / 60 / 120
  final String theme; // 主题：classic / bluegreen / sunshine / rose / lavender / mint / dark
  final String? avatar; // 头像：null=默认；data: 开头的图片 DataURL
  final String? lastSyncTime;
  final String? lastBackupAt; // v0.15.0 数据安全网：上次备份时间
  final Map<String, bool> notifiedDue; // v0.15.0 已提醒的截止任务（同条只提醒一次）
  final Map<String, bool> notifiedNotes; // v0.15.0 已提醒的便签
  final List<FamilyProfile> familyProfiles; // v0.17.0 家庭模式成员档案
  final List<String> relays; // v0.16.0 Nostr 中继列表
  final bool autoSync; // v0.16.0 自动同步开关
  final String deviceName;
  final List<SubjectConfig> subjects;

  const AppSettings({
    this.notifications = false,
    this.internetMode = false,
    this.animations = true,
    this.frameRate = 'auto',
    this.theme = 'classic',
    this.avatar,
    this.lastSyncTime,
    this.lastBackupAt,
    this.notifiedDue = const {},
    this.notifiedNotes = const {},
    this.familyProfiles = const [],
    this.relays = const [],
    this.autoSync = true,
    this.deviceName = '我的设备',
    this.subjects = const [],
  });

  AppSettings copyWith({
    bool? notifications,
    bool? internetMode,
    bool? animations,
    String? frameRate,
    String? theme,
    String? avatar,
    String? lastSyncTime,
    String? lastBackupAt,
    Map<String, bool>? notifiedDue,
    Map<String, bool>? notifiedNotes,
    List<FamilyProfile>? familyProfiles,
    List<String>? relays,
    bool? autoSync,
    String? deviceName,
    List<SubjectConfig>? subjects,
  }) {
    return AppSettings(
      notifications: notifications ?? this.notifications,
      internetMode: internetMode ?? this.internetMode,
      animations: animations ?? this.animations,
      frameRate: frameRate ?? this.frameRate,
      theme: theme ?? this.theme,
      avatar: avatar ?? this.avatar,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      notifiedDue: notifiedDue ?? this.notifiedDue,
      notifiedNotes: notifiedNotes ?? this.notifiedNotes,
      familyProfiles: familyProfiles ?? this.familyProfiles,
      relays: relays ?? this.relays,
      autoSync: autoSync ?? this.autoSync,
      deviceName: deviceName ?? this.deviceName,
      subjects: subjects ?? this.subjects,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'notifications': notifications,
        'internetMode': internetMode,
        'animations': animations,
        'frameRate': frameRate,
        'theme': theme,
        'avatar': avatar,
        'lastSyncTime': lastSyncTime,
        'lastBackupAt': lastBackupAt,
        'notifiedDue': notifiedDue,
        'notifiedNotes': notifiedNotes,
        'familyProfiles': familyProfiles.map((p) => p.toJson()).toList(),
        'relays': relays,
        'autoSync': autoSync,
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final subjects = (json['subjects'] as List?)
            ?.whereType<Map>()
            .map((e) => SubjectConfig.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <SubjectConfig>[];
    // v0.14.0 迁移：旧 darkMode / palette 收敛为 theme
    var theme = json['theme'] as String?;
    if (theme == null) {
      theme = json['darkMode'] == true ? 'dark' : (json['palette'] ?? 'classic');
    }
    return AppSettings(
      deviceName: (json['deviceName'] as String?) ?? '我的设备',
      notifications: json['notifications'] == true,
      internetMode: json['internetMode'] == true,
      animations: json['animations'] != false,
      frameRate: (json['frameRate'] as String?) ?? 'auto',
      theme: theme ?? 'classic',
      avatar: json['avatar'] as String?,
      lastSyncTime: json['lastSyncTime'] as String?,
      lastBackupAt: json['lastBackupAt'] as String?,
      notifiedDue: (json['notifiedDue'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v == true),
          ) ??
          const {},
      notifiedNotes: (json['notifiedNotes'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v == true),
          ) ??
          const {},
      familyProfiles: (json['familyProfiles'] as List?)
              ?.whereType<Map>()
              .map((e) => FamilyProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      relays: (json['relays'] as List?)?.whereType<String>().toList() ??
          const [],
      autoSync: json['autoSync'] != false,
      subjects: subjects,
    );
  }
}
