/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import 'basic.dart';

/// 语音速记按钮（v0.18.0 对齐网页版 Web Speech API）：
/// 点击开始识别，再次点击停止；识别结果追加到目标文本框。
class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final VoidCallback? onStatusChanged;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onStatusChanged,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await _speech.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    if (mounted) setState(() => _available = available);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_available) {
      final ok = await _speech.initialize();
      if (!mounted) return;
      setState(() => _available = ok);
      if (!ok) return;
    }
    await _speech.listen(
      localeId: 'zh_CN',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) widget.onResult(text);
      },
    );
    if (mounted) setState(() => _listening = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return PressableScale(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _listening ? t.pinkStrong : t.surface2,
          borderRadius: BorderRadius.circular(11),
          boxShadow: _listening
              ? [
                  BoxShadow(
                    color: t.pinkStrong.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SugarIcon(
              _listening ? 'close' : 'sparkles',
              size: 16,
              color: _listening ? Colors.white : t.pinkStrong,
            ),
            if (_listening)
              Positioned(
                top: 4,
                right: 5,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
