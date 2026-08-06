/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 顶栏进度条：渐变流光循环（3.2s，从左到右再返回，PRD §6.1）。
class ShimmerProgressBar extends ConsumerStatefulWidget {
  final double percent; // 0-100

  const ShimmerProgressBar({super.key, required this.percent});

  @override
  ConsumerState<ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends ConsumerState<ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimDurations.progressShimmer,
    );
    final enabled = ref.read(appStateProvider).store.settings.animations;
    if (enabled) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final pct = widget.percent.clamp(0.0, 100.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: t.surface3.withValues(alpha: 0.6),
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final w = MediaQuery.of(context).size.width;
            final start = _controller.value * 0.5;
            final barWidth = w * pct / 100;
            return FractionallySizedBox(
              widthFactor: pct / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      t.pinkStrong,
                      t.mintStrong,
                      t.pinkStrong,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    transform: _SlideGradientTransform(start, barWidth),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double offset;
  final double width;

  const _SlideGradientTransform(this.offset, this.width);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset * width * 2, 0, 0);
  }
}

/// 入场/滚动显现动画：scale .94→1 + 上移淡入（450ms，PRD §6.1）。
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const Reveal({super.key, required this.child, this.delayMs = 0});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimDurations.cardReveal,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = Theme.of(context).extension<SugarTheme>()!.animations;
    if (!enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
