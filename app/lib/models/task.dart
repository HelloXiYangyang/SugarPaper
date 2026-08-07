/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// 作业任务模型，字段与 PRD §3 / Web 版 `store.js` 完全一致。
class Task {
  final String id; // UUID v4
  final String subject; // 科目名
  final String title; // 主描述
  final String subtitle; // 附加描述
  bool isCompleted;
  int order; // 手动排序
  DateTime createdAt;
  DateTime updatedAt; // 冲突解决依据
  bool isDeleted; // 软删除
  DateTime? completedAt; // 实际完成时间（用于统计）
  DateTime? dueDate; // 截止日期（日历视图使用，仅日期部分）
  int priority; // 优先级 0-2 (低/中/高)
  String taskType; // v0.17.0：checkin(打卡) / recite(背诵) / written(书面)
  bool confirmed; // v0.17.0：家庭模式家长确认（打卡类任务）
  List<String> images; // v0.22.0 作业拍照存档（dataURL，最多 4 张，最长边 512px）

  Task({
    required this.id,
    required this.subject,
    required this.title,
    this.subtitle = '',
    this.isCompleted = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.completedAt,
    this.dueDate,
    this.priority = 1,
    this.taskType = 'written',
    this.confirmed = false,
    this.images = const [],
  });

  Task copyWith({
    String? id,
    String? subject,
    String? title,
    String? subtitle,
    bool? isCompleted,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? completedAt,
    DateTime? dueDate,
    int? priority,
    String? taskType,
    bool? confirmed,
    List<String>? images,
  }) {
    return Task(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      taskType: taskType ?? this.taskType,
      confirmed: confirmed ?? this.confirmed,
      images: images ?? this.images,
    );
  }

  /// 与 Web 版 `store.js` 的 JSON 字段一一对应，可直接互导备份。
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'title': title,
        'subtitle': subtitle,
        'isCompleted': isCompleted,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'completedAt': completedAt?.toIso8601String(),
        'dueDate': dueDate == null ? null : _dateStr(dueDate!),
        'priority': priority,
        'taskType': taskType,
        'confirmed': confirmed,
        'images': images,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'];
    final dueDate = json['dueDate'];
    return Task(
      id: (json['id'] as String?) ?? _uuid(),
      subject: (json['subject'] as String?) ?? '默认',
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      isCompleted: json['isCompleted'] == true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: _parseIso(json['createdAt']),
      updatedAt: _parseIso(json['updatedAt']),
      isDeleted: json['isDeleted'] == true,
      completedAt: completedAt == null ? null : _parseIso(completedAt),
      dueDate: dueDate == null ? null : _parseDateStr(dueDate as String),
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      taskType: (json['taskType'] as String?) ?? 'written',
      confirmed: json['confirmed'] == true,
      images: (json['images'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }
}

String _dateStr(DateTime d) =>
    '${d.year}-${_pad(d.month)}-${_pad(d.day)}';

String _pad(int n) => n.toString().padLeft(2, '0');

DateTime _parseIso(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

DateTime? _parseDateStr(String s) {
  final parts = s.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((p) => p == null)) return null;
  return DateTime(parts[0]!, parts[1]! - 1, parts[2]!);
}

String _uuid() {
  final r = DateTime.now().millisecondsSinceEpoch;
  return 't$r-${r.toRadixString(16)}';
}
