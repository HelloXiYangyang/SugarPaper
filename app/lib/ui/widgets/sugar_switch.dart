/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// 弹簧回弹开关（PRD v4.5）：拇指平移 + 按压拉伸 + 轨道渐变/光晕，
/// 300ms，曲线 cubic-bezier(.34,1.56,.64,1)。
class SugarSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SugarSwitch({super.key, required this.value, required this.onChanged});

  @override
  State<SugarSwitch> createState() => _SugarSwitchState();
}

class _SugarSwitchState extends State<SugarSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _thumbX;
  late final Animation<double> _thumbScale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimDurations.switchSpring,
      reverseDuration: AnimDurations.switchSpring,
    );
    _thumbX = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _thumbScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 70),
    ]).animate(_controller);
    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.value) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant SugarSwitch old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    const width = 50.0;
    const height = 30.0;
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                colors: [
                  t.iconMain.withValues(alpha: 0.45),
                  t.mintStrong.withValues(alpha: 0.45),
                ],
              ),
              boxShadow: [
                if (_glow.value > 0.01)
                  BoxShadow(
                    color: t.iconMain.withValues(alpha: 0.35 * _glow.value),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedContainer(
                  duration: AnimDurations.switchSpring,
                  curve: Curves.easeOut,
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    color: widget.value
                        ? t.iconMain.withValues(alpha: 0.9)
                        : t.surface3.withValues(alpha: 0.55),
                  ),
                ),
                AnimatedPadding(
                  duration: AnimDurations.switchSpring,
                  curve: Curves.easeOutBack,
                  padding: EdgeInsets.only(
                    left: _thumbX.value * (width - height) + 3,
                    right: 3,
                  ),
                  child: Transform.scale(
                    scale: _thumbScale.value,
                    child: Container(
                      width: height - 6,
                      height: height - 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
