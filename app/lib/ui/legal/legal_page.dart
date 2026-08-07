/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/markdown.dart';
import '../../core/theme.dart';
import '../../data/legal_store.dart';
import '../shell.dart';
import '../widgets/basic.dart';

/// 协议内容：从 assets/legal/ 加载 Markdown 并用内置渲染器展示。
class LegalContentView extends StatefulWidget {
  final String kind; // 'terms' | 'privacy'

  const LegalContentView({super.key, required this.kind});

  @override
  State<LegalContentView> createState() => _LegalContentViewState();
}

class _LegalContentViewState extends State<LegalContentView> {
  String? _md;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final md = await rootBundle
          .loadString('assets/legal/${widget.kind}.md');
      if (!mounted) return;
      setState(() {
        _md = md;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    if (_error != null) {
      return Center(
        child: Text(
          '协议加载失败，请重启应用重试',
          style: TextStyle(color: t.text2, fontSize: 13),
        ),
      );
    }
    if (_md == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: MdRender.toWidgets(
        _md!,
        text: t.text,
        text2: t.text2,
        accent: t.iconMain,
        base: const TextStyle(fontSize: 13.5),
      ),
    );
  }
}

/// 首启强制同意页：未同意前不进入应用主界面。
class LegalGatePage extends StatefulWidget {
  final LegalStore legal;

  const LegalGatePage({super.key, required this.legal});

  @override
  State<LegalGatePage> createState() => _LegalGatePageState();
}

class _LegalGatePageState extends State<LegalGatePage> {
  String _kind = 'terms';
  bool _checked = false;

  Future<void> _accept() async {
    await widget.legal.agree();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  Future<void> _decline() async {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未同意协议'),
        content: const Text('您未同意《用户协议》和《隐私政策》，无法使用本产品。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('再看看', style: TextStyle(color: t.iconMain)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '糖纸 · SugarPaper',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '欢迎使用！请阅读并同意以下协议后继续使用',
                    style: TextStyle(fontSize: 12, color: t.text2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _tab(t, 'terms', '用户协议'),
                  const SizedBox(width: 8),
                  _tab(t, 'privacy', '隐私政策'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LegalContentView(key: ValueKey(_kind), kind: _kind),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: t.surface2,
                border: Border(top: BorderSide(color: t.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _checked = !_checked),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _checked,
                            onChanged: (v) =>
                                setState(() => _checked = v ?? false),
                            activeColor: t.iconMain,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '我已阅读并同意《用户协议》和《隐私政策》',
                              style:
                                  TextStyle(fontSize: 12.5, color: t.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SugarButton(
                          label: '不同意并退出',
                          danger: true,
                          onTap: _decline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Opacity(
                          opacity: _checked ? 1 : 0.5,
                          child: SugarButton(
                            label: '同意并继续使用',
                            primary: true,
                            onTap: _checked ? _accept : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(SugarThemeData t, String kind, String label) {
    final active = _kind == kind;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _kind = kind),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? t.pinkSoft : t.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? t.pink : t.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? t.iconMain : t.text2,
            ),
          ),
        ),
      ),
    );
  }
}

/// 设置页「法律与隐私」查看页。
class LegalViewerPage extends StatelessWidget {
  final String kind; // 'terms' | 'privacy'

  const LegalViewerPage({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    final title = kind == 'privacy' ? '隐私政策' : '用户协议';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LegalContentView(kind: kind),
    );
  }
}
