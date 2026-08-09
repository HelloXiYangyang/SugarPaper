/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/// 家庭成员档案（v0.17.0 家庭模式）。
class FamilyProfile {
  final String id;
  final String nickname;
  bool active;

  FamilyProfile({
    required this.id,
    required this.nickname,
    this.active = false,
  });

  FamilyProfile copyWith({String? nickname, bool? active}) => FamilyProfile(
        id: id,
        nickname: nickname ?? this.nickname,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'active': active,
      };

  factory FamilyProfile.fromJson(Map<String, dynamic> json) => FamilyProfile(
        id: (json['id'] as String?) ?? 'f${DateTime.now().microsecondsSinceEpoch}',
        nickname: (json['nickname'] as String?) ?? '家庭成员',
        active: json['active'] == true,
      );
}
