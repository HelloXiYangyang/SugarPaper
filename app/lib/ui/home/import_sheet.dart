/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/parser.dart';
import '../widgets/basic.dart';
import '../widgets/voice_input.dart';
import 'dialogs.dart';

Future<void> showImportSheet(BuildContext context) {
  return showSugarDialog(
    context,
    builder: (ctx) => const SugarDialogBox(child: _ImportSheet()),
  );
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final TextEditingController _text = TextEditingController();
  List<ParsedTask>? _preview;
  List<String>? _warnings;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _parse() {
    final state = ref.read(appStateProvider);
    final detail = Parser.parseDetailed(_text.text, state.store.subjects);
    setState(() {
      _preview = detail.tasks;
      _warnings = detail.warnings;
    });
    if (detail.tasks.isEmpty) {
      showSugarToast(context, '没有解析到作业条目');
    }
  }

  /// v0.23.0 从 .txt/.md 文件导入（对齐网页版「从文件导入」）。
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'text'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.single;
    try {
      var content = '';
      if (f.bytes != null) {
        content = utf8.decode(f.bytes!, allowMalformed: true);
      } else if (f.path != null) {
        content = await File(f.path!).readAsString();
      } else {
        showSugarToast(context, '读取文件失败');
        return;
      }
      setState(() {
        _text.text = content;
        _preview = null;
        _warnings = null;
      });
      _parse();
      if (!mounted) return;
      showSugarToast(context, '已读取 ${f.name}');
    } catch (_) {
      showSugarToast(context, '文件读取失败，请重试');
    }
  }

  void _import(String mode) {
    final preview = _preview;
    if (preview == null || preview.isEmpty) return;
    final state = ref.read(appStateProvider);
    state.store.importTasks(
      preview
          .map((p) => {
                'subject': p.subject,
                'title': p.title,
                'subtitle': p.subtitle,
                'priority': p.priority,
                'dueDate': p.dueDate,
                'isCompleted': p.isCompleted,
              })
          .toList(),
      mode,
    );
    state.notify();
    Navigator.pop(context);
    showSugarToast(
      context,
      mode == 'overwrite' ? '已覆盖导入 ${preview.length} 项' : '已追加 ${preview.length} 项',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SugarIcon('file-text', size: 17, color: t.pinkStrong),
              const SizedBox(width: 6),
              Text(
                '粘贴作业清单',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _text,
              maxLines: 9,
              minLines: 6,
              style: TextStyle(fontSize: 13, height: 1.5, color: t.text),
              decoration: InputDecoration(
                hintText: '把老师发的消息粘贴到这里…\n\n'
                    '支持：\n数学\n1.试卷一张\n2.默写判定方法\n'
                    '写在一张纸上 周一收',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: VoiceInputButton(
                    onResult: (text) {
                      final cur = _text.text;
                      _text.text = cur.isEmpty ? text : '$cur\n$text';
                      _text.selection = TextSelection.collapsed(
                        offset: _text.text.length,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SugarButton(
                  label: '预览解析结果',
                  iconName: 'eye',
                  onTap: _parse,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SugarButton(
                  label: '载入示例',
                  iconName: 'sparkles',
                  onTap: () {
                    _text.text = _sampleText;
                    _parse();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SugarButton(
            label: '从文件导入（.txt / .md）',
            iconName: 'upload',
            onTap: _pickFile,
          ),
          if (_preview != null) ...[
            const SizedBox(height: 14),
            if (_warnings != null && _warnings!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _warnings!
                      .map((w) => Text(
                            w,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.dangerStrong,
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              '预览结果（${_preview!.length} 项）',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: _preview!.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
                itemBuilder: (context, i) {
                  final p = _preview![i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: SugarThemeData.hex(
                              ref.read(appStateProvider).store.subjectColor(p.subject),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.subject} · ${p.title}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.text,
                                ),
                              ),
                              if (p.subtitle.isNotEmpty)
                                Text(
                                  p.subtitle.replaceAll('\n', ' / '),
                                  style: TextStyle(fontSize: 11, color: t.text3),
                                ),
                            ],
                          ),
                        ),
                        if (p.dueDate != null)
                          Text(
                            p.dueDate!.substring(5).replaceFirst('-', '/'),
                            style: TextStyle(fontSize: 10, color: t.text3),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SugarButton(
                    label: '导入并覆盖',
                    iconName: 'download',
                    primary: true,
                    onTap: () => _import('overwrite'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SugarButton(
                    label: '追加到末尾',
                    iconName: 'plus',
                    onTap: () => _import('append'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

const _sampleText = '''
数学
1.试卷一张
2.默写平行四边形判定方法
写在一张纸上 周一收
语文
1.周六14:00考期末检测卷
对答案 周一检查
2.背《昆虫记》讲义
自己印的
英语
1.默写49个过去分词
优秀组默1遍
''';
