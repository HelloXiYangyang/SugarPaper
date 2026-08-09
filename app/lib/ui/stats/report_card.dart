/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/stats_engine.dart';

/// 统计报告卡片（v0.21.0，对齐网页版 `report.js` 的 SVG 报告卡）：
/// 640×880，进度环 / 摘要 / 科目分布 / 欠账排行 / 每日趋势 / 专注统计。
class ReportCardPainter extends CustomPainter {
  final StatsReport s;
  final String rangeLabel;
  final String dateStr;
  final int focusMin;
  final String Function(String name) subjectColor;

  ReportCardPainter({
    required this.s,
    required this.rangeLabel,
    required this.dateStr,
    required this.focusMin,
    required this.subjectColor,
  });

  static const bg = Color(0xFFFBF6F2);
  static const text = Color(0xFF5A4A52);
  static const sub = Color(0xFF8A7A82);
  static const faint = Color(0xFFB9A9B0);
  static const pink = Color(0xFFF4A8C6);
  static const mint = Color(0xFF7ED3B2);
  static const lavender = Color(0xFFB9A8E8);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // 标题
    _text(canvas, '糖纸 · SugarPaper 统计报告', 22, const Offset(40, 44),
        color: text, bold: true);
    _text(canvas, '$rangeLabel · $dateStr', 13, const Offset(40, 78),
        color: sub);

    // 进度环
    final ringCenter = const Offset(150, 200);
    final ringR = 54.0;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
        ringCenter, ringR, Paint()..color = const Color(0xFFEFE3E8)..style = PaintingStyle.stroke..strokeWidth = 12);
    final rate = (s.rate.clamp(0, 100)).toDouble();
    final sweep = rate / 100 * 2 * 3.1415926;
    canvas.drawArc(
      Rect.fromCircle(center: ringCenter, radius: ringR),
      -3.1415926 / 2,
      sweep,
      false,
      ringPaint..color = pink,
    );
    _text(canvas, '$rate%', 30, Offset(150 - 34, 188),
        color: text, bold: true, align: TextAlign.center, width: 68);
    _text(canvas, '完成率', 12, Offset(150 - 34, 222),
        color: sub, align: TextAlign.center, width: 68);

    // 摘要行
    final cells = <(String, String)>[
      ('总任务', '${s.total}'),
      ('已完成', '${s.completed}'),
      ('准时率', '${s.onTimeRate}%'),
      ('专注', '$focusMin 分'),
    ];
    for (var i = 0; i < cells.length; i++) {
      final x = 268.0 + i * 78;
      _text(canvas, cells[i].$2, 24, Offset(x, 150),
          color: pink, bold: true, align: TextAlign.center, width: 70);
      _text(canvas, cells[i].$1, 12, Offset(x, 178),
          color: sub, align: TextAlign.center, width: 70);
    }

    // 科目分布
    _sectionTitle(canvas, '科目分布', 268);
    final dist = s.subjectDist.take(6).toList();
    final maxCount = dist.fold<int>(1, (m, x) => x.count > m ? x.count : m);
    for (var i = 0; i < dist.length; i++) {
      final y = 300.0 + i * 26;
      final d = dist[i];
      _text(canvas, d.name, 13, Offset(40, y - 3), color: text);
      final barW = 250.0 * d.count / maxCount;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(120, y, barW, 8),
          const Radius.circular(4),
        ),
        Paint()..color = _hex(subjectColor(d.name)),
      );
      _text(canvas, '${d.count} 项', 12, Offset(392, y - 3),
          color: sub, align: TextAlign.end, width: 170);
    }

    // 每日完成趋势（最近 7 天）
    _sectionTitle(canvas, '每日完成趋势', 462);
    final trend = s.dailyTrend;
    final maxT = trend.fold<int>(1, (m, x) => x.count > m ? x.count : m);
    for (var i = 0; i < trend.length; i++) {
      final x = 52.0 + i * 72;
      final h = 80.0 * trend[i].count / maxT;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 590 - h, 36, h),
          const Radius.circular(6),
        ),
        Paint()..color = trend[i].isToday ? pink : lavender,
      );
      _text(canvas, trend[i].label, 10, Offset(x - 4, 598),
          color: sub, align: TextAlign.center, width: 44);
    }

    // 欠账排行
    _sectionTitle(canvas, '科目欠账排行', 636);
    final debts = s.subjectDebt.take(4).toList();
    if (debts.isEmpty) {
      _text(canvas, '暂无欠账，继续保持！', 13, const Offset(40, 672),
          color: mint);
    } else {
      for (var i = 0; i < debts.length; i++) {
        final y = 672.0 + i * 30;
        final d = debts[i];
        canvas.drawCircle(
          Offset(52, y - 5),
          7,
          Paint()..color = _hex(subjectColor(d.name)),
        );
        _text(canvas, d.name, 14, Offset(72, y - 9),
            color: text, bold: true);
        _text(canvas, '${d.count} 项 · 权重 ${d.weight}', 13,
            Offset(392, y - 9), color: sub, align: TextAlign.end, width: 180);
      }
    }

    // 页脚
    _text(canvas, '让作业管理像糖果一样甜美简单', 12, const Offset(40, 826),
        color: faint);
    _text(canvas, '离线优先 · 设备直连 · 零服务器依赖', 11,
        const Offset(320, 826), color: faint, align: TextAlign.end, width: 250);
  }

  void _sectionTitle(Canvas canvas, String label, double y) {
    canvas.drawRect(
      Rect.fromLTWH(40, y - 4, 4, 16),
      Paint()..color = pink,
    );
    _text(canvas, label, 15, Offset(52, y - 3), color: text, bold: true);
  }

  void _text(
    Canvas canvas,
    String s,
    double size,
    Offset pos, {
    Color color = text,
    bool bold = false,
    TextAlign align = TextAlign.left,
    double width = 560,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    tp.paint(canvas, pos);
  }

  static Color _hex(String hex) {
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return pink;
  }

  @override
  bool shouldRepaint(covariant ReportCardPainter old) => true;
}

/// 渲染报告卡片 PNG 字节（640×880，2x 像素比）。
Future<Uint8List> renderReportPng(
  StatsReport s, {
  required String rangeLabel,
  required int focusMin,
  required String Function(String) subjectColor,
}) async {
  final now = DateTime.now();
  final dateStr = '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = ReportCardPainter(
    s: s,
    rangeLabel: rangeLabel,
    dateStr: dateStr,
    focusMin: focusMin,
    subjectColor: subjectColor,
  );
  painter.paint(canvas, const Size(640, 880));
  final picture = recorder.endRecording();
  final image = await picture.toImage(640, 880);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List() ?? Uint8List(0);
}
