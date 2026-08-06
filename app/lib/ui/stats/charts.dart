/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/stats_engine.dart';

/// 进度环：缩放淡入（500ms，PRD §6.1）。
class RingChart extends StatefulWidget {
  final int percent;

  const RingChart({super.key, required this.percent});

  @override
  State<RingChart> createState() => _RingChartState();
}

class _RingChartState extends State<RingChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    _c.duration = theme.animations
        ? AnimDurations.speed(AnimDurations.ringFade, theme.frameRate)
        : Duration.zero;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final curve = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: curve,
          child: Transform.scale(
            scale: 0.8 + 0.2 * curve,
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _RingPainter(
                  percent: widget.percent,
                  progress: _c.value,
                  theme: t,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.percent}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                        ),
                      ),
                      Text(
                        '完成率',
                        style: TextStyle(fontSize: 10, color: t.text3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final int percent;
  final double progress;
  final SugarThemeData theme;

  _RingPainter({
    required this.percent,
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..color = theme.surface3;
    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * (percent / 100) * progress;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFE292B4), Color(0xFF5FB894)],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent || old.progress != progress;
}

/// 柱状图：自底生长（500ms，轻微回弹，PRD §6.1）。
class BarChart extends StatefulWidget {
  final List<BarPoint> data;

  const BarChart({super.key, required this.data});

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    _c.duration = theme.animations
        ? AnimDurations.speed(AnimDurations.barGrow, theme.frameRate)
        : Duration.zero;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final curve = Curves.easeOutBack.transform(_c.value);
        return SizedBox(
          height: 190,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarPainter(data: widget.data, progress: curve, theme: t),
          ),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<BarPoint> data;
  final double progress;
  final SugarThemeData theme;

  _BarPainter({
    required this.data,
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final max = math.max(1, data.map((d) => d.count).reduce(math.max));
    final left = 8.0;
    final right = 8.0;
    final top = 24.0;
    final bottom = 28.0;
    final chartW = size.width - left - right;
    final chartH = size.height - top - bottom;
    final step = chartW / data.length;
    final bw = step * 0.62;

    final baseline = Paint()
      ..color = theme.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(left, size.height - bottom),
      Offset(size.width - right, size.height - bottom),
      baseline,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final h = math.max(2, (d.count / max) * chartH) * progress;
      final x = left + i * step + (step - bw) / 2;
      final y = size.height - bottom - h;
      final paint = Paint()
        ..color = d.isToday ? theme.mintStrong : theme.pink;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, h),
          const Radius.circular(5),
        ),
        paint,
      );
      if (d.count > 0) {
        textPainter.text = TextSpan(
          text: '${d.count}',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.text2),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + bw / 2 - textPainter.width / 2, y - 16),
        );
      }
      textPainter.text = TextSpan(
        text: d.label,
        style: TextStyle(fontSize: 9, color: theme.text3),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + bw / 2 - textPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.data != data;
}

/// 饼图：转圈加载（1.4s）→ 扇区依次绽放（每扇区递增 90ms，550ms，PRD §6.1）。
class PieChart extends StatefulWidget {
  final List<SubjectDist> data;
  final List<String> colors;

  const PieChart({super.key, required this.data, required this.colors});

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    _c.duration = theme.animations
        ? const Duration(milliseconds: 1950)
        : Duration.zero;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _PiePainter(
              data: widget.data,
              colors: widget.colors,
              t: _c.value,
              theme: t,
            ),
          ),
        );
      },
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<SubjectDist> data;
  final List<String> colors;
  final double t;
  final SugarThemeData theme;

  _PiePainter({
    required this.data,
    required this.colors,
    required this.t,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold(0, (s, d) => s + d.count);
    if (total == 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 第一阶段（0-0.6）：转圈加载环
    if (t < 0.6) {
      final phase = t / 0.6;
      final loading = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = theme.pinkStrong.withValues(alpha: (1 - phase).clamp(0, 1));
      canvas.drawArc(
        rect,
        -math.pi / 2 + phase * math.pi * 4,
        math.pi * 1.4,
        false,
        loading,
      );
      return;
    }

    // 第二阶段：扇区依次绽放（每扇区递增 90ms）
    final blossomStart = 0.6;
    final blossomT = (t - blossomStart) / (1 - blossomStart);
    var angle = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final frac = d.count / total;
      final fullSweep = frac * 2 * math.pi;
      final delay = 90.0 / 550.0 * i;
      final local = ((blossomT - delay) / (1 - delay)).clamp(0.0, 1.0);
      final sweep = fullSweep * Curves.easeOutCubic.transform(local);
      if (sweep <= 0) continue;
      final color = i < colors.length
          ? SugarThemeData.hex(colors[i])
          : theme.lavender;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, angle, sweep, true, paint);
      angle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.t != t || old.data != data || old.colors != colors;
}

/// 折线图：描边绘制（1.1s，PRD §6.1）。
class LineChart extends StatefulWidget {
  final List<BarPoint> data;

  const LineChart({super.key, required this.data});

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration.zero,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    final theme = Theme.of(context).extension<SugarTheme>()!;
    _c.duration = theme.animations
        ? AnimDurations.speed(AnimDurations.lineDraw, theme.frameRate)
        : Duration.zero;
    _started = true;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          height: 170,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LinePainter(data: widget.data, t: _c.value, theme: t),
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<BarPoint> data;
  final double t;
  final SugarThemeData theme;

  _LinePainter({required this.data, required this.t, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final max = math.max(2, data.map((d) => d.count).reduce(math.max));
    final left = 10.0;
    final right = 10.0;
    final top = 12.0;
    final bottom = 26.0;
    final step = (size.width - left - right) / (data.length - 1);
    Offset pt(int i) {
      final x = left + i * step;
      final y = size.height - bottom - (data[i].count / max) * (size.height - top - bottom);
      return Offset(x, y);
    }

    final line = Path();
    for (var i = 0; i < data.length; i++) {
      final p = pt(i);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }

    // 面积填充
    final area = Path.from(line)
      ..lineTo(pt(data.length - 1).dx, size.height - bottom)
      ..lineTo(pt(0).dx, size.height - bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = theme.lavenderSoft,
    );

    // 描边绘制动画
    final metric = line.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * Curves.easeOut.transform(t));
    canvas.drawPath(
      visible,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = theme.lavenderStrong,
    );

    // 数据点与标签
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < data.length; i++) {
      final p = pt(i);
      canvas.drawCircle(p, 3.5, Paint()..color = theme.lavenderStrong);
      tp.text = TextSpan(
        text: data[i].label,
        style: TextStyle(fontSize: 9, color: theme.text3),
      );
      tp.layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, size.height - 19));
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.t != t || old.data != data;
}
