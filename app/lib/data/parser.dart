/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import '../models/subject_config.dart';

/// 解析结果（与 Web 版 `parser.js` 的 parse 返回值一致）。
class ParsedTask {
  final String subject;
  final String title;
  final String subtitle;
  final int priority;
  final String? dueDate; // 'YYYY-MM-DD'
  final String taskType; // checkin / recite / written
  final bool isCompleted; // v0.20.0 待办清单勾选状态（- [x] 直接算完成）

  const ParsedTask({
    required this.subject,
    required this.title,
    this.subtitle = '',
    this.priority = 1,
    this.dueDate,
    this.taskType = 'written',
    this.isCompleted = false,
  });
}

/// 详细解析结果（v0.17.0 对齐网页版 parseDetailed）。
class ParseDetail {
  final List<ParsedTask> tasks;
  final List<String> skipped;
  final List<String> warnings;

  const ParseDetail({
    required this.tasks,
    required this.skipped,
    required this.warnings,
  });
}

/// 文本解析引擎：粘贴老师消息 → 科目行 / 编号条目 / 子行 → 结构化任务。
/// 纯正则实现，逻辑与 Web 版 `web/js/parser.js` 完全一致。
class Parser {
  static const List<String> knownSubjects = [
    // 小学/初中/高中统一默认学科（PRD v4.1）
    '语文', '数学', '英语', '物理', '化学', '生物', '历史', '地理', '政治',
    '体育与健康', '音乐', '美术', '信息技术', '通用技术', '劳动', '综合实践活动',
    // 常见别名与兜底
    '道法', '道德与法治', '体育', '信息', '综合实践', '科学',
    '默认', '未分类', '综合',
  ];

  // 编号条目：1. 1、 (1) ① - • 等
  // 编号条目：1. 1、 (1) ① 一、 二、 - • 等（v0.17.0 支持中文数字）
  static final RegExp _itemRe = RegExp(
      r'^\s*(?:(\d{1,3})[.、．.)）]|([①-⑳])|([一二三四五六七八九十百]+)[、.．]|[-•·*])\s*(.+?)\s*$');
  // 作业动作词（用于启发式判断“这行不是科目行”）
  static final RegExp _taskWords = RegExp(
      r'题|卷|书|文|本|册|作业|抄|背|默|写|读|练|预习|复习|订正|检查|完成|背诵|听写|作文|古诗|讲义|试卷|练习|阅读|计算|画|做|准备|打印|下载|上传|提交|打卡');
  // 行尾标点（句号/分号/冒号等 → 更像普通句子）
  static final RegExp _sentenceEnd = RegExp(r'[。；：:，,！？!?]$');

  static final RegExp _priHighWords = RegExp(r'高|重要|紧急|必须|必做|优先|重点');
  static final RegExp _priLowWords = RegExp(r'低|选做|可做可不做|有空再做|加分');
  static final RegExp _checkinWords = RegExp(r'打卡|签到|每日打卡|接龙打卡');
  static final RegExp _reciteWords = RegExp(r'背诵|朗读|熟读|预习|听写|默写|诵读');
  static final RegExp _dueToday = RegExp(r'今天|今日');
  static final RegExp _dueTomorrow = RegExp(r'明天|明日');
  static final RegExp _dueDayAfter = RegExp(r'后天');
  static final RegExp _todoRe =
      RegExp(r'^\s*-\s*\[([ xX])\]\s*(.+?)\s*$');

  /// 从文本提取截止日期（'YYYY-MM-DD' 或 null）。
  static String? extractDueDate(String text) {
    final t = text;
    DateTime? base;
    if (_dueToday.hasMatch(t)) {
      base = DateTime.now();
    } else if (_dueTomorrow.hasMatch(t)) {
      base = DateTime.now().add(const Duration(days: 1));
    } else if (_dueDayAfter.hasMatch(t)) {
      base = DateTime.now().add(const Duration(days: 2));
    } else {
      final m = RegExp(r'(?:周|星期|礼拜)([一二三四五六日天])').firstMatch(t);
      if (m != null) {
        const map = {
          '一': 0, '二': 1, '三': 2, '四': 3, '五': 4, '六': 5, '日': 6, '天': 6,
        };
        return _nextWeekdayDate(map[m.group(1)]!);
      }
      final md = _parseDateText(t);
      if (md != null) {
        final now = DateTime.now();
        var y = now.year;
        var cand = DateTime(y, md.$1, md.$2);
        if (cand.isBefore(now.subtract(const Duration(days: 1)))) {
          y += 1;
          cand = DateTime(y, md.$1, md.$2);
        }
        return _dateStr(cand);
      }
    }
    if (base != null) {
      return _dateStr(DateTime(base.year, base.month, base.day));
    }
    return null;
  }

  /// 从文本提取优先级：2=高，0=低，1=中。
  static int extractPriority(String text) {
    final t = text;
    if (_priHighWords.hasMatch(t)) return 2;
    if (_priLowWords.hasMatch(t)) return 0;
    return 1;
  }

  static (int, int)? _parseDateText(String s) {
    final d = RegExp(r'(\d{1,2})月(\d{1,2})日').firstMatch(s);
    if (d != null) {
      return (int.parse(d.group(1)!), int.parse(d.group(2)!));
    }
    final d2 = RegExp(r'(\d{1,2})[./-](\d{1,2})(?!\d)').firstMatch(s);
    if (d2 != null && int.parse(d2.group(1)!) <= 12) {
      return (int.parse(d2.group(1)!), int.parse(d2.group(2)!));
    }
    return null;
  }

  static String _nextWeekdayDate(int dayIndex) {
    final today = DateTime.now();
    final cur = (today.weekday + 6) % 7; // 周一=0
    var diff = dayIndex - cur;
    if (diff <= 0) diff += 7;
    final t = DateTime(today.year, today.month, today.day + diff);
    return _dateStr(t);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool isSubjectLine(String line, List<String> subjectNames) {
    final t = line.trim();
    if (t.isEmpty) return false;
    final names = {...subjectNames, ...knownSubjects};
    if (names.contains(t)) return true;
    return _isHeuristicSubject(t);
  }

  static bool _isHeuristicSubject(String t) {
    // 启发式：短小、纯中文、无作业动作词、不以句号结尾 → 可能是科目行
    return t.length <= 6 &&
        RegExp(r'^[\u4e00-\u9fa5A-Za-z0-9]+$').hasMatch(t) &&
        !_taskWords.hasMatch(t) &&
        !_sentenceEnd.hasMatch(t);
  }

  /// 任务类型识别（v0.17.0）：打卡/签到 → checkin；背诵/朗读/预习/听写 → recite；其余 → written
  static String detectTaskType(String text) {
    final t = text;
    if (_checkinWords.hasMatch(t)) return 'checkin';
    if (_reciteWords.hasMatch(t)) return 'recite';
    return 'written';
  }

  /// 解析粘贴文本（两遍扫描，逻辑与 Web 版一致）。
  static List<ParsedTask> parse(String text, List<SubjectConfig> subjects) {
    return parseDetailed(text, subjects).tasks;
  }

  /// 详细解析：返回任务、未解析行与提示（对齐网页版 parseDetailed）。
  static ParseDetail parseDetailed(String text, List<SubjectConfig> subjects) {
    final subjectNames = subjects.map((s) => s.name).toList();
    final rawLines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final result = <ParsedTask>[];
    String? currentSubject;
    var sawAnySubject = false;
    ParsedTask? lastTask;
    final consumed = <int>{};
    final skipped = <String>[];

    final names = {...subjectNames, ...knownSubjects};
    final itemMatch = rawLines.map((l) => _itemRe.firstMatch(l)).toList();
    final isHeader = List<bool>.generate(rawLines.length, (i) {
      if (names.contains(rawLines[i])) return true;
      return false; // 启发式候选待第二遍结合下文判断
    });
    for (var i = 0; i < rawLines.length; i++) {
      if (isHeader[i] || !_isHeuristicSubject(rawLines[i])) continue;
      // 启发式候选：其后 3 行内出现编号条目 → 视为科目行
      for (var j = i + 1; j <= (i + 3).clamp(0, rawLines.length - 1); j++) {
        if (itemMatch[j] != null) {
          isHeader[i] = true;
          break;
        }
      }
    }

    for (var i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (isHeader[i]) {
        consumed.add(i);
        currentSubject = line;
        sawAnySubject = true;
        lastTask = null;
        continue;
      }

      // 待办清单（v0.20.0）：- [ ] / - [x] 优先于通用条目识别，勾选状态写入 isCompleted
      final todo = _todoRe.firstMatch(line);
      if (todo != null) {
        final title = todo.group(2)!.trim();
        if (title.isEmpty) continue;
        consumed.add(i);
        final task = ParsedTask(
          subject: currentSubject ?? (sawAnySubject ? currentSubject! : '默认'),
          title: title,
          priority: extractPriority(title),
          dueDate: extractDueDate(title),
          taskType: detectTaskType(title),
          isCompleted: todo.group(1) != ' ',
        );
        result.add(task);
        lastTask = task;
        continue;
      }

      final m = itemMatch[i];
      if (m != null) {
        final title = m.group(4)!.trim();
        if (title.isEmpty) continue;
        consumed.add(i);
        final task = ParsedTask(
          subject: currentSubject ?? (sawAnySubject ? currentSubject! : '默认'),
          title: title,
          priority: extractPriority(title),
          dueDate: extractDueDate(title),
          taskType: detectTaskType(title),
        );
        result.add(task);
        lastTask = task;
        continue;
      }

      // 非编号行 → 追加为上一个任务的子行（附加描述）
      if (lastTask != null) {
        consumed.add(i);
        final more = extractDueDate(line);
        if (more != null && lastTask.dueDate == null) {
          lastTask = ParsedTask(
            subject: lastTask.subject,
            title: lastTask.title,
            subtitle: lastTask.subtitle,
            priority: lastTask.priority,
            dueDate: more,
            taskType: lastTask.taskType,
            isCompleted: lastTask.isCompleted,
          );
          result[result.length - 1] = lastTask;
        }
        final pri = extractPriority(line);
        if (pri > lastTask.priority) {
          lastTask = ParsedTask(
            subject: lastTask.subject,
            title: lastTask.title,
            subtitle: lastTask.subtitle,
            priority: pri,
            dueDate: lastTask.dueDate,
            taskType: lastTask.taskType,
            isCompleted: lastTask.isCompleted,
          );
          result[result.length - 1] = lastTask;
        }
        final subtitle = lastTask.subtitle.isEmpty
            ? line
            : '${lastTask.subtitle}\n$line';
        lastTask = ParsedTask(
          subject: lastTask.subject,
          title: lastTask.title,
          subtitle: subtitle,
          priority: lastTask.priority,
          dueDate: lastTask.dueDate,
          taskType: lastTask.taskType,
          isCompleted: lastTask.isCompleted,
        );
        result[result.length - 1] = lastTask;
      } else if (!sawAnySubject && result.isEmpty) {
        consumed.add(i);
        // 无任何结构信息：整段视为一个任务（兜底）
        final task = ParsedTask(
          subject: '默认',
          title: line,
          priority: extractPriority(line),
          dueDate: extractDueDate(line),
          taskType: detectTaskType(line),
        );
        result.add(task);
        lastTask = task;
      }
    }

    for (var i = 0; i < rawLines.length; i++) {
      if (!consumed.contains(i)) skipped.add(rawLines[i]);
    }

    // 去掉标题为空的任务；为无科目任务补“默认”
    final tasks = result.where((t) => t.title.isNotEmpty).map((t) {
      final subject = t.subject.isEmpty ? '默认' : t.subject;
      return ParsedTask(
        subject: subject,
        title: t.title,
        subtitle: t.subtitle,
        priority: t.priority,
        dueDate: t.dueDate,
        taskType: t.taskType,
        isCompleted: t.isCompleted,
      );
    }).toList();

    final warnings = <String>[];
    if (tasks.isEmpty && rawLines.isNotEmpty) {
      warnings.add('没有解析到任何任务，请检查文本格式');
    }
    if (skipped.isNotEmpty) {
      warnings.add(
          '有 ${skipped.length} 行未能解析：${skipped.take(3).join(' / ')}');
    }
    return ParseDetail(tasks: tasks, skipped: skipped, warnings: warnings);
  }
}
