/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/// 无服务器账号（v0.16.0，与网页版 store.js account 结构一致）。
class Account {
  final String pubkey; // b64url 公钥（账号 ID）
  final String seedB64; // b64url 种子（仅存本机）
  final String? mnemonic; // 助记词（创建时展示，恢复后不持久化）
  final String displayName;
  final int version;
  final String? lastSyncAt;
  final List<Map<String, dynamic>> devices;

  const Account({
    required this.pubkey,
    required this.seedB64,
    this.mnemonic,
    this.displayName = '我的设备',
    this.version = 0,
    this.lastSyncAt,
    this.devices = const [],
  });

  Account copyWith({
    String? pubkey,
    String? seedB64,
    String? mnemonic,
    String? displayName,
    int? version,
    String? lastSyncAt,
    List<Map<String, dynamic>>? devices,
  }) {
    return Account(
      pubkey: pubkey ?? this.pubkey,
      seedB64: seedB64 ?? this.seedB64,
      mnemonic: mnemonic ?? this.mnemonic,
      displayName: displayName ?? this.displayName,
      version: version ?? this.version,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      devices: devices ?? this.devices,
    );
  }

  Map<String, dynamic> toJson() => {
        'pubkey': pubkey,
        'seedB64': seedB64,
        'mnemonic': mnemonic,
        'displayName': displayName,
        'version': version,
        'lastSyncAt': lastSyncAt,
        'devices': devices,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        pubkey: (json['pubkey'] as String?) ?? '',
        seedB64: (json['seedB64'] as String?) ?? '',
        mnemonic: json['mnemonic'] as String?,
        displayName: (json['displayName'] as String?) ?? '我的设备',
        version: (json['version'] as num?)?.toInt() ?? 0,
        lastSyncAt: json['lastSyncAt'] as String?,
        devices: (json['devices'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
      );
}
