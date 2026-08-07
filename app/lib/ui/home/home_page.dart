/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../models/task.dart';
import '../widgets/basic.dart';
import '../widgets/progress_bar.dart';
import '../focus/focus_page.dart';
import 'edit_sheet.dart';
import 'import_sheet.dart';
import 'task_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showCelebrate = false;

  void _celebrate() {
    setState(() => _showCelebrate = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showCelebrate = false);
    });
  }

  void _toggleTask(String id) {
    final state = ref.read(appStateProvider);
    final before = state.allTasks.where((t) => !t.isCompleted).length;
    state.store.toggleComplete(id);
    state.notify();
    final after = state.allTasks.where((t) => !t.isCompleted).length;
    if (before > 0 && after == 0 && state.allTasks.isNotEmpty) {
      _celebrate();
    }
  }

  void _loadSample() {
    final state = ref.read(appStateProvider);
    final now = DateTime.now().toUtc();
    final base = now.subtract(const Duration(days: 3));
    Task mk(
      String subject,
      String title,
      String subtitle,
      int priority,
      int days,
    ) {
      return Task(
        id: 'sample-${title.hashCode.toRadixString(16)}',
        subject: subject,
        title: title,
        subtitle: subtitle,
        order: state.store.tasks.length + 1,
        createdAt: base,
        updatedAt: now,
        priority: priority,
        dueDate: DateTime(now.year, now.month, now.day + days),
      );
    }

    state.store.addTasks([
      mk('语文', '背《昆虫记》讲义', '自己印的\n重点 2~5 页', 2, 2).toJson(),
      mk('数学', '试卷一张', '周一收\n包含最后两道大题', 1, 3).toJson(),
      mk('英语', '默写 49 个过去分词', '优秀组默 1 遍', 1, 1).toJson(),
      mk('物理', '练习册 P45-P48', '实验题要写过程', 0, 4).toJson(),
      mk('化学', '预习第四章', '下周课堂小测', 1, 5).toJson(),
    ]);
    state.notify();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final all = state.allTasks;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            _buildTopBar(context, state, t),
            if (_needsBackup(state)) ...[
              const SizedBox(height: 10),
              _backupBanner(context, state, t),
            ],
            const SizedBox(height: 14),
            _buildFilterBar(state, t),
            if (all.isEmpty)
              EmptyState(
                iconName: 'candy',
                title: '欢迎使用糖纸',
                subtitle: '粘贴老师发的作业消息，一键解析成清单。',
                actions: [
                  SugarButton(
                    label: '导入作业',
                    iconName: 'file-text',
                    primary: true,
                    onTap: () => showImportSheet(context),
                  ),
                  SugarButton(
                    label: '载入示例数据',
                    iconName: 'sparkles',
                    onTap: _loadSample,
                  ),
                ],
              )
            else if (state.filteredTasks.isEmpty &&
                (state.query.isNotEmpty ||
                    state.subject != '全部' ||
                    state.priority != 'all'))
              const EmptyState(
                iconName: 'search',
                title: '没有匹配的作业',
                subtitle: '换个关键词或筛选条件试试',
              )
            else ...[
              // v5.0 截止分级：逾期/今天/明天/本周/长期
              if (state.groupedActiveTasks.isEmpty)
                const EmptyState(title: '太棒啦，这里空空如也！')
              else
                ...state.groupedActiveTasks.expand((g) => [
                      GroupHeader(
                        iconName: g.icon,
                        label: g.label,
                        count: g.tasks.length,
                        accent: g.key == 'overdue'
                            ? t.dangerStrong
                            : g.key == 'today'
                                ? t.iconMain
                                : t.skyStrong,
                      ),
                      ...g.tasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              subjectColor:
                                  state.store.subjectColor(task.subject),
                              onToggle: () => _toggleTask(task.id),
                              onEdit: () => showEditSheet(context, task: task),
                              onDelete: () =>
                                  _confirmDelete(context, state, task),
                              onFocus: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FocusPage(task: task),
                                  ),
                                );
                              },
                              onConfirm: () {
                                state.store.updateTask(task.id, {
                                  'confirmed': !task.confirmed,
                                });
                                state.notify();
                              },
                              onMoveUp: () {
                                state.store.moveTask(task.id, -1);
                                state.notify();
                              },
                              onMoveDown: () {
                                state.store.moveTask(task.id, 1);
                                state.notify();
                              },
                            ),
                          )),
                    ]),
              GroupHeader(
                iconName: 'check',
                label: '已完成',
                count: state.doneTasks.length,
                accent: t.mintStrong,
              ),
              if (state.doneTasks.isEmpty)
                const EmptyState(
                  iconName: 'sun',
                  title: '还没有完成的作业，加油！',
                )
              else
                ...state.doneTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        subjectColor: state.store.subjectColor(task.subject),
                        onToggle: () => _toggleTask(task.id),
                        onEdit: () => showEditSheet(context, task: task),
                        onDelete: () => _confirmDelete(context, state, task),
                      ),
                    )),
            ],
          ],
        ),
        if (_showCelebrate) const _ConfettiOverlay(),
      ],
    );
  }

  bool _needsBackup(AppState state) {
    if (state.allTasks.isEmpty) return false;
    final last = state.store.settings.lastBackupAt;
    if (last == null) return true;
    final t = DateTime.tryParse(last);
    if (t == null) return true;
    return DateTime.now().difference(t).inDays >= 7;
  }

  Widget _backupBanner(BuildContext context, AppState state, SugarThemeData t) {
    return Reveal(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.yellowSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.yellow.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            SugarIcon('save', size: 15, color: t.yellowStrong),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '距上次备份已超过 7 天，建议导出备份',
                style: TextStyle(fontSize: 11.5, color: t.yellowStrong),
              ),
            ),
            SugarButton(
              label: '去备份',
              compact: true,
              onTap: () => state.navigate('settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppState state,
    SugarThemeData t,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // 品牌 Logo：与桌面图标 / 网页版 icon.svg 同源
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '糖纸',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: t.text,
              ),
            ),
            const Spacer(),
            PressableScale(
              onTap: () => showImportSheet(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.pinkSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: SugarIcon('plus', size: 18, color: t.iconMain),
              ),
            ),
            const SizedBox(width: 8),
            PressableScale(
              onTap: () => state.navigate('settings'),
              child: _Avatar(state, t),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ShimmerProgressBar(percent: state.progressPercent.toDouble()),
            ),
            const SizedBox(width: 10),
            Text(
              '${state.progressPercent}% · '
              '${state.allTasks.where((t) => t.isCompleted).length}/'
              '${state.allTasks.length}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.text2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(AppState state, SugarThemeData t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    SugarIcon('search', size: 14, color: t.text3),
                    const SizedBox(width: 6),
                    Expanded(child: _SearchField(state: state)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PrioritySelect(state, t),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SubjectChip(
                name: '全部',
                colorHex: '#F4B8CE',
                count: state.allTasks.length,
                active: state.subject == '全部',
                onTap: () => state.setSubject('全部'),
              ),
              const SizedBox(width: 8),
              ...state.enabledSubjects.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SubjectChip(
                      name: s.name,
                      colorHex: s.colorHex,
                      count: state.subjectCounts[s.name] ?? 0,
                      active: state.subject == s.name,
                      onTap: () => state.setSubject(s.name),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Task task) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除作业'),
        content: Text('确定删除「${task.title}」吗？删除后可重新导入。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.store.deleteTask(task.id);
              state.notify();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 搜索框（180ms 防抖，对应 Web 版 debounce）。
class _SearchField extends StatefulWidget {
  final AppState state;

  const _SearchField({required this.state});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: '搜索作业...',
      ),
      style: TextStyle(fontSize: 13, color: t.text),
      onChanged: (v) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 180), () {
          widget.state.setQuery(v);
        });
      },
    );
  }
}

class _PrioritySelect extends StatelessWidget {
  final AppState state;
  final SugarThemeData t;

  const _PrioritySelect(this.state, this.t);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.priority,
          isDense: true,
          icon: SugarIcon('chevron-down', size: 14, color: t.text3),
          style: TextStyle(fontSize: 12, color: t.text),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('全部优先级')),
            DropdownMenuItem(value: '2', child: Text('高')),
            DropdownMenuItem(value: '1', child: Text('中')),
            DropdownMenuItem(value: '0', child: Text('低')),
          ],
          onChanged: (v) {
            if (v != null) state.setPriority(v);
          },
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppState state;
  final SugarThemeData t;

  const _Avatar(this.state, this.t);

  @override
  Widget build(BuildContext context) {
    final avatar = state.store.settings.avatar;
    if (avatar == null) {
      // 默认头像：与网页版一致的内置喜羊羊图片
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          'assets/avatar-default.jpg',
          width: 34,
          height: 34,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 34,
        height: 34,
        color: t.surface2,
        child: avatar.startsWith('data:')
            ? Image.memory(
                Uint8List.fromList(_dataUriBytes(avatar)),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SugarIcon('user', size: 18),
            )
            : const SugarIcon('user', size: 18),
      ),
    );
  }

  static List<int> _dataUriBytes(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma < 0) return const [];
    final b64 = dataUri.substring(comma + 1);
    try {
      return base64Decode(b64);
    } catch (_) {
      return const [];
    }
  }
}

/// 全部完成撒花：轻量五彩纸屑粒子动画（持续约 1.8 秒）。
class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    final rng = math.Random(42);
    _particles = List.generate(80, (_) => _ConfettiParticle(rng));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🎉 太棒啦！',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: t.iconMain,
                        ),
                      ),
                      Text(
                        '全部作业完成',
                        style: TextStyle(fontSize: 13, color: t.text2),
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(_c.value, _particles, t),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double angle;
  final Color color;
  final double spin;

  _ConfettiParticle(math.Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble() * 0.4,
        speed = 0.35 + rng.nextDouble() * 0.45,
        size = 4 + rng.nextDouble() * 6,
        angle = rng.nextDouble() * math.pi * 2,
        spin = (rng.nextDouble() - 0.5) * 12,
        color = _colors[rng.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFFF4B8CE),
    Color(0xFFA9E0CB),
    Color(0xFFB3D4F0),
    Color(0xFFFBE6B9),
    Color(0xFFC9C7F0),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ConfettiParticle> particles;
  final SugarThemeData theme;

  _ConfettiPainter(this.t, this.particles, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + p.speed * t) * size.height;
      if (y > size.height) continue;
      final x = (p.x + math.sin(t * 2 + p.angle) * 0.04) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * p.spin + p.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
