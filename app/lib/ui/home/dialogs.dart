/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// 弹窗统一过渡：中心缩放弹出（回弹，220ms，PRD §6.1）。
Future<T?> showSugarDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context).extension<SugarTheme>()!;
  final duration = theme.animations
      ? AnimDurations.speed(AnimDurations.dialogPop, theme.frameRate)
      : Duration.zero;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '关闭',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: duration,
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      if (!theme.animations) return child;
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.34, 1.4, 0.64, 1),
        reverseCurve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

/// 弹窗内容容器（圆角 22，马卡龙表面色）。
class SugarDialogBox extends StatelessWidget {
  final Widget child;

  const SugarDialogBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: child,
      ),
    );
  }
}

/// 提示 Toast（SnackBar，3 秒自动消失）。
void showSugarToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
