import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'analytics_consent.dart';

/// Persists [AnalyticsConsent] to encrypted device storage.
///
/// Storing consent in [FlutterSecureStorage] ensures the user's preference
/// survives app updates and cannot be silently reset by clearing app cache.
final class AnalyticsConsentRepository {
  const AnalyticsConsentRepository(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'analytics_consent_v1';

  /// Loads persisted consent; returns [AnalyticsConsent.initial] on failure.
  Future<AnalyticsConsent> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return const AnalyticsConsent.initial();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AnalyticsConsent.fromMap(map);
    } catch (_) {
      return const AnalyticsConsent.initial();
    }
  }

  /// Saves [consent] to secure storage.
  Future<void> save(AnalyticsConsent consent) async {
    await _storage.write(key: _key, value: jsonEncode(consent.toMap()));
  }

  /// Resets consent to initial state (e.g. user deletes their data).
  Future<void> reset() async {
    await _storage.delete(key: _key);
  }
}
