/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 便签 Markdown 渲染器（v0.20.0，对齐网页版 `markdown.js`）。
/// 零依赖，支持：标题 / 加粗 / 斜体 / 行内代码 / 链接 / 列表（含待办清单）
/// / 引用 / 代码块 / 分隔线。文本先转义再渲染，避免注入。
class MdRender {
  static const String _codeTag = '\u0001';
  static const String _strongTag = '\u0002';
  static const String _emTag = '\u0003';
  static const String _linkTag = '\u0004';
  static const String _delTag = '\u0005';

  /// 把 Markdown 源码渲染为 Flutter widget 列表。
  static List<Widget> toWidgets(
    String src, {
    required Color text,
    required Color text2,
    required Color accent,
    TextStyle? base,
  }) {
    final raw = src.replaceAll('\r\n', '\n').split('\n');
    final out = <Widget>[];
    var inCode = false;
    final codeBuf = <String>[];
    final para = <String>[];

    void flushPara() {
      if (para.isEmpty) return;
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          _inlineSpans(para.join('\n'), text: text, text2: text2, accent: accent),
          style: (base ?? const TextStyle()).copyWith(
            color: text,
            height: 1.5,
          ),
        ),
      ));
      para.clear();
    }

    void push(Widget w) {
      flushPara();
      out.add(w);
    }

    for (final line in raw) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        if (inCode) {
          push(Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: text2.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              codeBuf.join('\n'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: text,
              ),
            ),
          ));
          codeBuf.clear();
          inCode = false;
        } else {
          flushPara();
          inCode = true;
        }
        continue;
      }
      if (inCode) {
        codeBuf.add(line);
        continue;
      }
      if (trimmed.isEmpty) {
        flushPara();
        continue;
      }
      final h = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (h != null) {
        final level = h.group(1)!.length;
        push(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text.rich(
            _inlineSpans(h.group(2)!, text: text, text2: text2, accent: accent),
            style: TextStyle(
              fontSize: level == 1 ? 18 : (level == 2 ? 16 : 14.5),
              fontWeight: FontWeight.w700,
              color: text,
              height: 1.35,
            ),
          ),
        ));
        continue;
      }
      if (RegExp(r'^(---|\*\*\*)$').hasMatch(trimmed)) {
        push(const Divider(height: 18));
        continue;
      }
      final quote = RegExp(r'^>\s?(.*)$').firstMatch(trimmed);
      if (quote != null) {
        push(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Text.rich(
            _inlineSpans(quote.group(1)!,
                text: text2, text2: text2, accent: accent),
            style: TextStyle(fontSize: 12.5, height: 1.5, color: text2),
          ),
        ));
        continue;
      }
      final check = RegExp(r'^-\s*\[([ xX])\]\s+(.*)$').firstMatch(trimmed);
      if (check != null) {
        flushPara();
        out.add(_todoRow(
          checked: check.group(1) != ' ',
          content: check.group(2)!,
          text: text,
          text2: text2,
          accent: accent,
        ));
        continue;
      }
      final ul = RegExp(r'^[-*]\s+(.*)$').firstMatch(trimmed);
      if (ul != null) {
        flushPara();
        out.add(_bulletRow(ul.group(1)!,
            text: text, text2: text2, accent: accent));
        continue;
      }
      final ol = RegExp(r'^\d+[.、]\s+(.*)$').firstMatch(trimmed);
      if (ol != null) {
        flushPara();
        out.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(fontSize: 13, color: accent)),
              Expanded(
                child: Text.rich(
                  _inlineSpans(ol.group(1)!,
                      text: text, text2: text2, accent: accent),
                  style: TextStyle(fontSize: 13, height: 1.5, color: text),
                ),
              ),
            ],
          ),
        ));
        continue;
      }
      para.add(trimmed);
    }
    if (inCode) {
      out.add(Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: text2.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          codeBuf.join('\n'),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.5,
            color: text,
          ),
        ),
      ));
    }
    flushPara();
    return out;
  }

  static Widget _bulletRow(
    String content, {
    required Color text,
    required Color text2,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text.rich(
              _inlineSpans(content, text: text, text2: text2, accent: accent),
              style: TextStyle(fontSize: 13, height: 1.5, color: text),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _todoRow({
    required String content,
    required bool checked,
    required Color text,
    required Color text2,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(right: 7, top: 1),
            decoration: BoxDecoration(
              color: checked ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: checked ? accent : text2,
                width: 1.4,
              ),
            ),
            child: checked
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
          Expanded(
            child: Text.rich(
              _inlineSpans(content, text: text, text2: text2, accent: accent),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: checked ? text2 : text,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 行内格式：行内代码 → 加粗 → 斜体 → 链接 → 删除线。
  static InlineSpan _inlineSpans(
    String src, {
    required Color text,
    required Color text2,
    required Color accent,
  }) {
    var s = src
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
    s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => '$_codeTag${m.group(1)}$_codeTag');
    s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => '$_strongTag${m.group(1)}$_strongTag');
    s = s.replaceAllMapped(RegExp(r'(^|[^*])\*([^*\n]+)\*(?!\*)'), (m) => '${m.group(1)}$_emTag${m.group(2)}$_emTag');
    s = s.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\((https?://[^)\s]+)\)'),
        (m) => '$_linkTag${m.group(1)}$_linkTag|${m.group(2)}');
    s = s.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => '$_delTag${m.group(1)}$_delTag');

    final spans = <InlineSpan>[];
    final buf = StringBuffer();

    void flush() {
      if (buf.isEmpty) return;
      spans.add(TextSpan(text: buf.toString()));
      buf.clear();
    }

    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (ch == _codeTag) {
        final end = s.indexOf(_codeTag, i + 1);
        if (end < 0) {
          buf.write(ch);
          i++;
          continue;
        }
        flush();
        spans.add(TextSpan(
          text: s.substring(i + 1, end),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: accent,
            backgroundColor: text2.withValues(alpha: 0.1),
          ),
        ));
        i = end + 1;
        continue;
      }
      if (ch == _strongTag) {
        final end = s.indexOf(_strongTag, i + 1);
        if (end < 0) {
          buf.write(ch);
          i++;
          continue;
        }
        flush();
        spans.add(TextSpan(
          text: s.substring(i + 1, end),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
        i = end + 1;
        continue;
      }
      if (ch == _emTag) {
        final end = s.indexOf(_emTag, i + 1);
        if (end < 0) {
          buf.write(ch);
          i++;
          continue;
        }
        flush();
        spans.add(TextSpan(
          text: s.substring(i + 1, end),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
        i = end + 1;
        continue;
      }
      if (ch == _delTag) {
        final end = s.indexOf(_delTag, i + 1);
        if (end < 0) {
          buf.write(ch);
          i++;
          continue;
        }
        flush();
        spans.add(TextSpan(
          text: s.substring(i + 1, end),
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
          ),
        ));
        i = end + 1;
        continue;
      }
      if (ch == _linkTag) {
        final end = s.indexOf(_linkTag, i + 1);
        final sep = s.indexOf('|', end);
        if (end < 0 || sep < 0) {
          buf.write(ch);
          i++;
          continue;
        }
        flush();
        final label = s.substring(i + 1, end);
        final url = s.substring(sep + 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: url)),
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ));
        i = s.length;
        continue;
      }
      buf.write(ch);
      i++;
    }
    flush();
    return TextSpan(children: spans);
  }
}
