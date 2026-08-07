/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/core/markdown.dart';
import 'package:sugarpaper/data/parser.dart';
import 'package:sugarpaper/data/stats_engine.dart';
import 'package:sugarpaper/data/teacher.dart';
import 'package:sugarpaper/models/update_info.dart';
import 'package:sugarpaper/models/focus_session.dart';
import 'package:sugarpaper/models/note.dart';
import 'package:sugarpaper/models/subject_config.dart';

void main() {
  const subjects = [
    SubjectConfig(name: '语文', colorHex: '#F4B8CE'),
    SubjectConfig(name: '数学', colorHex: '#B3D4F0'),
  ];

  group('Parser 待办清单（v0.20.0）', () {
    test('勾选状态写入 isCompleted', () {
      final r = Parser.parse(
        '语文\n- [ ] 背《春》\n- [x] 默写古诗词',
        subjects,
      );
      expect(r.length, 2);
      expect(r[0].title, '背《春》');
      expect(r[0].isCompleted, isFalse);
      expect(r[1].title, '默写古诗词');
      expect(r[1].isCompleted, isTrue);
    });

    test('待办优先于通用条目识别（不被 - 条目正则吃掉）', () {
      final r = Parser.parse('- [ ] 数学练习册', const <SubjectConfig>[]);
      expect(r.length, 1);
      expect(r[0].title, '数学练习册');
      expect(r[0].isCompleted, isFalse);
    });
  });

  group('TeacherEngine.buildHomeworkText（v0.25.0）', () {
    test('按科目分组 + 编号条目 + 截止/优先级标签', () {
      final text = TeacherEngine.buildHomeworkText([
        {'subject': '数学', 'title': '试卷一张', 'dueDate': '2026-08-10'},
        {'subject': '语文', 'title': '背《春》', 'priority': 2},
        {'subject': '数学', 'title': '选做拓展题', 'priority': 0},
      ]);
      final lines = text.split('\n');
      expect(lines[0], '数学');
      expect(lines[1], '1.试卷一张（8月10日交）');
      expect(lines[2], '2.选做拓展题（选做）');
      expect(lines[3], '语文');
      expect(lines[4], '1.背《春》（必做）');
    });

    test('空标题跳过', () {
      final text = TeacherEngine.buildHomeworkText([
        {'subject': '数学', 'title': '   '},
      ]);
      expect(text, '数学');
    });
  });

  group('StatsEngine.dayMarkers（v0.24.0）', () {
    test('考试便签 + 专注分钟角标', () {
      final date = DateTime(2026, 8, 10);
      final examNote = Note(
        id: 'n1',
        title: '期末检测',
        content: '复习',
        remindAt: DateTime(2026, 8, 10, 8),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final otherNote = Note(
        id: 'n2',
        title: '随便写写',
        content: '不是考试',
        remindAt: DateTime(2026, 8, 10, 9),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final sessions = [
        FocusSession(
          id: 's1',
          taskId: null,
          taskTitle: '专注',
          startedAt: DateTime(2026, 8, 10, 10),
          durationSec: 25 * 60,
          pomodoros: 1,
          soundScene: 'pink',
        ),
        FocusSession(
          id: 's2',
          taskId: null,
          taskTitle: '专注',
          startedAt: DateTime(2026, 8, 10, 11),
          durationSec: 50 * 60,
          pomodoros: 2,
          soundScene: 'rain',
        ),
      ];
      final m = StatsEngine.dayMarkers([examNote, otherNote], sessions, date);
      expect(m.exam, isTrue);
      expect(m.focusMin, 75);

      final other = StatsEngine.dayMarkers(
        [otherNote],
        sessions,
        DateTime(2026, 8, 11),
      );
      expect(other.exam, isFalse);
      expect(other.focusMin, 0);
    });
  });

  group('MdRender.toWidgets（v0.20.0）', () {
    test('渲染标题/待办/加粗不抛异常', () {
      final widgets = MdRender.toWidgets(
        '# 考试安排\n- [ ] 复习\n- [x] 交回执\n**重要**',
        text: Colors.black,
        text2: Colors.grey,
        accent: Colors.pink,
      );
      expect(widgets, isNotEmpty);
    });
  });

  group('跨端数据互通（v0.26.0）', () {
    test('FocusSession canonical 输出与本地字段兼容', () {
      final s = FocusSession(
        id: 'f1',
        taskId: 't1',
        taskTitle: '数学作业',
        subject: '数学',
        startedAt: DateTime.utc(2026, 8, 7, 8, 0),
        durationSec: 1500,
        pomodoros: 1,
        soundScene: 'rain',
      );
      final j = s.toJson();
      expect(j['startAt'], '2026-08-07T08:00:00.000Z');
      expect(j['endAt'], '2026-08-07T08:25:00.000Z');
      expect(j['minutes'], 25);
      expect(j['completed'], true);
      expect(j['sceneId'], 'rain');
      expect(j['startedAt'], '2026-08-07T08:00:00.000Z');
      expect(j['durationSec'], 1500);
    });

    test('FocusSession.fromJson 可读网页版 canonical 字段', () {
      final s = FocusSession.fromJson({
        'id': 'f1',
        'taskId': 't1',
        'taskTitle': '英语',
        'subject': '英语',
        'sceneId': 'fireplace',
        'startAt': '2026-08-07T08:00:00.000Z',
        'endAt': '2026-08-07T08:25:00.000Z',
        'minutes': 25,
        'completed': true,
        'source': 'pomodoro',
        'updatedAt': '2026-08-07T08:25:00.000Z',
      });
      expect(s.durationSec, 1500);
      expect(s.soundScene, 'fireplace');
      expect(s.startedAt.toUtc(), DateTime.utc(2026, 8, 7, 8, 0));
    });

    test('Note.colorHex 兼容网页版旧 color 字段', () {
      final n = Note.fromJson({'id': 'n1', 'title': 't', 'color': '#123456'});
      expect(n.colorHex, '#123456');
    });
  });

  group('自动更新元数据（v0.27.0）', () {
    test('UpdateInfo.fromJson 解析 latest 与 platforms', () {
      final info = UpdateInfo.fromJson({
        'app': 'SugarPaper',
        'latest': {
          'version': '0.27.0',
          'build': 46,
          'published_at': '2026-08-07T00:00:00Z',
          'notes': '- 新增自动更新',
        },
        'platforms': {
          'android': {
            'url': 'https://example.com/sugarpaper.apk',
            'sha256': 'aabbcc',
          },
        },
      });
      expect(info, isNotNull);
      expect(info!.version, '0.27.0');
      expect(info.build, 46);
      expect(info.platforms['android']!.url, 'https://example.com/sugarpaper.apk');
      expect(info.platforms['android']!.sha256, 'aabbcc');
    });
  });
}
