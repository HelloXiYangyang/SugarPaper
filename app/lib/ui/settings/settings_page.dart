/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/app_icons.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/device_capabilities.dart';
import '../../data/rewards.dart';
import '../../data/store.dart';
import '../../data/update_service.dart';
import '../../models/subject_config.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';
import '../widgets/progress_bar.dart';
import '../widgets/sugar_switch.dart';
import 'account_card.dart';
import 'teacher_dialog.dart';
import 'update_dialog.dart';
import '../legal/legal_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final set = state.store.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        _deviceCard(context, ref, state, t),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '个性化',
          children: [
            _row(
              t: t,
              icon: 'bolt',
              title: '帧率模式',
              desc: '高刷新率设备更丝滑，动画自动调速',
              trailing: _fpsSeg(context, ref, state, t),
            ),
            _row(
              t: t,
              icon: 'gauge',
              title: '流畅度自测',
              desc: '测量当前实际显示帧率',
              trailing: SugarButton(
                label: '测一测',
                compact: true,
                onTap: () => _fpsTest(context, ref),
              ),
            ),
            // v0.31.0：Android 8.0+ 才开放本地通知提醒，低版本隐藏
            if (DeviceCapabilities.hasNotifications) ...[
              _switchRow(
                context,
                ref,
                icon: 'bell',
                title: '通知提醒',
                desc: '作业截止与便签本地提醒（同条只提醒一次）',
                value: set.notifications,
                onChanged: (v) {
                  state.store.updateSettings({'notifications': v});
                  state.notify();
                },
              ),
            ],
            _switchRow(
              context,
              ref,
              icon: 'globe',
              title: '互联网模式',
              desc: '跨网络同步（WebRTC 在线直连 / Nostr 中继）',
              value: set.internetMode,
              onChanged: (v) {
                state.store.updateSettings({'internetMode': v});
                state.notify();
              },
            ),
            _row(
              t: t,
              icon: 'sparkles',
              title: '主题',
              desc: '5 套马卡龙配色 + 经典白 + 暗色，自由切换',
              trailing: _themePicker(context, ref, state, t),
            ),
            if (DeviceCapabilities.hasNotifications) ...[
              _row(
                t: t,
                icon: 'bell',
                title: '提醒时间',
                desc: '前一晚 ${set.reminder.eve} · 当天早上 ${set.reminder.morning} 起 2 小时',
                trailing: SugarButton(
                  label: '调整',
                  compact: true,
                  onTap: () => _editReminderTime(context, ref),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '激励与成就',
          children: [
            _row(
              t: t,
              icon: 'bolt',
              title: '每日 XP 目标',
              desc: '完成作业获得经验值，冲刺每日目标',
              trailing: _goalSeg(ref, state, t, 'dailyXp', [30, 50, 80, 100]),
            ),
            _row(
              t: t,
              icon: 'check',
              title: '每日完成目标',
              desc: '每天完成几项作业',
              trailing: _goalSeg(ref, state, t, 'dailyTasks', [2, 3, 5, 8]),
            ),
            _badgeWall(state, t),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '家庭模式',
          children: [
            _familyCard(context, ref, state, t),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '数据管理',
          children: [
            _row(
              t: t,
              icon: 'upload',
              title: '导出数据',
              desc: '将任务与设置导出为 JSON 备份',
              trailing: SugarButton(
                label: '导出',
                compact: true,
                onTap: () => _exportData(context, ref),
              ),
            ),
            _row(
              t: t,
              icon: 'download',
              title: '导入数据',
              desc: '从 JSON 备份文件恢复',
              trailing: SugarButton(
                label: '导入',
                compact: true,
                onTap: () => _importData(context, ref),
              ),
            ),
            _row(
              t: t,
              icon: 'sparkles',
              title: '载入示例数据',
              desc: '快速体验完整功能',
              trailing: SugarButton(
                label: '载入',
                compact: true,
                onTap: () => _loadSample(context, ref),
              ),
            ),
            _row(
              t: t,
              icon: 'trash',
              title: '清空全部数据',
              desc: '删除所有任务与设置（不可恢复）',
              trailing: SugarButton(
                label: '清空',
                compact: true,
                danger: true,
                onTap: () => _reset(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '教师模式',
          children: [
            _row(
              t: t,
              icon: 'file-text',
              title: '布置作业',
              desc: '按标准格式排好作业，复制/导出发到班级群；学生粘贴进糖纸即可一键导入',
              trailing: SugarButton(
                label: '打开',
                iconName: 'bolt',
                compact: true,
                primary: true,
                onTap: () => showTeacherDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '',
          children: const [AccountCard()],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '科目管理',
          children: [
            ...state.store.subjects.map((s) => _subjectRow(context, ref, state, s, t)),
            _row(
              t: t,
              icon: 'plus',
              title: '添加新科目',
              desc: '自定义科目与马卡龙配色',
              trailing: SugarButton(
                label: '添加',
                compact: true,
                primary: true,
                onTap: () => _editSubject(context, ref, null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '更新',
          children: [
            _row(
              t: t,
              icon: 'download',
              title: '检查更新',
              desc: '从 GitHub Pages 读取最新版本并自动安装',
              trailing: SugarButton(
                label: '检查',
                iconName: 'search',
                compact: true,
                primary: true,
                onTap: () => _checkForUpdate(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          t: t,
          title: '法律与隐私',
          children: [
            _row(
              t: t,
              icon: 'file-text',
              title: '用户协议',
              desc: 'v1.0.0 · 首次使用需阅读并同意',
              trailing: SugarButton(
                label: '查看',
                compact: true,
                onTap: () => _openLegal(context, 'terms'),
              ),
            ),
            _row(
              t: t,
              icon: 'file-text',
              title: '隐私政策',
              desc: 'v1.0.0 · 个人信息处理规则',
              trailing: SugarButton(
                label: '查看',
                compact: true,
                onTap: () => _openLegal(context, 'privacy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _aboutCard(t, state),
      ],
    );
  }

  void _openLegal(BuildContext context, String kind) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalViewerPage(kind: kind)),
    );
  }

  /// v0.27.0 检查更新（零服务器方案）。
  Future<void> _checkForUpdate(BuildContext context, WidgetRef ref) async {
    try {
      final update = await const UpdateService().checkForUpdate();
      if (!context.mounted) return;
      await showCheckUpdateResult(context, update: update);
    } catch (e) {
      if (!context.mounted) return;
      showSugarToast(context, '检查更新失败：$e');
    }
  }

  Widget _familyCard(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
  ) {
    final profiles = state.store.settings.familyProfiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前代管成员：${state.store.activeFamilyName}',
          style: TextStyle(fontSize: 12, color: t.text2),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profiles.map((p) {
            final active = p.active;
            return PressableScale(
              onTap: () {
                state.store.setActiveFamily(p.id);
                state.notify();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active ? t.iconMain : t.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SugarIcon(
                      'user',
                      size: 13,
                      color: active ? Colors.white : t.text2,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      p.nickname,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : t.text,
                      ),
                    ),
                    if (!active) ...[
                      const SizedBox(width: 6),
                      PressableScale(
                        onTap: () {
                          state.store.removeFamilyProfile(p.id);
                          state.notify();
                        },
                        child: SugarIcon(
                          'close',
                          size: 11,
                          color: t.text3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SugarButton(
          label: '添加家庭成员',
          iconName: 'plus',
          compact: true,
          onTap: () => _addFamilyMember(context, ref),
        ),
      ],
    );
  }

  void _addFamilyMember(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加家庭成员'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '成员昵称',
            hintText: '例如：妈妈 / 爸爸 / 小明',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                state.store.addFamilyProfile(name);
                state.notify();
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
  ) {
    return Reveal(
      child: SugarCard(
        child: Row(
          children: [
            _AvatarLarge(state, t),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.store.settings.deviceName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '离线优先 · 本地存储\n数据大小：${_dataSize(state.store)}',
                    style: TextStyle(fontSize: 11, height: 1.5, color: t.text3),
                  ),
                ],
              ),
            ),
            SugarButton(
              label: '换头像',
              iconName: 'image',
              compact: true,
              onTap: () => _changeAvatar(context, ref),
            ),
            const SizedBox(width: 6),
            SugarButton(
              label: '改名',
              iconName: 'edit',
              compact: true,
              onTap: () => _renameDevice(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fpsSeg(BuildContext context, WidgetRef ref, AppState state, SugarThemeData t) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface2,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // v0.31.0：Android 11+ 才开放 120 帧档位，低版本只显示 自动/60
        children: (DeviceCapabilities.hasHighRefreshRate
                ? ['auto', '60', '120']
                : ['auto', '60'])
            .map((v) {
          final active = state.store.settings.frameRate == v;
          return PressableScale(
            onTap: () {
              state.store.updateSettings({'frameRate': v});
              state.notify();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                v == 'auto' ? '自动' : '$v 帧',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? t.iconMain : t.text3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// v0.32.0：激励目标分段选择
  Widget _goalSeg(
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
    String key,
    List<int> options,
  ) {
    final current = state.store.settings.rewardsGoals[key] ??
        (key == 'dailyXp' ? 50 : 3);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.surface3,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 2,
        children: options.map((v) {
          final active = current == v;
          return PressableScale(
            onTap: () {
              final goals = Map<String, int>.from(
                  state.store.settings.rewardsGoals);
              goals[key] = v;
              state.store.updateSettings({'rewardsGoals': goals});
              state.notify();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: active ? t.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$v',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? t.iconMain : t.text3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// v0.32.0：成就徽章墙
  Widget _badgeWall(AppState state, SugarThemeData t) {
    final unlockedMap = RewardsEngine.unlocked(state.store);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
        children: RewardsEngine.badges.map((b) {
          final unlockedAt = unlockedMap[b.id];
          final ok = unlockedAt != null;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: ok ? t.iconSoft : t.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ok ? t.iconMain : t.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SugarIcon(b.icon, size: 22, color: ok ? t.iconMain : t.text3),
                const SizedBox(height: 5),
                Text(
                  b.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ok ? t.text : t.text3,
                  ),
                ),
                if (ok)
                  Text(
                    unlockedAt.length >= 10
                        ? unlockedAt.substring(5, 10)
                        : '',
                    style: TextStyle(fontSize: 9, color: t.text3),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _themePicker(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SugarThemeData t,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: kThemes.map((key) {
        final active = state.store.settings.theme == key;
        final colors = kThemeGradients[key]!;
        return PressableScale(
          onTap: () {
            state.store.updateSettings({'theme': key});
            state.notify();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? t.iconMain : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: t.iconMain.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subjectRow(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    SubjectConfig s,
    SugarThemeData t,
  ) {
    return Row(
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
        Expanded(
          child: Text(
            s.name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text),
          ),
        ),
        Text(
          s.enabled ? '已启用' : '已停用',
          style: TextStyle(fontSize: 11, color: t.text3),
        ),
        const SizedBox(width: 6),
        SugarButton(
          label: s.enabled ? '停用' : '启用',
          compact: true,
          onTap: () {
            state.store.updateSubject(s.name, {'enabled': !s.enabled});
            state.notify();
          },
        ),
        const SizedBox(width: 4),
        _miniBtn(context, t, 'edit', () => _editSubject(context, ref, s)),
        const SizedBox(width: 4),
        _miniBtn(
          context,
          t,
          'trash',
          () {
            state.store.removeSubject(s.name);
            state.notify();
          },
          danger: true,
        ),
      ],
    );
  }

  Widget _miniBtn(
    BuildContext context,
    SugarThemeData t,
    String icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
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

  Widget _row({
    required SugarThemeData t,
    required String icon,
    required String title,
    required String desc,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SugarIcon(icon, size: 16, color: t.iconMain),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: t.text3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _switchRow(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return _row(
      t: t,
      icon: icon,
      title: title,
      desc: desc,
      trailing: SugarSwitch(value: value, onChanged: onChanged),
    );
  }

  Widget _card({
    required SugarThemeData t,
    required String title,
    required List<Widget> children,
  }) {
    return Reveal(
      child: SugarCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _aboutCard(SugarThemeData t, AppState state) {
    return Reveal(
      child: SugarCard(
        child: Column(
          children: [
            // 应用图标：与桌面图标 / 网页版 icon.svg 同源
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '糖纸 · SugarPaper',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: t.text,
              ),
            ),
            Text(
              'v${AppStore.appVersion}（安卓版）',
              style: TextStyle(fontSize: 12, color: t.text3),
            ),
            const SizedBox(height: 6),
            Text(
              '让作业管理像糖果一样甜美简单。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: t.text2),
            ),
            Text(
              '离线优先 · 设备直连 · 马卡龙美学 · 零服务器依赖',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: t.text3),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 操作 ----------

  String _dataSize(AppStore store) {
    final bytes = utf8.encode(store.exportJSON()).length;
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void _renameDevice(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    final controller = TextEditingController(text: state.store.settings.deviceName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改设备名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：我的手机'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              state.store.updateSettings({
                'deviceName': controller.text.trim(),
              });
              state.notify();
              Navigator.pop(ctx);
              showSugarToast(context, '设备名称已更新');
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final state = ref.read(appStateProvider);
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final picked = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '更换头像',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 14),
              SugarButton(
                label: '从相册选择图片',
                iconName: 'image',
                primary: true,
                onTap: () async {
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 88,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
              const SizedBox(height: 8),
              SugarButton(
                label: '恢复默认头像',
                iconName: 'undo',
                onTap: () {
                  state.store.updateSettings({'avatar': null});
                  state.notify();
                  Navigator.pop(ctx);
                  showSugarToast(context, '已恢复默认头像');
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dataUri = await _compressAvatar(bytes);
    if (!context.mounted) return;
    state.store.updateSettings({'avatar': dataUri});
    state.notify();
    showSugarToast(context, '头像已更新');
  }

  Future<String?> _compressAvatar(List<int> bytes) async {
    try {
      final decoded = img.decodeImage(Uint8List.fromList(bytes));
      if (decoded == null) return null;
      final resized = img.copyResize(decoded, width: 256, height: 256);
      final jpg = img.encodeJpg(resized, quality: 85);
      return 'data:image/jpeg;base64,${base64Encode(jpg)}';
    } catch (_) {
      return null;
    }
  }

  void _fpsTest(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    // 简化自测：以 60/90/120/144 中最近档位估算
    showSugarToast(
      context,
      '当前实际帧率：约 ${state.detectedFps} FPS · 动画档位 ${state.resolveFps()}',
    );
  }

  /// v0.22.0 提醒时间自定义（对齐网页版 settings.reminder）。
  Future<void> _editReminderTime(BuildContext context, WidgetRef ref) async {
    final state = ref.read(appStateProvider);
    var cfg = state.store.settings.reminder;

    Future<TimeOfDay?> pick(String label, String hhmm) {
      final parts = hhmm.split(':');
      return showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 20,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
        ),
        helpText: label,
      );
    }

    final eve = await pick('前一晚提醒时间', cfg.eve);
    if (eve == null || !context.mounted) return;
    final morning = await pick('当天早上提醒窗口起点', cfg.morning);
    if (morning == null || !context.mounted) return;

    String fmt(TimeOfDay x) =>
        '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
    cfg = cfg.copyWith(eve: fmt(eve), morning: fmt(morning));
    state.store.updateSettings({'reminder': cfg.toJson()});
    state.notify();
    showSugarToast(
      context,
      '提醒时间已更新：前一晚 ${cfg.eve} · 早上 ${cfg.morning}',
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    state.store.updateSettings({
      'lastBackupAt': DateTime.now().toIso8601String(),
    });
    Clipboard.setData(ClipboardData(text: state.store.exportJSON()));
    state.notify();
    showSugarToast(context, '备份 JSON 已复制到剪贴板');
  }

  void _importData(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入 JSON 备份'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '粘贴糖纸备份 JSON（从剪贴板导出的内容）',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              try {
                state.store.importJSON(controller.text);
                state.notify();
                Navigator.pop(ctx);
                showSugarToast(context, '数据已导入');
              } catch (e) {
                showSugarToast(context, '导入失败：不是有效的备份文件');
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _loadSample(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    final now = DateTime.now().toUtc();
    final base = now.subtract(const Duration(days: 3));
    int order = state.store.tasks.length + 1;
    state.store.addTasks([
      {
        'subject': '语文',
        'title': '背《昆虫记》讲义',
        'subtitle': '自己印的',
        'priority': 2,
        'dueDate': _fmtDue(now, 2),
        'createdAt': base.toIso8601String(),
        'order': order++,
      },
      {
        'subject': '数学',
        'title': '试卷一张',
        'subtitle': '周一收',
        'priority': 1,
        'dueDate': _fmtDue(now, 3),
        'createdAt': base.toIso8601String(),
        'order': order++,
      },
      {
        'subject': '英语',
        'title': '默写 49 个过去分词',
        'subtitle': '优秀组默 1 遍',
        'priority': 1,
        'dueDate': _fmtDue(now, 1),
        'createdAt': base.toIso8601String(),
        'order': order++,
      },
    ]);
    state.notify();
    showSugarToast(context, '示例数据已载入');
  }

  String _fmtDue(DateTime now, int days) {
    final d = DateTime(now.year, now.month, now.day + days);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _reset(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部数据'),
        content: const Text('将删除所有任务、科目与设置，且无法恢复。建议先导出备份。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              state.store.reset();
              state.notify();
              Navigator.pop(ctx);
              showSugarToast(context, '数据已清空');
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editSubject(
    BuildContext context,
    WidgetRef ref,
    SubjectConfig? subject,
  ) {
    final state = ref.read(appStateProvider);
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final nameController = TextEditingController(text: subject?.name ?? '');
    String color = subject?.colorHex ?? kSubjectPalette[0];
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(subject == null ? '添加科目' : '编辑科目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '科目名称'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSubjectPalette.map((c) {
                  final active = color == c;
                  return GestureDetector(
                    onTap: () => setLocal(() => color = c),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                if (subject == null) {
                  final ok = state.store.addSubject(name, color);
                  if (!ok) {
                    showSugarToast(ctx, '该科目已存在');
                    return;
                  }
                } else {
                  state.store.updateSubject(subject.name, {
                    'name': name,
                    'colorHex': color,
                  });
                }
                state.notify();
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarLarge extends StatelessWidget {
  final AppState state;
  final SugarThemeData t;

  const _AvatarLarge(this.state, this.t);

  @override
  Widget build(BuildContext context) {
    final avatar = state.store.settings.avatar;
    if (avatar == null) {
      // 默认头像：与网页版一致的内置喜羊羊图片
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/avatar-default.jpg',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }
    Widget child;
    if (avatar.startsWith('data:')) {
      final comma = avatar.indexOf(',');
      final bytes = comma < 0
          ? const <int>[]
          : base64Decode(avatar.substring(comma + 1));
      child = Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SugarIcon('user', size: 26),
      );
    } else {
      child = const SugarIcon('user', size: 26);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        color: t.surface2,
        child: child,
      ),
    );
  }
}
