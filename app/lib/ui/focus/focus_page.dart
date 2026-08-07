/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/app_state.dart';
import '../../data/noise_gen.dart';
import '../../models/app_settings.dart';
import '../../models/task.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';
import '../widgets/sugar_switch.dart';

const _presets = [
  ('pomodoro', '番茄', 25 * 60),
  ('short', '短休', 5 * 60),
  ('long', '长休', 15 * 60),
  ('free', '自由', 0),
];

class FocusPage extends ConsumerStatefulWidget {
  final Task? task;

  const FocusPage({super.key, this.task});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage>
    with SingleTickerProviderStateMixin {
  String _preset = 'pomodoro';
  int _remaining = 25 * 60;
  int _total = 25 * 60;
  bool _running = false;
  Timer? _timer;
  String _scene = 'none';
  bool _done = false;
  bool _breathOn = true;
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _mixPlayer = AudioPlayer();
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    final focus = ref.read(appStateProvider).store.settings.focus;
    if (focus.sceneId != null && focus.sceneId != 'none') {
      _scene = focus.sceneId!;
    }
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (_breathOn) _breath.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playMain();
      _playMix();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _mixPlayer.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _toggleBreath() {
    setState(() {
      _breathOn = !_breathOn;
      if (_breathOn) {
        _breath.repeat(reverse: true);
      } else {
        _breath.stop();
        _breath.value = 0;
      }
    });
  }

  void _selectPreset(String key, int seconds) {
    setState(() {
      _preset = key;
      _total = seconds;
      _remaining = seconds;
      _running = false;
      _done = false;
    });
    _timer?.cancel();
    if (seconds == 0) _startFree();
  }

  void _startFree() {
    // 自由专注：不限时，只记录开始
    setState(() {
      _running = true;
      _done = false;
    });
  }

  void _toggle() {
    if (_preset == 'free') {
      setState(() => _running = !_running);
      return;
    }
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_remaining > 0) {
            _remaining--;
          }
          if (_remaining == 0) {
            _timer?.cancel();
            _running = false;
            _finish();
          }
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _total;
      _running = false;
      _done = false;
    });
  }

  void _finish() {
    setState(() => _done = true);
    final state = ref.read(appStateProvider);
    state.store.addFocusSession({
      'taskId': widget.task?.id,
      'taskTitle': widget.task?.title ?? '自由专注',
      'durationSec': _total,
      'pomodoros': 1,
      'soundScene': _scene,
    });
    state.notify();
    _player.stop();
    _mixPlayer.stop();
    showSugarToast(context, '🎉 专注完成，太棒啦！');
  }

  Future<void> _selectScene(String scene) async {
    setState(() => _scene = scene);
    _saveFocus({'sceneId': scene == 'none' ? null : scene});
    await _playMain();
  }

  void _saveFocus(Map<String, dynamic> patch) {
    final cur = ref.read(appStateProvider).store.settings.focus;
    final next = cur.copyWith(
      sceneId: patch.containsKey('sceneId')
          ? patch['sceneId'] as String?
          : null,
      volume: patch['volume'] as double?,
      mixSceneId: patch.containsKey('mixSceneId')
          ? patch['mixSceneId'] as String?
          : null,
      mixVolume: patch['mixVolume'] as double?,
      customAudio: patch['customAudio'] as CustomAudio?,
      clearScene: patch['clearScene'] == true,
      clearMix: patch['clearMix'] == true,
      clearCustom: patch['clearCustom'] == true,
    );
    ref.read(appStateProvider).store.updateSettings({'focus': next.toJson()});
    ref.read(appStateProvider).notify();
  }

  Future<void> _playMain() async {
    final focus = ref.read(appStateProvider).store.settings.focus;
    final id = focus.sceneId ?? _scene;
    if (id == 'none' || id.isEmpty) {
      await _player.stop();
      return;
    }
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(focus.volume);
      if (id == 'custom') {
        final ca = focus.customAudio;
        if (ca != null) {
          await _player.play(BytesSource(_audioBytes(ca.dataUrl)));
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = await generateSoundFile(id, dir);
        await _player.play(DeviceFileSource(file.path));
      }
    } catch (_) {
      if (!mounted) return;
      showSugarToast(context, '音频播放暂不可用，已静音');
    }
  }

  Future<void> _playMix() async {
    final focus = ref.read(appStateProvider).store.settings.focus;
    final id = focus.mixSceneId;
    if (id == null || id.isEmpty) {
      await _mixPlayer.stop();
      return;
    }
    try {
      await _mixPlayer.stop();
      await _mixPlayer.setReleaseMode(ReleaseMode.loop);
      await _mixPlayer.setVolume(focus.mixVolume);
      if (id == 'custom') {
        final ca = focus.customAudio;
        if (ca != null) {
          await _mixPlayer.play(BytesSource(_audioBytes(ca.dataUrl)));
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = await generateSoundFile(id, dir);
        await _mixPlayer.play(DeviceFileSource(file.path));
      }
    } catch (_) {
      await _mixPlayer.stop();
    }
  }

  static Uint8List _audioBytes(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    return comma < 0
        ? Uint8List(0)
        : base64Decode(dataUrl.substring(comma + 1));
  }

  Future<void> _uploadCustomAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.single;
    if (f.size > 2 * 1024 * 1024) {
      showSugarToast(context, '音频需 ≤2MB');
      return;
    }
    var bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      showSugarToast(context, '读取音频失败');
      return;
    }
    final ca = CustomAudio(
      name: f.name,
      dataUrl: 'data:${_guessMime(f.name)};base64,${base64Encode(bytes)}',
    );
    _saveFocus({'customAudio': ca});
    if (!mounted) return;
    showSugarToast(context, '自定义声音已添加');
    await _playMain();
  }

  static String _guessMime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.mp3')) return 'audio/mpeg';
    if (n.endsWith('.wav')) return 'audio/wav';
    if (n.endsWith('.m4a') || n.endsWith('.aac')) return 'audio/mp4';
    if (n.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mpeg';
  }

  void _setVolume(double v, {required bool mix}) {
    _saveFocus({mix ? 'mixVolume' : 'volume': v});
    if (mix) {
      _mixPlayer.setVolume(v);
    } else {
      _player.setVolume(v);
    }
  }

  void _setMix(String id) {
    _saveFocus({'mixSceneId': id.isEmpty ? null : id});
    _playMix();
  }

  void _removeCustom() {
    _saveFocus({'clearCustom': true});
    showSugarToast(context, '自定义声音已删除');
    _playMain();
    _playMix();
  }

  Widget _mixChip(
    BuildContext context,
    String label,
    String id,
    SugarThemeData t,
  ) {
    final focus = ref.read(appStateProvider).store.settings.focus;
    final active = focus.mixSceneId == (id.isEmpty ? null : id);
    return PressableScale(
      onTap: () => _setMix(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? t.lavenderSoft : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? t.lavender : t.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? t.lavenderStrong : t.text2,
          ),
        ),
      ),
    );
  }

  String get _timeText {
    if (_preset == 'free') return '∞';
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_total == 0) return 0;
    return (_total - _remaining) / _total;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final todaySec = state.store.focusSessions
        .where((s) {
          final now = DateTime.now();
          return s.startedAt.year == now.year &&
              s.startedAt.month == now.month &&
              s.startedAt.day == now.day;
        })
        .fold<int>(0, (sum, s) => sum + s.durationSec);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // 呼吸引导光晕
            if (_breathOn)
              AnimatedBuilder(
              animation: _breath,
              builder: (context, _) {
                final v = _breath.value;
                return Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 220 + 90 * v,
                      height: 220 + 90 * v,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.pinkSoft.withValues(alpha: 0.35 + 0.2 * (1 - v)),
                      ),
                    ),
                  ),
                );
              },
              ),
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Row(
                  children: [
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: t.border),
                        ),
                        child: SugarIcon('close', size: 17, color: t.text2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '专注',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: t.text,
                            ),
                          ),
                          Text(
                            '今日已专注 ${todaySec ~/ 60} 分钟',
                            style: TextStyle(fontSize: 11, color: t.text3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Center(
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surface,
                      border: Border.all(color: t.border),
                      boxShadow: [
                        BoxShadow(
                          color: t.pinkStrong.withValues(alpha: 0.12),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 210,
                          height: 210,
                          child: CustomPaint(
                            painter: _FocusRingPainter(
                              progress: _progress,
                              theme: t,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeText,
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.task?.title ?? '自由专注',
                              style: TextStyle(fontSize: 12, color: t.text2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 预设
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _presets.map((p) {
                    final active = _preset == p.$1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: PressableScale(
                        onTap: () => _selectPreset(p.$1, p.$3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active ? t.pinkStrong : t.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? t.pinkStrong : t.border,
                            ),
                          ),
                          child: Text(
                            p.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : t.text2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // 控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PressableScale(
                      onTap: _reset,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: t.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.border),
                        ),
                        child: SugarIcon('undo', size: 20, color: t.text2),
                      ),
                    ),
                    const SizedBox(width: 22),
                    PressableScale(
                      onTap: _toggle,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: t.pinkStrong,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: t.pinkStrong.withValues(alpha: 0.4),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: SugarIcon(
                          _running ? 'close' : 'bolt',
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                    PressableScale(
                      onTap: () => _done
                          ? _finish()
                          : showSugarToast(context, '点击下方场景选择白噪音'),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: t.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.border),
                        ),
                        child: SugarIcon('check', size: 20, color: t.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '专注场景（白噪音）',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: t.text2,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '呼吸引导',
                        style: TextStyle(fontSize: 12, color: t.text2),
                      ),
                    ),
                    SugarSwitch(
                      value: _breathOn,
                      onChanged: (_) => _toggleBreath(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...kSoundScenes.map((sc) {
                      final active = _scene == sc.$1;
                      return PressableScale(
                        onTap: () => _selectScene(sc.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active ? t.pinkSoft : t.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: active ? t.pink : t.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SugarIcon(
                                sc.$3,
                                size: 13,
                                color: active ? t.pinkStrong : t.text2,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sc.$2,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: active ? t.pinkStrong : t.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (state.store.settings.focus.customAudio != null)
                      PressableScale(
                        onTap: () => _selectScene('custom'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _scene == 'custom' ? t.pinkSoft : t.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _scene == 'custom' ? t.pink : t.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SugarIcon(
                                'sparkles',
                                size: 13,
                                color: _scene == 'custom'
                                    ? t.pinkStrong
                                    : t.text2,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '自定义声音',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _scene == 'custom'
                                      ? t.pinkStrong
                                      : t.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // 主场景音量（v0.18.0 双音轨混音）
                Row(
                  children: [
                    SugarIcon('bell', size: 14, color: t.pinkStrong),
                    const SizedBox(width: 6),
                    Text(
                      '主场景音量',
                      style: TextStyle(fontSize: 12, color: t.text2),
                    ),
                    Expanded(
                      child: Slider(
                        value: state.store.settings.focus.volume,
                        onChanged: (v) => _setVolume(v, mix: false),
                      ),
                    ),
                    Text(
                      '${(state.store.settings.focus.volume * 100).round()}%',
                      style: TextStyle(fontSize: 11, color: t.text3),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 叠加场景（Noisli 式混音）
                Text(
                  '叠加声音（可选）',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.text2),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _mixChip(context, '无', '', t),
                    ...kSoundScenes
                        .where((sc) => sc.$1 != 'none')
                        .map((sc) => _mixChip(context, sc.$2, sc.$1, t)),
                    if (state.store.settings.focus.customAudio != null)
                      _mixChip(context, '自定义声音', 'custom', t),
                  ],
                ),
                if (state.store.settings.focus.mixSceneId != null &&
                    state.store.settings.focus.mixSceneId!.isNotEmpty) ...[
                  Row(
                    children: [
                      SugarIcon('bell', size: 14, color: t.lavenderStrong),
                      const SizedBox(width: 6),
                      Text(
                        '叠加音量',
                        style: TextStyle(fontSize: 12, color: t.text2),
                      ),
                      Expanded(
                        child: Slider(
                          value: state.store.settings.focus.mixVolume,
                          onChanged: (v) => _setVolume(v, mix: true),
                        ),
                      ),
                      Text(
                        '${(state.store.settings.focus.mixVolume * 100).round()}%',
                        style: TextStyle(fontSize: 11, color: t.text3),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                // 自定义声音上传 / 删除（v0.18.0）
                if (state.store.settings.focus.customAudio == null)
                  SugarButton(
                    label: '上传自定义声音（≤2MB）',
                    iconName: 'upload',
                    compact: true,
                    onTap: _uploadCustomAudio,
                  )
                else
                  Row(
                    children: [
                      SugarIcon('sparkles', size: 14, color: t.pinkStrong),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          state.store.settings.focus.customAudio!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.text2),
                        ),
                      ),
                      SugarButton(
                        label: '更换',
                        compact: true,
                        onTap: _uploadCustomAudio,
                      ),
                      const SizedBox(width: 6),
                      SugarButton(
                        label: '删除',
                        compact: true,
                        danger: true,
                        onTap: _removeCustom,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  final SugarThemeData theme;

  _FocusRingPainter({required this.progress, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = theme.surface3,
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFFE292B4), Color(0xFF5FB894)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter old) =>
      old.progress != progress;
}
