/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// 科目配置：名称 / 马卡龙配色 / 是否启用。
class SubjectConfig {
  final String name;
  final String colorHex;
  final bool enabled;

  const SubjectConfig({
    required this.name,
    required this.colorHex,
    this.enabled = true,
  });

  SubjectConfig copyWith({String? name, String? colorHex, bool? enabled}) {
    return SubjectConfig(
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'color': colorHex, 'enabled': enabled};

  factory SubjectConfig.fromJson(Map<String, dynamic> json) => SubjectConfig(
        name: (json['name'] as String?) ?? '默认',
        colorHex: (json['color'] as String?) ?? '#C9C7F0',
        enabled: json['enabled'] != false,
      );
}
