/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import '../models/subject_config.dart';

/// 默认学科清单（v4.1 统一）：覆盖小学/初中/高中，全平台保持一致。
const List<SubjectConfig> kDefaultSubjects = [
  SubjectConfig(name: '语文', colorHex: '#F4B8CE'),
  SubjectConfig(name: '数学', colorHex: '#B3D4F0'),
  SubjectConfig(name: '英语', colorHex: '#C9C7F0'),
  SubjectConfig(name: '物理', colorHex: '#A9E0CB'),
  SubjectConfig(name: '化学', colorHex: '#FBE6B9'),
  SubjectConfig(name: '生物', colorHex: '#BFE8C9'),
  SubjectConfig(name: '历史', colorHex: '#E8D5F0'),
  SubjectConfig(name: '地理', colorHex: '#C9E8F0'),
  SubjectConfig(name: '政治', colorHex: '#F0C9C9'),
  SubjectConfig(name: '体育与健康', colorHex: '#FAD1B8'),
  SubjectConfig(name: '音乐', colorHex: '#F5C4DC'),
  SubjectConfig(name: '美术', colorHex: '#F2D4A8'),
  SubjectConfig(name: '信息技术', colorHex: '#B8D8E8'),
  SubjectConfig(name: '通用技术', colorHex: '#C8D8C0'),
  SubjectConfig(name: '劳动', colorHex: '#F0DEB8'),
  SubjectConfig(name: '综合实践活动', colorHex: '#D8C8F0'),
];

/// 科目管理配色面板（与 Web 版 COLOR_PALETTE 一致）
const List<String> kSubjectPalette = [
  '#F4B8CE', '#A9E0CB', '#B3D4F0', '#C9C7F0',
  '#FBE6B9', '#BFE8C9', '#E8D5F0', '#C9E8F0',
  '#F0C9C9', '#FAD1B8', '#F5C4DC', '#F2D4A8',
  '#B8D8E8', '#C8D8C0', '#F0DEB8', '#D8C8F0',
];

/// 七套平行主题
const List<String> kThemes = [
  'classic', 'bluegreen', 'sunshine', 'rose', 'lavender', 'mint', 'dark',
];

const Map<String, String> kThemeLabels = {
  'classic': '经典白',
  'bluegreen': '清新蓝绿',
  'sunshine': '阳光黄桃',
  'rose': '玫瑰粉',
  'lavender': '梦幻紫',
  'mint': '薄荷绿',
  'dark': '暗色',
};

const Map<String, List<Color>> kThemeGradients = {
  'classic': [Color(0xFFFBF6F2), Color(0xFFF4B8CE)],
  'bluegreen': [Color(0xFF9ED8C6), Color(0xFFB0CFF0)],
  'sunshine': [Color(0xFFF8CE9E), Color(0xFFDFE3A0)],
  'rose': [Color(0xFFF5BCC4), Color(0xFFE0C4E8)],
  'lavender': [Color(0xFFD5C8F2), Color(0xFFC9B8EC)],
  'mint': [Color(0xFFBFE8C9), Color(0xFFA9E0CB)],
  'dark': [Color(0xFF2E2738), Color(0xFF4A3F47)],
};

/// 响应式断点（五档，PRD §5.1）
const double kCompactMax = 600;
const double kMediumMax = 840;
const double kExpandedMax = 1200;
const double kLargeMax = 1600;

/// 动画时长（PRD §6.1 组件微动画清单，Web 版基准）
class AnimDurations {
  static const pageTransition = Duration(milliseconds: 220);
  static const cardReveal = Duration(milliseconds: 450);
  static const taskSlideOut = Duration(milliseconds: 240);
  static const pressFeedback = Duration(milliseconds: 120);
  static const switchSpring = Duration(milliseconds: 300);
  static const calendarCell = Duration(milliseconds: 320);
  static const barGrow = Duration(milliseconds: 500);
  static const lineDraw = Duration(milliseconds: 1100);
  static const pieLoad = Duration(milliseconds: 1400);
  static const pieBlossom = Duration(milliseconds: 550);
  static const ringFade = Duration(milliseconds: 500);
  static const progressShimmer = Duration(milliseconds: 3200);
  static const dialogPop = Duration(milliseconds: 220);
  static const staggerFade = Duration(milliseconds: 280);

  /// 120 帧档位自动缩短动画时长（PRD v4.6）
  static Duration speed(Duration d, String frameRate) {
    if (frameRate == '120') {
      return Duration(milliseconds: (d.inMilliseconds * 0.8).round());
    }
    return d;
  }
}
