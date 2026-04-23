import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paguei/core/analytics/analytics_consent.dart';
import 'package:paguei/core/analytics/analytics_consent_repository.dart';

// ---------------------------------------------------------------------------
// Fake secure storage for unit tests
// ---------------------------------------------------------------------------

final class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey(
          {required String key,
          AppleOptions? iOptions,
          AndroidOptions? aOptions,
          LinuxOptions? lOptions,
          WebOptions? webOptions,
          AppleOptions? mOptions,
          WindowsOptions? wOptions}) async =>
      _store.containsKey(key);
  @override
  Future<void> deleteAll(
          {AppleOptions? iOptions,
          AndroidOptions? aOptions,
          LinuxOptions? lOptions,
          WebOptions? webOptions,
          AppleOptions? mOptions,
          WindowsOptions? wOptions}) async =>
      _store.clear();
  @override
  Future<Map<String, String>> readAll(
          {AppleOptions? iOptions,
          AndroidOptions? aOptions,
          LinuxOptions? lOptions,
          WebOptions? webOptions,
          AppleOptions? mOptions,
          WindowsOptions? wOptions}) async =>
      Map.unmodifiable(_store);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AnalyticsConsent model', () {
    test('initial state: not asked, not granted', () {
      const c = AnalyticsConsent.initial();
      expect(c.hasBeenAsked, isFalse);
      expect(c.isGranted, isFalse);
      expect(c.grantedAt, isNull);
    });

    test('toMap / fromMap roundtrip', () {
      final original = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
        grantedAt: DateTime.utc(2026, 4, 20, 10, 0),
      );
      final map = original.toMap();
      final restored = AnalyticsConsent.fromMap(map);

      expect(restored.hasBeenAsked, true);
      expect(restored.isGranted, true);
      expect(
        restored.grantedAt?.millisecondsSinceEpoch,
        original.grantedAt?.millisecondsSinceEpoch,
      );
    });

    test('fromMap handles missing fields gracefully', () {
      final c = AnalyticsConsent.fromMap({});
      expect(c.hasBeenAsked, isFalse);
      expect(c.isGranted, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const c = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: false,
        grantedAt: null,
      );
      final updated = c.copyWith(isGranted: true);
      expect(updated.hasBeenAsked, true);
      expect(updated.isGranted, true);
    });

    test('equality ignores grantedAt', () {
      final a = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
        grantedAt: DateTime.utc(2026, 1, 1),
      );
      final b = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
        grantedAt: DateTime.utc(2026, 6, 6),
      );
      expect(a, equals(b));
    });
  });

  group('AnalyticsConsentRepository — consent persistence', () {
    late _FakeSecureStorage storage;
    late AnalyticsConsentRepository repo;

    setUp(() {
      storage = _FakeSecureStorage();
      repo = AnalyticsConsentRepository(storage);
    });

    test('load returns initial when nothing stored', () async {
      final consent = await repo.load();
      expect(consent.hasBeenAsked, isFalse);
      expect(consent.isGranted, isFalse);
    });

    test('save then load roundtrips correctly', () async {
      final granted = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
        grantedAt: DateTime.utc(2026, 4, 20),
      );
      await repo.save(granted);
      final loaded = await repo.load();

      expect(loaded.hasBeenAsked, true);
      expect(loaded.isGranted, true);
    });

    test('deny persists isGranted = false', () async {
      // First grant
      await repo.save(const AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
      ));

      // Then deny
      await repo.save(const AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: false,
      ));

      final loaded = await repo.load();
      expect(loaded.isGranted, isFalse);
      expect(loaded.hasBeenAsked, isTrue);
    });

    test('reset returns to initial state', () async {
      await repo.save(const AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
      ));

      await repo.reset();
      final loaded = await repo.load();

      expect(loaded.hasBeenAsked, isFalse);
      expect(loaded.isGranted, isFalse);
    });

    test('load handles corrupted storage gracefully', () async {
      // Write invalid JSON directly
      await storage.write(key: 'analytics_consent_v1', value: 'INVALID_JSON');

      final consent = await repo.load();
      expect(consent, equals(const AnalyticsConsent.initial()));
    });

    test('consent is stored as valid JSON', () async {
      final consent = AnalyticsConsent(
        hasBeenAsked: true,
        isGranted: true,
        grantedAt: DateTime.utc(2026, 4, 20),
      );
      await repo.save(consent);

      final raw = await storage.read(key: 'analytics_consent_v1');
      expect(() => jsonDecode(raw!), returnsNormally);
    });
  });
}
