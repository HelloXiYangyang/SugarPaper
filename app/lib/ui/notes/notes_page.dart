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
import '../../core/markdown.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/parser.dart';
import '../../models/note.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';
import '../widgets/voice_input.dart';

const kNoteColors = [
  '#FBE4EC', // 粉
  '#DEF3EA', // 薄荷
  '#E2EEF9', // 蓝
  '#ECEBFA', // 紫
  '#FDEBE0', // 桃
  '#FDF4DC', // 黄
  '#FBE6E6', // 红
  '#E4F3EA', // 绿
];

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final notes = state.activeNotes;
    final archived = state.archivedNotes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        Row(
          children: [
            SugarIcon('list', size: 17, color: t.iconMain),
            const SizedBox(width: 6),
            Text(
              '便签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const Spacer(),
            SugarButton(
              label: '新建便签',
              iconName: 'plus',
              primary: true,
              compact: true,
              onTap: () => _editNote(context, ref, null),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty && archived.isEmpty)
          EmptyState(
            iconName: 'book',
            title: '还没有便签',
            subtitle: '速记灵感、考试安排、错题要点…\n一条便签可一键转为作业。',
            actions: [
              SugarButton(
                label: '新建便签',
                iconName: 'plus',
                primary: true,
                onTap: () => _editNote(context, ref, null),
              ),
            ],
          )
        else ...[
          ...notes.map((note) => _NoteCard(
                note: note,
                onTap: () => _editNote(context, ref, note),
                onTogglePin: () {
                  state.store.updateNote(note.id, {'pinned': !note.pinned});
                  state.notify();
                },
                onArchive: () {
                  state.store.updateNote(note.id, {'archived': true});
                  state.notify();
                },
                onDelete: () => _deleteNote(context, state, note),
                onConvert: () => _convertToTask(context, ref, note),
              )),
          if (archived.isNotEmpty) ...[
            GroupHeader(
              iconName: 'clock',
              label: '已归档',
              count: archived.length,
              accent: t.text3,
            ),
            ...archived.map((note) => _NoteCard(
                  note: note,
                  onTap: () => _editNote(context, ref, note),
                  onTogglePin: null,
                  onArchive: () {
                    state.store.updateNote(note.id, {'archived': false});
                    state.notify();
                  },
                  onDelete: () => _deleteNote(context, state, note),
                  onConvert: null,
                )),
          ],
        ],
      ],
    );
  }

  void _editNote(BuildContext context, WidgetRef ref, Note? note) {
    showSugarDialog(
      context,
      builder: (ctx) => _NoteEditor(note: note),
    );
  }

  void _deleteNote(BuildContext context, AppState state, Note note) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除便签'),
        content: Text('确定删除「${note.title.isEmpty ? '无标题' : note.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              state.store.deleteNote(note.id);
              state.notify();
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _convertToTask(BuildContext context, WidgetRef ref, Note note) {
    final state = ref.read(appStateProvider);
    final text = '${note.title.isNotEmpty ? note.title + '\n' : ''}${note.content}';
    final parsed = Parser.parse(text, state.store.subjects);
    if (parsed.isEmpty) {
      showSugarToast(context, '没有解析到可转为作业的内容');
      return;
    }
    showSugarDialog(
      context,
      builder: (ctx) => SugarDialogBox(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SugarIcon('file-text', size: 17, color: Theme.of(context)
                      .extension<SugarTheme>()!.data.pinkStrong),
                  const SizedBox(width: 6),
                  Text(
                    '便签转作业（${parsed.length} 项）',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).extension<SugarTheme>()!.data.text,
                    ),
                  ),
                  const Spacer(),
                  PressableScale(
                    onTap: () => Navigator.pop(ctx),
                    child: SugarIcon(
                      'close',
                      size: 18,
                      color: Theme.of(context).extension<SugarTheme>()!.data.text3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...parsed.take(8).map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '· [${p.subject}] ${p.title}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).extension<SugarTheme>()!.data.text,
                      ),
                    ),
                  )),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SugarButton(
                      label: '追加导入',
                      iconName: 'plus',
                      primary: true,
                      onTap: () {
                        state.store.importTasks(
                          parsed
                              .map((p) => {
                                    'subject': p.subject,
                                    'title': p.title,
                                    'subtitle': p.subtitle,
                                    'priority': p.priority,
                                    'dueDate': p.dueDate,
                                    'isCompleted': p.isCompleted,
                                  })
                              .toList(),
                          'append',
                        );
                        state.notify();
                        Navigator.pop(ctx);
                        Navigator.pop(ctx);
                        showSugarToast(context, '已转为作业 ${parsed.length} 项');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SugarButton(
                      label: '取消',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onConvert;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onTogglePin,
    required this.onArchive,
    required this.onDelete,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final color = SugarThemeData.hex(note.colorHex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A5C68).withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? '无标题' : note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                  ),
                  if (note.pinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SugarIcon('pin', size: 14, color: t.iconMain),
                    ),
                  _miniIcon(context, 'edit', () => onTap()),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: t.text2,
                  ),
                ),
              ],
              if (note.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: note.images.take(4).map((uri) {
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
              Row(
                children: [
                  if (onTogglePin != null)
                    _textBtn(
                      context,
                      note.pinned ? '取消置顶' : '置顶',
                      icon: 'pin',
                      onTap: onTogglePin!,
                    ),
                  const SizedBox(width: 8),
                  _textBtn(
                    context,
                    note.archived ? '恢复' : '归档',
                    icon: 'download',
                    onTap: onArchive,
                  ),
                  if (onConvert != null) ...[
                    const SizedBox(width: 8),
                    _textBtn(
                      context,
                      '转作业',
                      icon: 'file-text',
                      onTap: onConvert!,
                    ),
                  ],
                  const Spacer(),
                  _miniIcon(context, 'trash', onDelete, danger: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textBtn(BuildContext context, String label,
      {required String icon, required VoidCallback onTap}) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SugarIcon(icon, size: 11, color: t.text2),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, color: t.text2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(
    BuildContext context,
    String icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: danger ? t.dangerSoft : t.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SugarIcon(
          icon,
          size: 13,
          color: danger ? t.dangerStrong : t.text2,
        ),
      ),
    );
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

class _NoteEditor extends ConsumerStatefulWidget {
  final Note? note;

  const _NoteEditor({this.note});

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late String _color;
  DateTime? _remindAt;
  List<String> _images = [];
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
    _color = widget.note?.colorHex ?? kNoteColors[0];
    _remindAt = widget.note?.remindAt;
    _images = [...?widget.note?.images];
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _save() {
    final state = ref.read(appStateProvider);
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (widget.note == null) {
      state.store.addNote({
        'title': title,
        'content': content,
        'colorHex': _color,
        'remindAt': _remindAt?.toIso8601String(),
        'images': _images,
      });
    } else {
      state.store.updateNote(widget.note!.id, {
        'title': title,
        'content': content,
        'colorHex': _color,
        'remindAt': _remindAt?.toIso8601String(),
        'images': _images,
      });
    }
    state.notify();
    Navigator.pop(context);
  }

  Future<void> _pickRemindAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _remindAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: '选择提醒日期',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
      final maxSide = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return SugarDialogBox(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SugarIcon(
                  widget.note == null ? 'plus' : 'edit',
                  size: 17,
                  color: t.iconMain,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.note == null ? '新建便签' : '编辑便签',
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
              decoration: InputDecoration(
                labelText: '标题（可选）',
                filled: true,
                fillColor: t.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _mdModeBtn(context, '编辑', !_preview, () {
                  setState(() => _preview = false);
                }),
                const SizedBox(width: 6),
                _mdModeBtn(context, '预览', _preview, () {
                  setState(() => _preview = true);
                }),
              ],
            ),
            const SizedBox(height: 8),
            if (_preview)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _content.text.trim().isEmpty
                    ? Text(
                        '暂无内容',
                        style: TextStyle(fontSize: 12.5, color: t.text3),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: MdRender.toWidgets(
                          _content.text,
                          text: t.text,
                          text2: t.text2,
                          accent: t.iconMain,
                        ),
                      ),
              )
            else
              TextField(
                controller: _content,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: '内容',
                  hintText: '速记内容…支持 Markdown 排版与「- [ ] 待办清单」，可一键转为作业',
                  filled: true,
                  fillColor: t.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: VoiceInputButton(
                      onResult: (text) {
                        final cur = _content.text;
                        _content.text = cur.isEmpty ? text : '$cur\n$text';
                        _content.selection = TextSelection.collapsed(
                          offset: _content.text.length,
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kNoteColors.map((c) {
                final active = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: SugarThemeData.hex(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? t.iconMain : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SugarIcon('bell', size: 15, color: t.iconMain),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _remindAt == null
                        ? '设置提醒（可选）'
                        : '${_remindAt!.month}月${_remindAt!.day}日 '
                            '${_remindAt!.hour.toString().padLeft(2, '0')}:'
                            '${_remindAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 13, color: t.text2),
                  ),
                ),
                SugarButton(
                  label: _remindAt == null ? '添加' : '修改',
                  compact: true,
                  onTap: _pickRemindAt,
                ),
                if (_remindAt != null) ...[
                  const SizedBox(width: 6),
                  SugarButton(
                    label: '清除',
                    compact: true,
                    danger: true,
                    onTap: () => setState(() => _remindAt = null),
                  ),
                ],
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                                  _images = _images
                                      .where((x) => x != uri)
                                      .toList();
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
                    if (_images.length < 4) ...[
                      PressableScale(
                        onTap: _pickImages,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: t.surface2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: t.border,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: SugarIcon(
                            'image',
                            size: 20,
                            color: t.iconMain,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SugarButton(
                label: '添加图片（最多 4 张）',
                iconName: 'image',
                compact: true,
                onTap: _pickImages,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SugarButton(
                  label: '取消',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                SugarButton(
                  label: widget.note == null ? '创建' : '保存',
                  iconName: 'save',
                  primary: true,
                  onTap: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mdModeBtn(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? t.iconMain : t.surface2,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : t.text2,
          ),
        ),
      ),
    );
  }
}
