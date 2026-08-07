/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../models/app_settings.dart';
import '../models/account.dart';
import '../models/family_profile.dart';
import '../models/focus_session.dart';
import '../models/note.dart';
import '../models/subject_config.dart';
import '../models/task.dart';

/// 本地存储与状态管理（离线优先）。
/// 数据格式与 Web 版 `web/js/store.js` 完全一致，备份可互相导入。
class AppStore {
  static const String appVersion = '0.25.0';
  static const String storageFileName = 'sugarpaper.json';

  final List<Task> tasks = [];
  final List<Note> notes = [];
  final List<FocusSession> focusSessions = [];
  Account? account; // v0.16.0 无服务器账号
  List<SubjectConfig> subjects = [...kDefaultSubjects];
  AppSettings settings = const AppSettings(subjects: []);

  /// 用于测试时注入目录；null 时使用应用文档目录。
  Directory? overrideDir;

  /// 数据持久化后的回调（用于触发提醒检查等）。
  void Function(AppStore store)? onPersist;

  Future<Directory> _dir() async {
    if (overrideDir != null) return overrideDir!;
    final docs = await getApplicationDocumentsDirectory();
    return docs;
  }

  AppSettings get fullSettings =>
      settings.copyWith(subjects: subjects.toList());

  Future<void> load() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$storageFileName');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        _fromBackup(raw is String ? jsonDecode(raw) : raw);
      }
    } catch (e) {
      // 读取失败时使用默认状态，不阻塞启动
    }
    if (subjects.isEmpty) subjects = [...kDefaultSubjects];
  }

  Future<void> persist() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}${Platform.pathSeparator}$storageFileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_toBackup()),
      );
    } catch (_) {}
    onPersist?.call(this);
  }

  Map<String, dynamic> _toBackup() => {
        'app': 'SugarPaper',
        'kind': 'backup',
        'version': appVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'focusSessions': focusSessions.map((s) => s.toJson()).toList(),
        'account': account?.toJson(),
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'settings': fullSettings.toJson(),
      };

  void _fromBackup(Map<String, dynamic> d) {
    tasks
      ..clear()
      ..addAll((d['tasks'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e))));
    notes
      ..clear()
      ..addAll((d['notes'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Note.fromJson(Map<String, dynamic>.from(e))));
    focusSessions
      ..clear()
      ..addAll((d['focusSessions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => FocusSession.fromJson(Map<String, dynamic>.from(e))));
    account = d['account'] is Map
        ? Account.fromJson(Map<String, dynamic>.from(d['account'] as Map))
        : null;
    final subs = (d['subjects'] as List?)
        ?.whereType<Map>()
        .map((e) => SubjectConfig.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (subs != null && subs.isNotEmpty) {
      subjects = subs;
    }
    final set = AppSettings.fromJson(
        Map<String, dynamic>.from((d['settings'] as Map?) ?? {}));
    settings = set.copyWith(subjects: subjects);
  }

  // ---------- 任务操作（语义与 Web 版 store.js 一致） ----------

  String _uuid() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-'
      '${_rand()}';

  String _rand() =>
      List.generate(16, (_) => (0x20 + (DateTime.now().microsecondsSinceEpoch % 0x5f)).toRadixString(36)).join();

  int _maxOrder() => tasks
      .where((t) => !t.isDeleted)
      .fold(0, (mx, t) => t.order > mx ? t.order : mx);

  Task _normalize(Map<String, dynamic> input) {
    final now = DateTime.now().toUtc();
    return Task(
      id: input['id'] as String? ?? _uuid(),
      subject: (input['subject'] as String?)?.isNotEmpty == true
          ? input['subject'] as String
          : '默认',
      title: (input['title'] as String? ?? '').trim(),
      subtitle: input['subtitle'] as String? ?? '',
      isCompleted: input['isCompleted'] == true,
      order: (input['order'] as num?)?.toInt() ?? _maxOrder() + 1,
      createdAt: input['createdAt'] is String
          ? DateTime.tryParse(input['createdAt'] as String)?.toLocal() ?? now
          : now,
      updatedAt: input['updatedAt'] is String
          ? DateTime.tryParse(input['updatedAt'] as String)?.toLocal() ?? now
          : now,
      isDeleted: input['isDeleted'] == true,
      completedAt: input['completedAt'] is String
          ? DateTime.tryParse(input['completedAt'] as String)?.toLocal()
          : null,
      dueDate: input['dueDate'] is String
          ? _parseDateStr(input['dueDate'] as String)
          : null,
      priority: (input['priority'] as num?)?.toInt() ?? 1,
      taskType: (input['taskType'] as String?) ?? 'written',
      confirmed: input['confirmed'] == true,
      images: input['images'] is List
          ? (input['images'] as List).whereType<String>().take(4).toList()
          : const [],
    );
  }

  DateTime? _parseDateStr(String s) {
    final p = s.split('-').map(int.tryParse).toList();
    if (p.length != 3 || p.any((x) => x == null)) return null;
    return DateTime(p[0]!, p[1]! - 1, p[2]!);
  }

  Task addTask(Map<String, dynamic> input) {
    final t = _normalize(input);
    tasks.add(t);
    persist();
    return t;
  }

  List<Task> addTasks(List<Map<String, dynamic>> list) {
    final added = list.map(_normalize).toList();
    tasks.addAll(added);
    persist();
    return added;
  }

  Task? findTask(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Task? updateTask(String id, Map<String, dynamic> patch) {
    final t = findTask(id);
    if (t == null) return null;
    var copy = t;
    if (patch.containsKey('subject')) copy = copy.copyWith(subject: patch['subject'] as String?);
    if (patch.containsKey('title')) copy = copy.copyWith(title: patch['title'] as String?);
    if (patch.containsKey('subtitle')) copy = copy.copyWith(subtitle: patch['subtitle'] as String?);
    if (patch.containsKey('order')) copy = copy.copyWith(order: (patch['order'] as num).toInt());
    if (patch.containsKey('isCompleted')) copy = copy.copyWith(isCompleted: patch['isCompleted'] as bool);
    if (patch.containsKey('priority')) copy = copy.copyWith(priority: (patch['priority'] as num).toInt());
    if (patch.containsKey('dueDate')) copy = copy.copyWith(dueDate: _parseDateStr(patch['dueDate'] as String));
    if (patch.containsKey('images')) {
      copy = copy.copyWith(
        images: (patch['images'] as List)
            .whereType<String>()
            .take(4)
            .toList(),
      );
    }
    copy = copy.copyWith(updatedAt: DateTime.now().toUtc());
    final i = tasks.indexOf(t);
    tasks[i] = copy;
    persist();
    return copy;
  }

  void deleteTask(String id) {
    final t = findTask(id);
    if (t == null) return;
    final i = tasks.indexOf(t);
    tasks[i] = t.copyWith(isDeleted: true, updatedAt: DateTime.now().toUtc());
    persist();
  }

  Task? toggleComplete(String id) {
    final t = findTask(id);
    if (t == null) return null;
    final now = DateTime.now().toUtc();
    final completed = !t.isCompleted;
    final i = tasks.indexOf(t);
    tasks[i] = t.copyWith(
      isCompleted: completed,
      completedAt: completed ? now : null,
      updatedAt: now,
    );
    persist();
    return tasks[i];
  }

  void moveTask(String id, int dir) {
    final active = tasks
        .where((t) => !t.isDeleted && !t.isCompleted)
        .toList()
      ..sort((a, b) {
        final c = a.order.compareTo(b.order);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    final i = active.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final j = i + dir;
    if (j < 0 || j >= active.length) return;
    final a = tasks.indexOf(active[i]);
    final b = tasks.indexOf(active[j]);
    final tmp = tasks[a].order;
    tasks[a] = tasks[a].copyWith(
      order: tasks[b].order,
      updatedAt: DateTime.now().toUtc(),
    );
    tasks[b] = tasks[b].copyWith(order: tmp, updatedAt: DateTime.now().toUtc());
    persist();
  }

  void importTasks(List<Map<String, dynamic>> list, String mode) {
    if (mode == 'overwrite') {
      tasks.clear();
    }
    addTasks(list);
  }

  // ---------- 专注会话（v5.0） ----------

  FocusSession addFocusSession(Map<String, dynamic> input) {
    final now = DateTime.now();
    final session = FocusSession(
      id: input['id'] as String? ?? _uuid(),
      taskId: input['taskId'] as String?,
      taskTitle: (input['taskTitle'] as String?) ?? '自由专注',
      startedAt: now,
      durationSec: (input['durationSec'] as num?)?.toInt() ?? 0,
      pomodoros: (input['pomodoros'] as num?)?.toInt() ?? 1,
      soundScene: (input['soundScene'] as String?) ?? 'none',
    );
    focusSessions.add(session);
    persist();
    return session;
  }

  // ---------- 便签操作（v5.0） ----------

  Note addNote(Map<String, dynamic> input) {
    final now = DateTime.now();
    final note = Note(
      id: input['id'] as String? ?? _uuid(),
      title: input['title'] as String? ?? '',
      content: input['content'] as String? ?? '',
      colorHex: input['colorHex'] as String? ?? '#FBE4EC',
      pinned: input['pinned'] == true,
      archived: input['archived'] == true,
      images: input['images'] is List
          ? (input['images'] as List).whereType<String>().take(4).toList()
          : const [],
      createdAt: input['createdAt'] is String
          ? DateTime.tryParse(input['createdAt'] as String)?.toLocal() ?? now
          : now,
      updatedAt: now,
    );
    notes.add(note);
    persist();
    return note;
  }

  Note? updateNote(String id, Map<String, dynamic> patch) {
    final i = notes.indexWhere((n) => n.id == id);
    if (i < 0) return null;
    final n = notes[i];
    final next = n.copyWith(
      title: patch['title'] as String?,
      content: patch['content'] as String?,
      colorHex: patch['colorHex'] as String?,
      pinned: patch['pinned'] as bool?,
      archived: patch['archived'] as bool?,
      isDeleted: patch['isDeleted'] as bool?,
      remindAt: patch['remindAt'] is String
          ? DateTime.tryParse(patch['remindAt'] as String)?.toLocal()
          : patch['remindAt'] as DateTime?,
      images: patch['images'] is List
          ? (patch['images'] as List).whereType<String>().toList()
          : null,
      updatedAt: DateTime.now(),
    );
    notes[i] = next;
    persist();
    return next;
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    persist();
  }

  // ---------- 科目操作 ----------

  String subjectColor(String name) {
    for (final s in subjects) {
      if (s.name == name) return s.colorHex;
    }
    return '#C9C7F0';
  }

  bool addSubject(String name, String color) {
    if (subjects.any((s) => s.name == name)) return false;
    subjects = [...subjects, SubjectConfig(name: name, colorHex: color)];
    settings = settings.copyWith(subjects: subjects);
    persist();
    return true;
  }

  bool updateSubject(String name, Map<String, dynamic> patch) {
    final i = subjects.indexWhere((s) => s.name == name);
    if (i < 0) return false;
    final old = subjects[i];
    final newName = patch['name'] as String? ?? old.name;
    final newSub = SubjectConfig(
      name: newName,
      colorHex: patch['colorHex'] as String? ?? old.colorHex,
      enabled: patch['enabled'] as bool? ?? old.enabled,
    );
    final next = [...subjects];
    next[i] = newSub;
    subjects = next;
    if (newName != old.name) {
      for (var k = 0; k < tasks.length; k++) {
        if (tasks[k].subject == old.name) {
          tasks[k] = tasks[k].copyWith(
            subject: newName,
            updatedAt: DateTime.now().toUtc(),
          );
        }
      }
    }
    settings = settings.copyWith(subjects: subjects);
    persist();
    return true;
  }

  void removeSubject(String name) {
    subjects = subjects.where((s) => s.name != name).toList();
    settings = settings.copyWith(subjects: subjects);
    persist();
  }

  // ---------- 设置 ----------

  void updateSettings(Map<String, dynamic> patch) {
    var s = settings;
    if (patch.containsKey('deviceName')) {
      s = s.copyWith(deviceName: patch['deviceName'] as String);
    }
    if (patch.containsKey('notifications')) {
      s = s.copyWith(notifications: patch['notifications'] as bool);
    }
    if (patch.containsKey('internetMode')) {
      s = s.copyWith(internetMode: patch['internetMode'] as bool);
    }
    if (patch.containsKey('animations')) {
      s = s.copyWith(animations: patch['animations'] as bool);
    }
    if (patch.containsKey('frameRate')) {
      s = s.copyWith(frameRate: patch['frameRate'] as String);
    }
    if (patch.containsKey('theme')) {
      s = s.copyWith(theme: patch['theme'] as String);
    }
    if (patch.containsKey('avatar')) {
      s = s.copyWith(avatar: patch['avatar'] as String?);
    }
    if (patch.containsKey('lastBackupAt')) {
      s = s.copyWith(lastBackupAt: patch['lastBackupAt'] as String?);
    }
    if (patch.containsKey('notifiedDue')) {
      s = s.copyWith(
        notifiedDue: Map<String, bool>.from(
          (patch['notifiedDue'] as Map).map(
            (k, v) => MapEntry(k.toString(), v == true),
          ),
        ),
      );
    }
    if (patch.containsKey('notifiedNotes')) {
      s = s.copyWith(
        notifiedNotes: Map<String, bool>.from(
          (patch['notifiedNotes'] as Map).map(
            (k, v) => MapEntry(k.toString(), v == true),
          ),
        ),
      );
    }
    if (patch.containsKey('familyProfiles')) {
      s = s.copyWith(
        familyProfiles: (patch['familyProfiles'] as List)
            .map((e) => FamilyProfile.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
      );
    }
    if (patch.containsKey('relays')) {
      s = s.copyWith(
        relays: (patch['relays'] as List).whereType<String>().toList(),
      );
    }
    if (patch.containsKey('autoSync')) {
      s = s.copyWith(autoSync: patch['autoSync'] as bool);
    }
    if (patch.containsKey('reminder') && patch['reminder'] is Map) {
      s = s.copyWith(
        reminder: ReminderConfig.fromJson(
          Map<String, dynamic>.from(patch['reminder'] as Map),
        ),
      );
    }
    if (patch.containsKey('focus') && patch['focus'] is Map) {
      s = s.copyWith(
        focus: FocusConfig.fromJson(
          Map<String, dynamic>.from(patch['focus'] as Map),
        ),
      );
    }
    settings = s.copyWith(subjects: subjects);
    persist();
  }

  // ---------- 家庭模式（v0.17.0） ----------

  // ---------- 账号（v0.16.0） ----------

  void setAccount(Account acc) {
    account = acc;
    persist();
  }

  void updateAccount(Map<String, dynamic> patch) {
    final a = account;
    if (a == null) return;
    account = a.copyWith(
      pubkey: patch['pubkey'] as String?,
      seedB64: patch['seedB64'] as String?,
      mnemonic: patch['mnemonic'] as String?,
      displayName: patch['displayName'] as String?,
      version: patch['version'] as int?,
      lastSyncAt: patch['lastSyncAt'] as String?,
      devices: patch['devices'] is List
          ? (patch['devices'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
    );
    persist();
  }

  void clearAccount() {
    account = null;
    persist();
  }

  /// 用合并后的快照整体替换本地数据（WebRTC DataChannel 接收端）。
  void replaceAll({
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> notes,
    required List<Map<String, dynamic>> focusSessions,
  }) {
    this.tasks
      ..clear()
      ..addAll(tasks.map((e) => Task.fromJson(e)));
    this.notes
      ..clear()
      ..addAll(notes.map((e) => Note.fromJson(e)));
    this.focusSessions
      ..clear()
      ..addAll(focusSessions.map((e) => FocusSession.fromJson(e)));
    persist();
  }

  FamilyProfile addFamilyProfile(String nickname) {
    final list = [...settings.familyProfiles];
    if (list.isEmpty) {
      list.add(FamilyProfile(id: _uuid(), nickname: nickname, active: true));
    } else {
      list.add(FamilyProfile(id: _uuid(), nickname: nickname));
    }
    settings = settings.copyWith(familyProfiles: list, subjects: subjects);
    persist();
    return list.last;
  }

  void removeFamilyProfile(String id) {
    final list = settings.familyProfiles
        .where((p) => p.id != id)
        .toList();
    if (list.isNotEmpty && !list.any((p) => p.active)) {
      list[0] = list[0].copyWith(active: true);
    }
    settings = settings.copyWith(familyProfiles: list, subjects: subjects);
    persist();
  }

  void setActiveFamily(String id) {
    settings = settings.copyWith(
      familyProfiles: settings.familyProfiles
          .map((p) => p.copyWith(active: p.id == id))
          .toList(),
      subjects: subjects,
    );
    persist();
  }

  String get activeFamilyName {
    for (final p in settings.familyProfiles) {
      if (p.active) return p.nickname;
    }
    return settings.familyProfiles.isEmpty
        ? '自己'
        : settings.familyProfiles.first.nickname;
  }

  // ---------- 备份 ----------

  String exportJSON() =>
      const JsonEncoder.withIndent('  ').convert(_toBackup());

  void importJSON(String json) {
    final d = jsonDecode(json);
    if (d is! Map || d['tasks'] is! List) {
      throw const FormatException('不是有效的糖纸备份文件');
    }
    _fromBackup(Map<String, dynamic>.from(d));
    persist();
  }

  void reset() {
    tasks.clear();
    notes.clear();
    focusSessions.clear();
    account = null;
    subjects = [...kDefaultSubjects];
    settings = const AppSettings(subjects: []);
    persist();
  }
}
