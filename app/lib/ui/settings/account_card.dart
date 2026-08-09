/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../data/account_service.dart';
import '../../data/app_state.dart';
import '../../data/direct_sync_service.dart';
import '../../data/sync_service.dart';
import '../../models/account.dart';
import '../home/dialogs.dart';
import '../widgets/basic.dart';
import '../widgets/sugar_switch.dart';

/// 账号与同步卡片（v0.16.0 对齐网页版 ui-account.js）。
class AccountCard extends ConsumerStatefulWidget {
  const AccountCard({super.key});

  @override
  ConsumerState<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<AccountCard> {
  final SyncService _sync = SyncService();
  final DirectSyncService _direct = DirectSyncService();
  bool _syncing = false;

  Future<void> _createAccount() async {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    showSugarDialog(
      context,
      barrierDismissible: false,
      builder: (ctx) => SugarDialogBox(
        child: FutureBuilder(
          future: AccountService.createAccount(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final acc = snap.data!;
            final words = acc.mnemonic.join(' ');
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '你的 12 词助记词',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '助记词即账号身份，请抄写并妥善保管。'
                    '丢失后无法恢复数据；任何人拿到助记词即可解密你的数据。',
                    style: TextStyle(fontSize: 11.5, color: t.dangerStrong),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      words,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SugarButton(
                        label: '复制',
                        iconName: 'save',
                        compact: true,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: words));
                          showSugarToast(context, '助记词已复制');
                        },
                      ),
                      const Spacer(),
                      SugarButton(
                        label: '我已备份，创建账号',
                        iconName: 'check',
                        primary: true,
                        compact: true,
                        onTap: () async {
                          final pubkey =
                              await AccountService.publicKeyB64(acc.keyPair);
                          ref.read(appStateProvider).store.setAccount(
                                Account(
                                  pubkey: pubkey,
                                  seedB64: _b64url(acc.seed),
                                  mnemonic: words,
                                  displayName: ref
                                      .read(appStateProvider)
                                      .store
                                      .settings
                                      .deviceName,
                                ),
                              );
                          ref.read(appStateProvider).notify();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _restoreAccount() async {
    final state = ref.read(appStateProvider);
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final controller = TextEditingController();
    showSugarDialog(
      context,
      builder: (ctx) => SugarDialogBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '恢复账号',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '12 词助记词（空格分隔）',
                  hintText: 'bub zeb ral …',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SugarButton(
                    label: '取消',
                    onTap: () => Navigator.pop(ctx),
                  ),
                  const SizedBox(width: 8),
                  SugarButton(
                    label: '恢复',
                    iconName: 'undo',
                    primary: true,
                    onTap: () async {
                      try {
                        final restored = await AccountService.restoreAccount(
                          controller.text,
                        );
                        final pubkey = await AccountService.publicKeyB64(
                          restored.keyPair,
                        );
                        state.store.setAccount(
                          Account(
                            pubkey: pubkey,
                            seedB64: _b64url(restored.seed),
                            displayName: state.store.settings.deviceName,
                          ),
                        );
                        state.notify();
                        if (ctx.mounted) Navigator.pop(ctx);
                        showSugarToast(context, '账号已恢复，可开始同步');
                      } catch (e) {
                        showSugarToast(context, '恢复失败：${e.toString()}');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    final state = ref.read(appStateProvider);
    setState(() => _syncing = true);
    await _sync.syncOnce(state.store, onDone: () {
      if (mounted) {
        setState(() => _syncing = false);
        state.notify();
      }
    });
  }

  void _deleteAccount(BuildContext context) {
    final state = ref.read(appStateProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除本地账号'),
        content: const Text('将删除本机账号身份与同步配置，本地任务数据保留。'
            '请确保助记词已备份，否则无法再恢复此账号。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              state.store.clearAccount();
              state.notify();
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _directStart() {
    final state = ref.read(appStateProvider);
    _direct.start(state.store, onChanged: () {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _directStop() {
    _direct.stop();
    setState(() {});
  }

  void _editRelays(BuildContext context) {
    final state = ref.read(appStateProvider);
    final controller = TextEditingController(
      text: (state.store.settings.relays.isNotEmpty
              ? state.store.settings.relays
              : SyncService.defaultRelays)
          .join('\n'),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nostr 中继配置'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '中继地址（每行一个 wss://）',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final relays = controller.text
                  .split(RegExp(r'[\n,;]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              state.store.updateSettings({'relays': relays});
              state.notify();
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static String _b64url(List<int> bytes) => base64UrlEncode(bytes)
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SugarTheme>()!.data;
    final state = ref.watch(appStateProvider);
    final acc = state.store.account;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SugarIcon('globe', size: 16, color: t.iconMain),
            const SizedBox(width: 8),
            Text(
              '账号与同步',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (acc == null) ...[
          Text(
            '无服务器账号：12 词助记词即身份，数据端到端加密，'
            '经 Nostr 中继跨设备同步。',
            style: TextStyle(fontSize: 11.5, height: 1.5, color: t.text3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SugarButton(
                label: '创建账号',
                iconName: 'plus',
                primary: true,
                compact: true,
                onTap: _createAccount,
              ),
              const SizedBox(width: 8),
              SugarButton(
                label: '恢复账号',
                iconName: 'undo',
                compact: true,
                onTap: _restoreAccount,
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: t.pinkSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SugarIcon('user', size: 18, color: t.iconMain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.displayName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                    Text(
                      'ID: ${AccountService.accountShortId(acc.pubkey)}',
                      style: TextStyle(fontSize: 11, color: t.text3),
                    ),
                  ],
                ),
              ),
              SugarButton(
                label: '备份助记词',
                iconName: 'save',
                compact: true,
                onTap: () {
                  final words = acc.mnemonic;
                  if (words == null) {
                    showSugarToast(context, '本机未保存助记词（恢复的账号）');
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: words));
                  showSugarToast(context, '助记词已复制，请妥善保管');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(
            t: t,
            icon: 'bolt',
            title: '同步状态',
            desc: _sync.status == 'connected'
                ? '已同步${acc.lastSyncAt != null ? ' · ${acc.lastSyncAt!.substring(0, 16).replaceAll('T', ' ')}' : ''}'
                : _sync.status == 'error'
                    ? '同步失败：${_sync.lastError}'
                    : _sync.status == 'connecting'
                        ? '正在同步…'
                        : '未同步',
            trailing: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SugarButton(
                    label: '立即同步',
                    iconName: 'bolt',
                    compact: true,
                    primary: true,
                    onTap: _syncNow,
                  ),
          ),
          _row(
            t: t,
            icon: 'bell',
            title: '自动同步',
            desc: '数据变化后自动经中继同步',
            trailing: SugarSwitch(
              value: state.store.settings.autoSync,
              onChanged: (v) {
                state.store.updateSettings({'autoSync': v});
                state.notify();
              },
            ),
          ),
          _row(
            t: t,
            icon: 'globe',
            title: 'Nostr 中继',
            desc: (state.store.settings.relays.isNotEmpty
                    ? state.store.settings.relays
                    : SyncService.defaultRelays)
                .join(' / '),
            trailing: SugarButton(
              label: '编辑',
              iconName: 'edit',
              compact: true,
              onTap: () => _editRelays(context),
            ),
          ),
          _row(
            t: t,
            icon: 'bolt',
            title: '在线直连（P2P）',
            desc: _direct.status == 'connected'
                ? '已直连${_direct.peer != null ? ' · $_directPeer' : ''} · '
                    '数据不经过中继'
                : _direct.status == 'listening'
                    ? '正在等待对方设备…（两端需同时点击「直连」）'
                    : _direct.status == 'connecting'
                        ? '正在建立 P2P 连接…'
                        : _direct.status == 'error'
                            ? '直连失败：${_direct.lastError}'
                            : '同一账号两台在线设备，数据 P2P 直传、中继仅转发信令',
            trailing: _direct.isActive
                ? SugarButton(
                    label: '停止直连',
                    iconName: 'close',
                    compact: true,
                    danger: true,
                    onTap: _directStop,
                  )
                : SugarButton(
                    label: '开始直连',
                    iconName: 'bolt',
                    compact: true,
                    primary: true,
                    onTap: _directStart,
                  ),
          ),
          const SizedBox(height: 6),
          SugarButton(
            label: '删除本地账号',
            iconName: 'trash',
            compact: true,
            danger: true,
            onTap: () => _deleteAccount(context),
          ),
        ],
      ],
    );
  }

  String get _directPeer => _direct.peer ?? '';

  Widget _row({
    required SugarThemeData t,
    required String icon,
    required String title,
    required String desc,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SugarIcon(icon, size: 14, color: t.iconMain),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: t.text3),
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
}
