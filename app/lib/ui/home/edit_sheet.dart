/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/task.dart';
import '../widgets/basic.dart';
import 'dialogs.dart';

Future<void> showEditSheet(
  BuildContext context, {
  Task? task,
  DateTime? initialDueDate,
}) {
  return showSugarDialog(
    context,
    builder: (ctx) => SugarDialogBox(
      child: _EditSheet(task: task, initialDueDate: initialDueDate),
    ),
  );
}

class _EditSheet extends ConsumerStatefulWidget {
  final Task? task;
  final DateTime? initialDueDate;

  const _EditSheet({this.task, this.initialDueDate});

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late String _subject;
  late int _priority;
  DateTime? _dueDate;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _subtitle = TextEditingController(text: t?.subtitle ?? '');
    _subject = t?.subject ??
        (ref.read(appStateProvider).enabledSubjects.isNotEmpty
            ? ref.read(appStateProvider).enabledSubjects.first.name
            : '默认');
    _priority = t?.priority ?? 1;
    _dueDate = t?.dueDate ?? widget.initialDueDate;
    _images = [...?t?.images];
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      helpText: '选择截止日期',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(
      limit: 4 - _images.length,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked.isEmpty || !mounted) return;
    final added = <String>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      final uri = await _compressImage(bytes);
      if (uri != null && _images.length + added.length < 4) {
        added.add(uri);
      }
    }
    if (added.isNotEmpty && mounted) {
      setState(() => _images = [..._images, ...added]);
    }
  }

  Future<String?> _compressImage(List<int> bytes) async {
    try {
      final decoded = img.decodeImage(Uint8List.fromList(bytes));
      if (decoded == null) return null;
      final maxSide =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      final scale = maxSide > 512 ? 512.0 / maxSide : 1.0;
      final resized = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
      final jpg = img.encodeJpg(resized, quality: 82);
      return 'data:image/jpeg;base64,${base64Encode(jpg)}';
    } catch (_) {
      return null;
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showSugarToast(context, '请填写作业内容');
      return;
    }
    final state = ref.read(appStateProvider);
    final patch = <String, dynamic>{
      'title': title,
      'subtitle': _subtitle.text.trim(),
      'subject': _subject,
      'priority': _priority,
      'images': _images,
      'dueDate': _dueDate == null
          ? null
          : '${_dueDate!.year}-'
              '${_dueDate!.month.toString().padLeft(2, '0')}-'
              '${_dueDate!.day.toString().padLeft(2, '0')}',
    };
    if (widget.task == null) {
      state.store.addTask(patch);
    } else {
      state.store.updateTask(widget.task!.id, patch);
    }
    state.notify();
    Navigator.pop(context);
    showSugarToast(context, widget.task == null ? '已添加作业' : '已保存');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SugarIcon(widget.task == null ? 'plus' : 'edit',
                  size: 17, color: t.pinkStrong),
              const SizedBox(width: 6),
              Text(
                widget.task == null ? '添加作业' : '编辑作业',
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
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            autofocus: widget.task == null,
            decoration: InputDecoration(
              labelText: '作业内容',
              hintText: '例如：试卷一张',
              filled: true,
              fillColor: t.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitle,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '附加说明（可选）',
              hintText: '例如：周一收',
              filled: true,
              fillColor: t.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Picker(
                icon: 'book',
                label: _subject,
                onTap: () => _pickSubject(state, t),
              ),
              _Picker(
                icon: 'calendar',
                label: _dueDate == null
                    ? '截止日期'
                    : '${_dueDate!.month}月${_dueDate!.day}日',
                onTap: _pickDueDate,
              ),
              _Picker(
                icon: 'flag',
                label: switch (_priority) {
                  2 => '高优先级',
                  0 => '低优先级',
                  _ => '中优先级',
                },
                onTap: () {
                  setState(() {
                    _priority = (_priority + 1) % 3;
                  });
                },
              ),
            ],
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  ..._images.map((uri) {
                    final comma = uri.indexOf(',');
                    final bytes = comma < 0
                        ? const <int>[]
                        : base64Decode(uri.substring(comma + 1));
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uint8List.fromList(bytes),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _images = _images.where((x) => x != uri).toList();
                              }),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_images.length < 4)
                    PressableScale(
                      onTap: _pickImages,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: t.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: SugarIcon(
                          'image',
                          size: 20,
                          color: t.pinkStrong,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SugarButton(
              label: '作业拍照存档（最多 4 张）',
              iconName: 'image',
              compact: true,
              onTap: _pickImages,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SugarButton(
                label: '取消',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              SugarButton(
                label: widget.task == null ? '添加' : '保存',
                iconName: 'save',
                primary: true,
                onTap: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pickSubject(AppState state, SugarThemeData t) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择科目'),
        children: state.enabledSubjects
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
}

class _Picker extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _Picker({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            SugarIcon(icon, size: 13, color: t.pinkStrong),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text),
            ),
          ],
        ),
      ),
    );
  }
}
