/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'subject_config.dart';
import 'family_profile.dart';

/// 提醒时间配置（v0.22.0，对齐网页版 settings.reminder）。
class ReminderConfig {
  final String eve; // 前一晚提醒时间，默认 20:00
  final String morning; // 当天早上提醒窗口起点，默认 07:00

  const ReminderConfig({this.eve = '20:00', this.morning = '07:00'});

  ReminderConfig copyWith({String? eve, String? morning}) =>
      ReminderConfig(eve: eve ?? this.eve, morning: morning ?? this.morning);

  Map<String, dynamic> toJson() => {'eve': eve, 'morning': morning};

  factory ReminderConfig.fromJson(Map<String, dynamic> json) => ReminderConfig(
        eve: (json['eve'] as String?) ?? '20:00',
        morning: (json['morning'] as String?) ?? '07:00',
      );
}

/// 自定义声音（v0.18.0，对齐网页版 settings.focus.customAudio）。
class CustomAudio {
  final String name;
  final String dataUrl; // data:audio/...;base64,...

  const CustomAudio({required this.name, required this.dataUrl});

  Map<String, dynamic> toJson() => {'name': name, 'dataUrl': dataUrl};

  factory CustomAudio.fromJson(Map<String, dynamic> json) => CustomAudio(
        name: (json['name'] as String?) ?? '自定义声音',
        dataUrl: (json['dataUrl'] as String?) ?? '',
      );
}

/// 专注场景配置（v0.18.0 对齐网页版 settings.focus）。
class FocusConfig {
  final String? sceneId; // 主场景
  final double volume; // 主场景音量 0-1
  final String? mixSceneId; // 叠加场景
  final double mixVolume; // 叠加音量 0-1
  final CustomAudio? customAudio; // 自定义声音

  const FocusConfig({
    this.sceneId,
    this.volume = 0.6,
    this.mixSceneId,
    this.mixVolume = 0.3,
    this.customAudio,
  });

  FocusConfig copyWith({
    String? sceneId,
    double? volume,
    String? mixSceneId,
    double? mixVolume,
    CustomAudio? customAudio,
    bool clearScene = false,
    bool clearMix = false,
    bool clearCustom = false,
  }) =>
      FocusConfig(
        sceneId: clearScene ? null : (sceneId ?? this.sceneId),
        volume: volume ?? this.volume,
        mixSceneId: clearMix ? null : (mixSceneId ?? this.mixSceneId),
        mixVolume: mixVolume ?? this.mixVolume,
        customAudio: clearCustom ? null : (customAudio ?? this.customAudio),
      );

  Map<String, dynamic> toJson() => {
        'sceneId': sceneId,
        'volume': volume,
        'mixSceneId': mixSceneId,
        'mixVolume': mixVolume,
        'customAudio': customAudio?.toJson(),
      };

  factory FocusConfig.fromJson(Map<String, dynamic> json) => FocusConfig(
        sceneId: json['sceneId'] as String?,
        volume: (json['volume'] as num?)?.toDouble() ?? 0.6,
        mixSceneId: json['mixSceneId'] as String?,
        mixVolume: (json['mixVolume'] as num?)?.toDouble() ?? 0.3,
        customAudio: json['customAudio'] is Map
            ? CustomAudio.fromJson(
                Map<String, dynamic>.from(json['customAudio'] as Map))
            : null,
      );
}

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
  final ReminderConfig reminder; // v0.22.0 提醒时间自定义
  final FocusConfig focus; // v0.18.0 专注场景配置
  final Map<String, int> rewardsGoals; // v0.32.0 激励目标（dailyXp / dailyTasks）
  final Map<String, dynamic> rewards; // v0.32.0 激励计数（comebackCount 等）
  final Map<String, String> achievements; // v0.32.0 已解锁徽章（id → ISO 时间）

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
    this.reminder = const ReminderConfig(),
    this.focus = const FocusConfig(),
    this.rewardsGoals = const {},
    this.rewards = const {},
    this.achievements = const {},
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
    ReminderConfig? reminder,
    FocusConfig? focus,
    Map<String, int>? rewardsGoals,
    Map<String, dynamic>? rewards,
    Map<String, String>? achievements,
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
      reminder: reminder ?? this.reminder,
      focus: focus ?? this.focus,
      rewardsGoals: rewardsGoals ?? this.rewardsGoals,
      rewards: rewards ?? this.rewards,
      achievements: achievements ?? this.achievements,
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
        'reminder': reminder.toJson(),
        'focus': focus.toJson(),
        'rewardsGoals': rewardsGoals,
        'rewards': rewards,
        'achievements': achievements,
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
      reminder: json['reminder'] is Map
          ? ReminderConfig.fromJson(
              Map<String, dynamic>.from(json['reminder'] as Map))
          : const ReminderConfig(),
      focus: json['focus'] is Map
          ? FocusConfig.fromJson(
              Map<String, dynamic>.from(json['focus'] as Map))
          : const FocusConfig(),
      rewardsGoals: (json['rewardsGoals'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          const {},
      rewards: json['rewards'] is Map
          ? Map<String, dynamic>.from(json['rewards'] as Map)
          : const {},
      achievements: (json['achievements'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v.toString())) ??
          const {},
    );
  }
}
