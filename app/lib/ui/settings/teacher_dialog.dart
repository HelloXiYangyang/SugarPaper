/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/teacher.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';

/// 教师模式：布置作业弹窗（v0.25.0，对齐网页版 ui-teacher.js）。
Future<void> showTeacherDialog(BuildContext context) {
  return showSugarDialog(
    context,
    builder: (ctx) => const SugarDialogBox(child: _TeacherDialog()),
  );
}

class _TeacherDialog extends ConsumerStatefulWidget {
  const _TeacherDialog();

  @override
  ConsumerState<_TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends ConsumerState<_TeacherDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _output = TextEditingController();
  late String _subject;
  DateTime? _dueDate;
  int _priority = 1;
  final List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final subjects = ref.read(appStateProvider).enabledSubjects;
    _subject = subjects.isNotEmpty ? subjects.first.name : '默认';
  }

  @override
  void dispose() {
    _title.dispose();
    _output.dispose();
    super.dispose();
  }

  void _add() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showSugarToast(context, '请填写作业内容');
      return;
    }
    setState(() {
      _items.add({
        'subject': _subject,
        'title': title,
        'dueDate': _dueDate == null
            ? null
            : '${_dueDate!.year}-'
                '${_dueDate!.month.toString().padLeft(2, '0')}-'
                '${_dueDate!.day.toString().padLeft(2, '0')}',
        'priority': _priority,
      });
      _title.clear();
      _dueDate = null;
      _priority = 1;
    });
  }

  void _generate() {
    if (_items.isEmpty) {
      showSugarToast(context, '请先添加作业条目');
      return;
    }
    _output.text = TeacherEngine.buildHomeworkText(_items);
    setState(() {});
    showSugarToast(context, '文本已生成，可复制到班级群');
  }

  Future<void> _copy() async {
    if (_output.text.isEmpty) {
      showSugarToast(context, '请先生成文本');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _output.text));
    if (!mounted) return;
    showSugarToast(context, '已复制，粘贴到班级群即可');
  }

  Future<void> _download() async {
    if (_output.text.isEmpty) {
      showSugarToast(context, '请先生成文本');
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final date = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final file = File('${dir.path}${Platform.pathSeparator}糖纸-作业布置-$date.txt');
      await file.writeAsString(_output.text, encoding: utf8);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/plain')],
        text: '糖纸 · 作业布置',
      );
    } catch (_) {
      if (!mounted) return;
      showSugarToast(context, '导出失败，请重试');
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: '选择截止日期',
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  void _pickSubject() {
    final subjects = ref.read(appStateProvider).enabledSubjects;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择科目'),
        children: subjects
            .map((s) => SimpleDialogOption(
                  onPressed: () {
                    setState(() => _subject = s.name);
                    Navigator.pop(ctx);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: SugarThemeData.hex(s.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(s.name),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SugarIcon('file-text', size: 17, color: t.iconMain),
              const SizedBox(width: 6),
              Text(
                '教师模式 · 布置作业',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const Spacer(),
              PressableScale(
                onTap: () => Navigator.pop(context),
                child: SugarIcon('close', size: 18, color: t.text3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '排好作业后复制或导出，发到班级群；学生粘贴进糖纸即可一键解析导入。',
            style: TextStyle(fontSize: 11.5, height: 1.5, color: t.text2),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipBtn(context, 'book', _subject, _pickSubject),
              _chipBtn(
                context,
                'calendar',
                _dueDate == null
                    ? '截止日期'
                    : '${_dueDate!.month}月${_dueDate!.day}日交',
                _pickDueDate,
              ),
              _chipBtn(
                context,
                'flag',
                switch (_priority) {
                  2 => '高优先级',
                  0 => '低优先级',
                  _ => '中优先级',
                },
                () {
                  setState(() => _priority = (_priority + 1) % 3);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    hintText: '作业内容（例如：试卷一张）',
                    filled: true,
                    fillColor: t.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              SugarButton(
                label: '添加',
                iconName: 'plus',
                primary: true,
                onTap: _add,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Text(
              '还没有条目，添加后点「生成文本」。',
              style: TextStyle(fontSize: 12, color: t.text3),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _items.asMap().entries.map((e) {
                final it = e.value;
                final i = e.key;
                final due = it['dueDate'] as String?;
                final pri = (it['priority'] as num?)?.toInt() ?? 1;
                return Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  decoration: BoxDecoration(
                    color: t.surface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${it['subject']} · ${it['title']}'
                        '${due != null ? ' · ${due.substring(5).replaceFirst('-', '/')}交' : ''}'
                        '${pri == 2 ? ' · 必做' : (pri == 0 ? ' · 选做' : '')}',
                        style: TextStyle(fontSize: 11.5, color: t.text),
                      ),
                      PressableScale(
                        onTap: () =>
                            setState(() => _items.removeAt(i)),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SugarIcon(
                            'close',
                            size: 11,
                            color: t.text3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SugarButton(
                  label: '生成文本',
                  iconName: 'bolt',
                  onTap: _generate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _output,
              readOnly: true,
              maxLines: 7,
              minLines: 4,
              style: TextStyle(fontSize: 12.5, height: 1.6, color: t.text),
              decoration: InputDecoration(
                hintText: '点击「生成文本」预览班级群格式…',
                hintStyle: TextStyle(fontSize: 12, color: t.text3),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SugarButton(
                  label: '复制文本',
                  iconName: 'paperclip',
                  onTap: _copy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SugarButton(
                  label: '导出 .txt',
                  iconName: 'download',
                  primary: true,
                  onTap: _download,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipBtn(
    BuildContext context,
    String icon,
    String label,
    VoidCallback onTap,
  ) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SugarIcon(icon, size: 13, color: t.iconMain),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
