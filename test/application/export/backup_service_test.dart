import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/export/backup_service.dart';

void main() {
  group('BackupManifest', () {
    test('serialises and deserialises round-trip correctly', () {
      final original = BackupManifest(
        backupVersion: BackupService.currentBackupVersion,
        exportedAt: DateTime.utc(2026, 4, 20, 10, 0),
        appVersion: '1.0.0',
        counts: const BackupCounts(
          accounts: 3,
          transactions: 120,
          bills: 14,
          debts: 2,
          funds: 4,
          categories: 14,
        ),
        isEncrypted: false,
      );

      final json = original.toJson();
      final restored = BackupManifest.fromJson(json);

      expect(restored.backupVersion, original.backupVersion);
      expect(restored.exportedAt.millisecondsSinceEpoch,
          original.exportedAt.millisecondsSinceEpoch);
      expect(restored.counts.transactions, 120);
      expect(restored.isEncrypted, false);
    });

    test('fromJson handles unknown fields gracefully', () {
      final json = {
        'backupVersion': 1,
        'exportedAt': '2026-04-20T10:00:00.000Z',
        'appVersion': '1.0.0',
        'counts': {
          'accounts': 1,
          'transactions': 5,
          'bills': 0,
          'debts': 0,
          'funds': 0,
          'categories': 14
        },
        'isEncrypted': false,
        'unknownFutureField': 'some value', // forward compat
      };
      expect(() => BackupManifest.fromJson(json), returnsNormally);
    });
  });

  group('BackupService.buildPayload / parsePayload', () {
    final sampleData = {
      'accounts': [
        {
          'id': 'a1',
          'name': 'Conta Principal',
          'type': 'checking',
          'currentBalance': 1500.0
        },
      ],
      'categories': <Map<String, dynamic>>[],
      'transactions': [
        {
          'id': 't1',
          'accountId': 'a1',
          'type': 'income',
          'amount': 3000.0,
          'description': 'Salário',
          'date': '2026-04-05T00:00:00.000Z'
        },
      ],
      'bills': <Map<String, dynamic>>[],
      'funds': <Map<String, dynamic>>[],
      'debts': <Map<String, dynamic>>[],
    };

    // ── Round-trip without password ────────────────────────────────────────

    test('round-trip without password preserves all data', () {
      final encoded = BackupService.buildPayload(sampleData, password: null);
      expect(encoded, isNotEmpty);

      final decoded = BackupService.parsePayload(encoded, password: null);
      expect(decoded['accounts'], isA<List<dynamic>>());
      expect((decoded['accounts'] as List<dynamic>).length, 1);
      expect((decoded['transactions'] as List<dynamic>).length, 1);
    });

    test('encoded payload is valid gzip+base64', () {
      final encoded = BackupService.buildPayload(sampleData, password: null);
      // Should be decodable as base64
      expect(() => base64.decode(encoded), returnsNormally);
      // Decoded should be valid gzip
      final compressed = base64.decode(encoded);
      expect(
        () => GZipCodec().decode(compressed),
        returnsNormally,
      );
    });

    // ── Round-trip with password ───────────────────────────────────────────

    test('round-trip with password decrypts to original data', () {
      const password = 'MinhaS3nha!';
      final encoded =
          BackupService.buildPayload(sampleData, password: password);
      final decoded = BackupService.parsePayload(encoded, password: password);

      expect((decoded['accounts'] as List).length, 1);
    });

    test('wrong password throws BackupDecryptionException', () {
      const password = 'CorretaSenha';
      final encoded =
          BackupService.buildPayload(sampleData, password: password);

      expect(
        () => BackupService.parsePayload(encoded, password: 'SenhaErrada'),
        throwsA(isA<BackupDecryptionException>()),
      );
    });

    test('null password cannot parse password-encrypted payload', () {
      final encoded =
          BackupService.buildPayload(sampleData, password: 'segredo');
      expect(
        () => BackupService.parsePayload(encoded, password: null),
        throwsA(isA<BackupDecryptionException>()),
      );
    });
  });

  group('BackupService.versionCheck', () {
    test('same version passes', () {
      expect(
        BackupService.versionCheck(BackupService.currentBackupVersion),
        isTrue,
      );
    });

    test('older version passes (backwards compatible)', () {
      // version 0 (hypothetical past) should still be accepted
      expect(BackupService.versionCheck(0), isTrue);
    });

    test('version far in the future fails', () {
      // A backup from version 100 (way ahead) should be rejected
      expect(BackupService.versionCheck(100), isFalse);
    });
  });

  group('RestorePreview', () {
    test('counts are computed correctly', () {
      final data = {
        'accounts': List.generate(3, (i) => {'id': 'a$i'}),
        'transactions': List.generate(50, (i) => {'id': 't$i'}),
        'bills': List.generate(7, (i) => {'id': 'b$i'}),
        'funds': List.generate(2, (i) => {'id': 'f$i'}),
        'debts': List.generate(1, (i) => {'id': 'd$i'}),
        'categories': List.generate(14, (i) => {'id': 'c$i'}),
      };

      final preview = RestorePreview.fromData(data);
      expect(preview.accountCount, 3);
      expect(preview.transactionCount, 50);
      expect(preview.billCount, 7);
      expect(preview.fundCount, 2);
      expect(preview.debtCount, 1);
    });

    test('handles missing keys without throwing', () {
      final data = <String, dynamic>{'accounts': <dynamic>[]};
      final preview = RestorePreview.fromData(data);
      expect(preview.transactionCount, 0);
      expect(preview.billCount, 0);
    });
  });
}
