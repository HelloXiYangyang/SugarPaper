/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';

/// 按压缩放反馈（scale .92-.94，120ms，PRD §6.1）。
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.93,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        child: widget.child,
      ),
    );
  }
}

/// 马卡龙卡片（表面色、圆角 16）。
class SugarCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const SugarCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A5C68).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}

/// 小标签（优先级 / 截止日期 / 完成时间）。
class SugarTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final String? iconName;

  const SugarTag({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconName != null) ...[
            SugarIcon(iconName!, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(text, style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

/// 优先级标签。
class PriorityTag extends StatelessWidget {
  final int priority;

  const PriorityTag({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    switch (priority) {
      case 2:
        return SugarTag(
          text: '高',
          bg: t.dangerSoft,
          fg: t.dangerStrong,
          iconName: 'flag',
        );
      case 0:
        return SugarTag(
          text: '低',
          bg: t.mintSoft,
          fg: t.mintStrong,
          iconName: 'flag',
        );
      default:
        return SugarTag(
          text: '中',
          bg: t.skySoft,
          fg: t.skyStrong,
          iconName: 'flag',
        );
    }
  }
}

/// 截止日期标签（逾期红色）。
class DueTag extends StatelessWidget {
  final DateTime? due;
  final bool completed;

  const DueTag({super.key, required this.due, this.completed = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    if (due == null) return const SizedBox.shrink();
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);
    final dueD = DateTime(due!.year, due!.month, due!.day);
    final overdue = !completed && dueD.isBefore(todayD);
    final days = todayD.difference(dueD).inDays;
    final label = overdue
        ? '已逾期 $days 天'
        : '${due!.month}月${due!.day}日';
    return SugarTag(
      text: label,
      bg: overdue ? t.dangerSoft : t.peachSoft,
      fg: overdue ? t.dangerStrong : t.peachStrong,
      iconName: 'calendar',
    );
  }
}

/// 空状态。
class EmptyState extends StatelessWidget {
  final String iconName;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const EmptyState({
    super.key,
    this.iconName = 'sparkles',
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SugarIcon(iconName, size: 44, color: t.iconMain),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: t.text3),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 10, children: actions!),
          ],
        ],
      ),
    );
  }
}

/// 主按钮。
class SugarButton extends StatelessWidget {
  final String label;
  final String? iconName;
  final VoidCallback? onTap;
  final bool primary;
  final bool danger;
  final bool compact;

  const SugarButton({
    super.key,
    required this.label,
    this.iconName,
    this.onTap,
    this.primary = false,
    this.danger = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final bg = danger ? t.danger : t.surface2;
    // v0.30.0：主按钮使用主题图标渐变（iconMain → iconAccent），随主题切换
    final isPrimary = primary && !danger;
    final fg = (danger || primary) ? Colors.white : t.text;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 7 : 11,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? null : bg,
          gradient: isPrimary
              ? LinearGradient(colors: [t.iconMain, t.iconAccent])
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconName != null) ...[
              SugarIcon(iconName!, size: 14, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分组标题（图标 + 标签 + 计数 + 分隔线）。
class GroupHeader extends StatelessWidget {
  final String iconName;
  final String label;
  final int count;
  final Color accent;

  const GroupHeader({
    super.key,
    required this.iconName,
    required this.label,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          SugarIcon(iconName, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: t.border),
          ),
        ],
      ),
    );
  }
}

/// 科目 Chip（含计数）。
class SubjectChip extends StatelessWidget {
  final String name;
  final String colorHex;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.name,
    required this.colorHex,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final color = SugarThemeData.hex(colorHex);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? t.iconMain : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? t.iconMain : t.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name == '全部')
              SugarIcon(
                'sparkles',
                size: 13,
                color: active ? Colors.white : t.iconMain,
              )
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : t.text,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: active ? Colors.white70 : t.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
