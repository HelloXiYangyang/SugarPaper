/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sugarpaper/data/legal_store.dart';

void main() {
  test('LegalStore：默认未同意，agree 后持久化且重新加载仍为已同意', () async {
    final dir = await Directory.systemTemp.createTemp('sugar_legal_test');
    try {
      final store = LegalStore()..overrideDir = dir;
      await store.load();
      expect(store.isAgreed, isFalse);

      await store.agree();
      expect(store.isAgreed, isTrue);

      final reloaded = LegalStore()..overrideDir = dir;
      await reloaded.load();
      expect(reloaded.isAgreed, isTrue);
      expect(reloaded.agreedVersion, LegalStore.legalVersion);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
