/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// 专注会话（v5.0 新增）：记录番茄钟/倒计时/无限专注时长。
class FocusSession {
  final String id;
  final String? taskId;
  final String taskTitle;
  final DateTime startedAt;
  final int durationSec;
  final int pomodoros; // 完成的番茄数
  final String soundScene; // 白噪音场景

  const FocusSession({
    required this.id,
    this.taskId,
    this.taskTitle = '自由专注',
    required this.startedAt,
    required this.durationSec,
    this.pomodoros = 1,
    this.soundScene = 'none',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'startedAt': startedAt.toIso8601String(),
        'durationSec': durationSec,
        'pomodoros': pomodoros,
        'soundScene': soundScene,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: (json['id'] as String?) ?? 'f${DateTime.now().microsecondsSinceEpoch}',
        taskId: json['taskId'] as String?,
        taskTitle: (json['taskTitle'] as String?) ?? '自由专注',
        startedAt: json['startedAt'] is String
            ? DateTime.tryParse(json['startedAt'] as String)?.toLocal() ??
                DateTime.now()
            : DateTime.now(),
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        pomodoros: (json['pomodoros'] as num?)?.toInt() ?? 1,
        soundScene: (json['soundScene'] as String?) ?? 'none',
      );
}
