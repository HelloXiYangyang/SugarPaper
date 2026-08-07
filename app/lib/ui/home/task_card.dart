/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../widgets/basic.dart';

/// 任务卡片：科目徽章 / 标题 / 副标题 / 优先级 / 截止日期 / 操作按钮。
/// 完成/撤销时向右滑出淡出（240ms）后再切换分组（PRD §6.2）。
class TaskCard extends StatefulWidget {
  final Task task;
  final String subjectColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onFocus;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onConfirm; // 打卡任务家长确认（v0.17.0）

  const TaskCard({
    super.key,
    required this.task,
    required this.subjectColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onFocus,
    this.onMoveUp,
    this.onMoveDown,
    this.onConfirm,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _leaving = false;

  void _toggle() {
    final enabled = Theme.of(context).extension<SugarTheme>()!.animations;
    if (!enabled) {
      widget.onToggle();
      return;
    }
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      widget.onToggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final task = widget.task;
    final color = SugarThemeData.hex(widget.subjectColor);
    final done = task.isCompleted;

    final card = SugarCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.subject,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: done ? t.text3 : t.text,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (done)
                SugarIcon('check', size: 16, color: t.success)
              else
                SugarIcon('pin', size: 15, color: t.text3),
            ],
          ),
          if (task.subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              task.subtitle,
              style: TextStyle(fontSize: 12, height: 1.4, color: t.text2),
            ),
          ],
          if (task.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: Row(
                children: task.images.take(4).map((uri) {
                  final comma = uri.indexOf(',');
                  final bytes = comma < 0
                      ? const <int>[]
                      : base64Decode(uri.substring(comma + 1));
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _showImage(context, bytes),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(bytes),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (task.taskType == 'checkin')
                SugarTag(
                  text: '打卡',
                  bg: t.yellowSoft,
                  fg: t.yellowStrong,
                  iconName: 'target',
                )
              else if (task.taskType == 'recite')
                SugarTag(
                  text: '背诵',
                  bg: t.lavenderSoft,
                  fg: t.lavenderStrong,
                  iconName: 'book',
                ),
              if (task.taskType == 'checkin' && task.confirmed)
                SugarTag(
                  text: '家长已确认',
                  bg: t.mintSoft,
                  fg: t.mintStrong,
                  iconName: 'check',
                ),
              PriorityTag(priority: task.priority),
              DueTag(due: task.dueDate, completed: done),
              if (done && task.completedAt != null)
                SugarTag(
                  text: _fmtDateTime(task.completedAt!),
                  bg: t.mintSoft,
                  fg: t.mintStrong,
                  iconName: 'check',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                icon: done ? 'undo' : 'check',
                label: done ? '撤销' : '完成',
                fg: done ? t.mintStrong : Colors.white,
                bg: done ? t.mintSoft : t.success,
                onTap: _toggle,
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: 'edit',
                label: '',
                fg: t.text2,
                bg: t.surface2,
                onTap: widget.onEdit,
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: 'trash',
                label: '',
                fg: t.dangerStrong,
                bg: t.dangerSoft,
                onTap: widget.onDelete,
              ),
              if (!done && widget.onFocus != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: 'bolt',
                  label: '专注',
                  fg: t.pinkStrong,
                  bg: t.pinkSoft,
                  onTap: () => widget.onFocus?.call(),
                ),
              ],
              if (!done &&
                  task.taskType == 'checkin' &&
                  widget.onConfirm != null) ...[
                const SizedBox(width: 6),
                _ActionButton(
                  icon: 'check',
                  label: task.confirmed ? '已确认' : '确认',
                  fg: task.confirmed ? t.mintStrong : t.yellowStrong,
                  bg: task.confirmed ? t.mintSoft : t.yellowSoft,
                  onTap: () => widget.onConfirm?.call(),
                ),
              ],
              const Spacer(),
              if (!done) ...[
                _ActionButton(
                  icon: 'chevron-up',
                  label: '',
                  fg: t.text3,
                  bg: t.surface2,
                  onTap: () => widget.onMoveUp?.call(),
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: 'chevron-down',
                  label: '',
                  fg: t.text3,
                  bg: t.surface2,
                  onTap: () => widget.onMoveDown?.call(),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return AnimatedSlide(
      offset: _leaving ? const Offset(1, 0) : Offset.zero,
      duration: const Duration(milliseconds: 240),
      curve: Curves.ease,
      child: AnimatedOpacity(
        opacity: _leaving ? 0 : 1,
        duration: const Duration(milliseconds: 240),
        child: card,
      ),
    );
  }

  static String _fmtDateTime(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)} '
        '${pad(d.hour)}:${pad(d.minute)}';
  }

  void _showImage(BuildContext context, List<int> bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label.isEmpty ? 8 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SugarIcon(icon, size: 13, color: fg),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
