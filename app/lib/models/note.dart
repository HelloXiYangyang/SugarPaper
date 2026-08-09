/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/// 便签（v5.0 新增模块）：轻量速记，与作业联动。
class Note {
  final String id;
  final String title;
  final String content;
  final String colorHex; // 马卡龙 8 色
  bool pinned;
  bool archived;
  bool isDeleted;
  DateTime? remindAt; // v0.15.0 便签提醒时间
  List<String> images; // v0.19.0 图片附件（dataURL，最多 4 张，最长边 512px）
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.colorHex = '#FBE4EC',
    this.pinned = false,
    this.archived = false,
    this.isDeleted = false,
    this.remindAt,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    String? colorHex,
    bool? pinned,
    bool? archived,
    bool? isDeleted,
    DateTime? remindAt,
    List<String>? images,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      isDeleted: isDeleted ?? this.isDeleted,
      remindAt: remindAt ?? this.remindAt,
      images: images ?? this.images,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'color': colorHex,
        'pinned': pinned,
        'archived': archived,
        'isDeleted': isDeleted,
        'remindAt': remindAt?.toUtc().toIso8601String(),
        'images': images,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: (json['id'] as String?) ?? 'n${DateTime.now().microsecondsSinceEpoch}',
        title: (json['title'] as String?) ?? '',
        content: (json['content'] as String?) ?? '',
        colorHex: (json['colorHex'] as String?) ??
            (json['color'] as String?) ??
            '#FBE4EC',
        pinned: json['pinned'] == true,
        archived: json['archived'] == true,
        isDeleted: json['isDeleted'] == true,
        remindAt: json['remindAt'] is String
            ? DateTime.tryParse(json['remindAt'] as String)?.toLocal()
            : null,
        images: (json['images'] as List?)?.whereType<String>().toList() ??
            const [],
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)?.toLocal() ??
                DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)?.toLocal() ??
                DateTime.now()
            : DateTime.now(),
      );
}
