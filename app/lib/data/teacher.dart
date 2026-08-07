/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// 教师模式：作业文本生成器（v0.25.0，对齐网页版 `teacher.js`）。
/// 把条目按「科目行 + 编号条目」标准格式排版，学生粘贴进糖纸即可一键解析导入。
class TeacherEngine {
  static String _fmtDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return '';
    return '${int.tryParse(parts[1]) ?? 0}月${int.tryParse(parts[2]) ?? 0}日';
  }

  /// 生成作业文本。
  /// [items] 每条含 subject / title / dueDate('YYYY-MM-DD' 可选) / priority(0-2)。
  static String buildHomeworkText(List<Map<String, dynamic>> items) {
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final it in items) {
      final subject = (it['subject'] as String?)?.trim().isNotEmpty == true
          ? it['subject'] as String
          : '默认';
      if (!groups.containsKey(subject)) {
        groups[subject] = [];
        order.add(subject);
      }
      groups[subject]!.add(it);
    }
    final lines = <String>[];
    for (final subject in order) {
      lines.add(subject);
      final list = groups[subject]!;
      for (var i = 0; i < list.length; i++) {
        final it = list[i];
        var title = (it['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;
        final tags = <String>[];
        final due = it['dueDate'] as String?;
        if (due != null && due.isNotEmpty) {
          tags.add('${_fmtDate(due)}交');
        }
        final pri = (it['priority'] as num?)?.toInt() ?? 1;
        if (pri == 2) tags.add('必做');
        if (pri == 0) tags.add('选做');
        if (tags.isNotEmpty) title = '$title（${tags.join('、')}）';
        lines.add('${i + 1}.$title');
      }
    }
    return lines.join('\n');
  }
}
