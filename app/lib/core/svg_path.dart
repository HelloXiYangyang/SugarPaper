/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:math' as math;
import 'dart:ui';

/// 轻量 SVG path 解析器：支持 M/L/H/V/C/Q/A/Z 及对应小写相对命令，
/// 用于把 Web 版 `icons.js` 的 path 数据原样绘制到 Flutter Canvas。
Path svgPathToFlutterPath(String d) {
  final path = Path();
  final numbers = RegExp(r'([MLHVCSQAZmlhvcsqaz])([^MLHVCSQAZmlhvcsqaz]*)');
  var cursor = Offset.zero;
  var start = Offset.zero;
  var lastControl = Offset.zero;
  var lastCmd = '';

  for (final m in numbers.allMatches(d)) {
    final cmd = m.group(1)!;
    final args = _parseArgs(m.group(2)!);
    var i = 0;
    var c = cmd;
    while (true) {
      switch (c) {
        case 'M':
          cursor = Offset(args[i], args[i + 1]);
          start = cursor;
          path.moveTo(cursor.dx, cursor.dy);
          i += 2;
          c = 'L';
          break;
        case 'm':
          cursor += Offset(args[i], args[i + 1]);
          start = cursor;
          path.moveTo(cursor.dx, cursor.dy);
          i += 2;
          c = 'l';
          break;
        case 'L':
          cursor = Offset(args[i], args[i + 1]);
          path.lineTo(cursor.dx, cursor.dy);
          i += 2;
          break;
        case 'l':
          cursor += Offset(args[i], args[i + 1]);
          path.lineTo(cursor.dx, cursor.dy);
          i += 2;
          break;
        case 'H':
          cursor = Offset(args[i], cursor.dy);
          path.lineTo(cursor.dx, cursor.dy);
          i += 1;
          break;
        case 'h':
          cursor += Offset(args[i], 0);
          path.lineTo(cursor.dx, cursor.dy);
          i += 1;
          break;
        case 'V':
          cursor = Offset(cursor.dx, args[i]);
          path.lineTo(cursor.dx, cursor.dy);
          i += 1;
          break;
        case 'v':
          cursor += Offset(0, args[i]);
          path.lineTo(cursor.dx, cursor.dy);
          i += 1;
          break;
        case 'C':
          {
            final c1 = Offset(args[i], args[i + 1]);
            final c2 = Offset(args[i + 2], args[i + 3]);
            final end = Offset(args[i + 4], args[i + 5]);
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
            lastControl = c2;
            cursor = end;
            i += 6;
            break;
          }
        case 'c':
          {
            final c1 = cursor + Offset(args[i], args[i + 1]);
            final c2 = cursor + Offset(args[i + 2], args[i + 3]);
            final end = cursor + Offset(args[i + 4], args[i + 5]);
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
            lastControl = c2;
            cursor = end;
            i += 6;
            break;
          }
        case 'Q':
          {
            final c1 = Offset(args[i], args[i + 1]);
            final end = Offset(args[i + 2], args[i + 3]);
            path.quadraticBezierTo(c1.dx, c1.dy, end.dx, end.dy);
            lastControl = c1;
            cursor = end;
            i += 4;
            break;
          }
        case 'q':
          {
            final c1 = cursor + Offset(args[i], args[i + 1]);
            final end = cursor + Offset(args[i + 2], args[i + 3]);
            path.quadraticBezierTo(c1.dx, c1.dy, end.dx, end.dy);
            lastControl = c1;
            cursor = end;
            i += 4;
            break;
          }
        case 'S':
          {
            final c1 = lastCmd == 'C' || lastCmd == 'S'
                ? cursor * 2 - lastControl
                : cursor;
            final c2 = Offset(args[i], args[i + 1]);
            final end = Offset(args[i + 2], args[i + 3]);
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
            lastControl = c2;
            cursor = end;
            i += 4;
            break;
          }
        case 's':
          {
            final c1 = lastCmd == 'c' || lastCmd == 's'
                ? cursor * 2 - lastControl
                : cursor;
            final c2 = cursor + Offset(args[i], args[i + 1]);
            final end = cursor + Offset(args[i + 2], args[i + 3]);
            path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
            lastControl = c2;
            cursor = end;
            i += 4;
            break;
          }
        case 'A':
          {
            final rx = args[i];
            final ry = args[i + 1];
            final rot = args[i + 2];
            final large = args[i + 3] != 0;
            final sweep = args[i + 4] != 0;
            final end = Offset(args[i + 5], args[i + 6]);
            _arcTo(path, cursor, Offset(rx, ry), rot, large, sweep, end);
            cursor = end;
            i += 7;
            break;
          }
        case 'a':
          {
            final rx = args[i];
            final ry = args[i + 1];
            final rot = args[i + 2];
            final large = args[i + 3] != 0;
            final sweep = args[i + 4] != 0;
            final end = cursor + Offset(args[i + 5], args[i + 6]);
            _arcTo(path, cursor, Offset(rx, ry), rot, large, sweep, end);
            cursor = end;
            i += 7;
            break;
          }
        case 'Z':
        case 'z':
          path.close();
          cursor = start;
          break;
      }
      lastCmd = c;
      if (i >= args.length) break;
    }
  }
  return path;
}

List<double> _parseArgs(String s) {
  return RegExp(r'-?\d*\.?\d+(?:[eE][+-]?\d+)?')
      .allMatches(s)
      .map((m) => double.parse(m.group(0)!))
      .toList();
}

void _arcTo(
  Path path,
  Offset from,
  Offset radii,
  double rotation,
  bool largeArc,
  bool sweep,
  Offset end,
) {
  // 将椭圆弧近似为三次贝塞尔曲线。
  if (from == end) return;
  var rx = radii.dx.abs();
  var ry = radii.dy.abs();
  final phi = rotation * math.pi / 180;
  final cosP = math.cos(phi);
  final sinP = math.sin(phi);
  final dx = (from.dx - end.dx) / 2;
  final dy = (from.dy - end.dy) / 2;
  final x1p = cosP * dx + sinP * dy;
  final y1p = -sinP * dx + cosP * dy;

  var rx2 = rx * rx;
  var ry2 = ry * ry;
  final x1p2 = x1p * x1p;
  final y1p2 = y1p * y1p;
  var lambda = x1p2 / rx2 + y1p2 / ry2;
  if (lambda > 1) {
    final scale = math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
    rx2 = rx * rx;
    ry2 = ry * ry;
    lambda = x1p2 / rx2 + y1p2 / ry2;
  }

  final num = math.max(0, rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2);
  final den = rx2 * y1p2 + ry2 * x1p2;
  var factor = math.sqrt(num / den);
  if (largeArc == sweep) factor = -factor;
  final cxp = factor * (rx * y1p / ry);
  final cyp = -factor * (ry * x1p / rx);
  final cx = cosP * cxp - sinP * cyp + (from.dx + end.dx) / 2;
  final cy = sinP * cxp + cosP * cyp + (from.dy + end.dy) / 2;

  double angle(Offset u, Offset v) {
    final dot = u.dx * v.dx + u.dy * v.dy;
    final len = math.sqrt((u.dx * u.dx + u.dy * u.dy) * (v.dx * v.dx + v.dy * v.dy));
    var a = math.acos((dot / len).clamp(-1.0, 1.0));
    if (u.dx * v.dy - u.dy * v.dx < 0) a = -a;
    return a;
  }

  final theta1 = angle(Offset((x1p - cxp) / rx, (y1p - cyp) / ry), Offset(1, 0));
  final theta2 = angle(
        Offset((x1p - cxp) / rx, (y1p - cyp) / ry),
        Offset((-x1p - cxp) / rx, (-y1p - cyp) / ry),
      ) %
      (2 * math.pi);
  final deltaTheta = sweep ? theta2 : theta2 - 2 * math.pi;

  const segments = 6;
  for (var i = 0; i < segments; i++) {
    final t1 = theta1 + deltaTheta * i / segments;
    final t2 = theta1 + deltaTheta * (i + 1) / segments;
    final p1 = _arcPoint(cx, cy, rx, ry, phi, t1);
    final p2 = _arcPoint(cx, cy, rx, ry, phi, t2);
    final alpha = math.sin((t2 - t1) / 2) * (4 / 3);
    final c1 = Offset(
      p1.dx - alpha * (-rx * math.sin(t1) * math.cos(phi) - ry * math.cos(t1) * math.sin(phi)),
      p1.dy - alpha * (-rx * math.sin(t1) * math.sin(phi) + ry * math.cos(t1) * math.cos(phi)),
    );
    final c2 = Offset(
      p2.dx + alpha * (-rx * math.sin(t2) * math.cos(phi) - ry * math.cos(t2) * math.sin(phi)),
      p2.dy + alpha * (-rx * math.sin(t2) * math.sin(phi) + ry * math.cos(t2) * math.cos(phi)),
    );
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
}

Offset _arcPoint(
  double cx,
  double cy,
  double rx,
  double ry,
  double phi,
  double theta,
) {
  final cosP = math.cos(phi);
  final sinP = math.sin(phi);
  final x = rx * math.cos(theta);
  final y = ry * math.sin(theta);
  return Offset(cx + cosP * x - sinP * y, cy + sinP * x + cosP * y);
}
