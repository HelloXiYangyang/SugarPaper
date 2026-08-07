/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import 'svg_path.dart';

/// 描边风格 UI 图标（24×24 视口，stroke=currentColor，线宽 1.8，圆角端点）。
/// path 数据与 Web 版 `web/js/icons.js` 完全一致（PRD §5.8 跨平台基准）。
const Map<String, String> kStrokeIcons = {
  'home': 'M3 10.5 12 3l9 7.5M5 9.5V21h14V9.5M9 21v-6h6v6',
  'calendar': 'M6 5h12a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V8a3 3 0 0 1 3-3zM8 3v4M16 3v4M3 10h18',
  'chart-bar': 'M4 20v-9M10 20V5M16 20v-12M3 20h18',
  'chart-line': 'M3 20h18m-17 0 5-6 4 3 6-8',
  'chart-pie': 'M12 3a9 9 0 1 0 9 9h-9zM15 3.5A9 9 0 0 1 20.5 9H15z',
  'user': 'M12 8a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c0-4 3.6-6 8-6s8 2 8 6',
  'plus': 'M12 5v14M5 12h14',
  'search': 'M11 11a7 7 0 1 0 0-14 7 7 0 0 0 0 14zm9 9-3.5-3.5',
  'edit': 'M4 20h4L19 9l-4-4L4 16zM13 7l4 4',
  'trash': 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
  'check': 'm5 12 5 5 9-10',
  'undo': 'M9 14 4 9l5-5M4 9h10a6 6 0 0 1 0 12h-3',
  'chevron-up': 'm6 14 6-6 6 6',
  'chevron-down': 'm6 10 6 6 6-6',
  'chevron-left': 'm14 6-6 6 6 6',
  'chevron-right': 'm10 6 6 6-6 6',
  'pause': 'M8 5v14M16 5v14',
  'music':
      'M9 18V5l10-2v13M4 18a3 3 0 1 0 6 0 3 3 0 1 0-6 0zM14 16a3 3 0 1 0 6 0 3 3 0 1 0-6 0z',
  'mic':
      'M9 6v5a3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3zM5 11a7 7 0 0 0 14 0M12 18v3',
  'flag': 'M5 21V4M5 4h11l-2 4 2 4H5',
  'download': 'M12 3v12M7 10l5 5 5-5M4 21h16',
  'upload': 'M12 15V3M7 8l5-5 5 5M4 21h16',
  'moon': 'M20 14A8 8 0 1 1 10 4a7 7 0 0 0 10 10z',
  'bell': 'M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6M10 20a2 2 0 0 0 4 0',
  'globe': 'M12 12a9 9 0 1 0 0-18 9 9 0 0 0 0 18zm-9 0h18M12 3c2.5 2.6 4 5.7 4 9s-1.5 6.4-4 9c-2.5-2.6-4-5.7-4-9s1.5-6.4 4-9',
  'sparkles': 'M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9zM18.5 14l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z',
  'book': 'M4 5a2 2 0 0 1 2-2h14v18H6a2 2 0 0 0-2 2zM4 19a2 2 0 0 1 2-2h14',
  'camera': 'M4 8h3l2-3h6l2 3h3v12H4zM12 13a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
  'image': 'M6 4h12a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V7a3 3 0 0 1 3-3zM9 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm-5 9 5-5 3 3 4-4 4 4',
  'close': 'M6 6l12 12M18 6 6 18',
  'eye': 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7zm10-3a3 3 0 1 0 0 6 3 3 0 0 0 0-6z',
  'gauge': 'M5 19a9 9 0 1 1 14 0M12 13l4-4M12 13a1.6 1.6 0 1 0 0-3.2 1.6 1.6 0 0 0 0 3.2z',
  'bolt': 'M13 2 4 14h7l-1 8 9-12h-7z',
  'save': 'M5 3h11l5 5v13H5zM8 3v6h8V3M8 21v-8h8v8',
  'file-text': 'M6 3h9l5 5v13H6zM14 3v6h6M9 12h6M9 16h6',
  'paperclip': 'M9 4v11a4 4 0 0 0 8 0V6M17 6v9a6 6 0 0 1-12 0V5',
  'list': 'M6 4h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2zM9 8h6M9 12h6M9 16h4',
  'pin': 'M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11zM12 10a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  'clock': 'M12 12a9 9 0 1 0 0-18 9 9 0 0 0 0 18zm0-5v5l3 2',
  'flame': 'M12 2c.8 2.5-.8 3.7-.8 5.5a2.8 2.8 0 0 0 5.6 0C19 9.5 21 12.5 21 16a9 9 0 1 1-18 0c0-4 2.5-7.5 5-9-.3 1.6.5 2.6 1.6 3.2C9.2 6 10 3.5 12 2z',
  'sun': 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm0-10v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
  'help': 'M12 12a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9a2.5 2.5 0 1 1 3.6 2.2c-.7.4-1.1.9-1.1 1.8M12 17h.01',
  'target': 'M12 12a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0-4a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm0-3a1 1 0 1 0 0-2 1 1 0 0 0 0 2z',
  'candy': 'M12 10a5.5 5.5 0 1 0 0-11 5.5 5.5 0 0 0 0 11zm0 5.5V21M9.5 18.5h5M12 4.5a5.5 5.5 0 0 1 5.5 5.5',
};

/// 填充风格头像（fill=currentColor），保留用于扩展（PRD §5.8）。
const Map<String, String> kFillAvatars = {
  'person': 'M12 8a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21c0-4.2 3.6-7 8-7s8 2.8 8 7z',
  'star': 'M12 2l2.9 6.1 6.6.8-4.9 4.5 1.3 6.5L12 16.9 6.1 20l1.3-6.5L2.5 8.9l6.6-.8z',
  'heart': 'M12 20.5S3.5 15.8 2 11C1 7.8 3.5 4.5 6.8 4.5c2.2 0 3.8 1.4 5.2 3.2 1.4-1.8 3-3.2 5.2-3.2C20.5 4.5 23 7.8 22 11c-1.5 4.8-10 9.5-10 9.5z',
  'cat': 'M8.5 8 5 3.5l3.8 2M15.5 8 19 3.5l-3.8 2M5 13a7 7 0 0 1 14 0v4a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3z',
  'fox': 'M6 3l4 5.5 2-2 2 2L18 3l-1.2 6A7 7 0 1 1 7.2 9z',
  'bear': 'M8 8a2.2 2.2 0 1 0 0-4.4A2.2 2.2 0 0 0 8 8zm8 0a2.2 2.2 0 1 0 0-4.4A2.2 2.2 0 0 0 16 8zM4 13a8 8 0 0 1 16 0v4a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3z',
  'candy': 'M12 10a6 6 0 1 0 0-12 6 6 0 0 0 0 12zm0 6v5.5M9.3 18.5h5.4',
  'sparkle': 'M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z',
  'cloud':
      'M7 18h9.5a4 4 0 0 0 .6-7.9A6 6 0 0 0 5.3 9.6 4.5 4.5 0 0 0 7 18z',
  'leaf':
      'M5 19C5 9.5 11.5 4.5 20 4c0 8.5-5 15-15 15zM5 19c3-5.5 7.5-9.5 11.5-11.5',
  'wave':
      'M2 13c2.4-3 4.8-3 7.2 0s4.8 3 7.2 0 4.8-3 7.6 0M2 18c2.4-3 4.8-3 7.2 0s4.8 3 7.2 0 4.8-3 7.6 0',
  'cup':
      'M4 8h12v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5zM16 9h2a3 3 0 0 1 0 6h-2M7 3v2M11 3v2M15 3v2',
};

/// 自绘矢量图标组件（24×24 视口，描边风格，随主题色变色）。
class SugarIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final bool filled;

  const SugarIcon(
    this.name, {
    super.key,
    this.size = 18,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(
        name: name,
        color: color ?? theme.colorScheme.onSurface,
        filled: filled,
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final String name;
  final Color color;
  final bool filled;

  _IconPainter({required this.name, required this.color, required this.filled});

  static final Map<String, Path> _pathCache = {};

  Path _path(String d) =>
      _pathCache.putIfAbsent(d, () => svgPathToFlutterPath(d));

  @override
  void paint(Canvas canvas, Size size) {
    final data = filled
        ? (kFillAvatars[name] ?? kFillAvatars['person']!)
        : (kStrokeIcons[name] ?? '');
    if (data.isEmpty) return;
    final path = _path(data);
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);
    if (filled) {
      canvas.drawPath(path, Paint()..color = color);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.name != name || old.color != color || old.filled != filled;
}
