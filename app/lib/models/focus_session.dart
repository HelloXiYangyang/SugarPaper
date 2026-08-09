/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/// 专注会话（v5.0 新增）：记录番茄钟/倒计时/无限专注时长。
class FocusSession {
  final String id;
  final String? taskId;
  final String taskTitle;
  final String? subject; // 对齐网页版：关联任务科目
  final DateTime startedAt;
  final int durationSec;
  final int pomodoros; // 完成的番茄数
  final String soundScene; // 白噪音场景（对齐网页版 sceneId）

  const FocusSession({
    required this.id,
    this.taskId,
    this.taskTitle = '自由专注',
    this.subject,
    required this.startedAt,
    required this.durationSec,
    this.pomodoros = 1,
    this.soundScene = 'none',
  });

  /// 与网页版 `store.js` 的 focusSessions 字段互通：
  /// 同时输出 canonical（startAt/endAt/minutes/…）与本地字段，保证双向可读。
  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'subject': subject,
        'sceneId': soundScene,
        'startAt': startedAt.toUtc().toIso8601String(),
        'endAt': startedAt
            .add(Duration(seconds: durationSec))
            .toUtc()
            .toIso8601String(),
        'minutes': (durationSec / 60).ceil(),
        'completed': true,
        'source': 'pomodoro',
        'updatedAt': startedAt
            .add(Duration(seconds: durationSec))
            .toUtc()
            .toIso8601String(),
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationSec': durationSec,
        'pomodoros': pomodoros,
        'soundScene': soundScene,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    // canonical 优先（网页版字段），兼容旧版本地字段
    final startRaw = (json['startAt'] ?? json['startedAt']);
    final startedAt = startRaw is String
        ? DateTime.tryParse(startRaw)?.toLocal() ?? DateTime.now()
        : DateTime.now();
    final minutes = (json['minutes'] as num?)?.toInt();
    final durationSec = (json['durationSec'] as num?)?.toInt() ??
        (minutes != null ? minutes * 60 : 0);
    final endRaw = json['endAt'];
    final endAt = endRaw is String ? DateTime.tryParse(endRaw) : null;
    final duration = endAt != null && startedAt != DateTime.now()
        ? endAt.difference(startedAt).inSeconds
        : null;
    return FocusSession(
      id: (json['id'] as String?) ??
          'f${DateTime.now().microsecondsSinceEpoch}',
      taskId: json['taskId'] as String?,
      taskTitle: (json['taskTitle'] as String?) ?? '自由专注',
      subject: json['subject'] as String?,
      startedAt: startedAt,
      durationSec: duration ?? durationSec,
      pomodoros: (json['pomodoros'] as num?)?.toInt() ?? 1,
      soundScene: (json['soundScene'] as String?) ??
          (json['sceneId'] as String?) ??
          'none',
    );
  }
}
