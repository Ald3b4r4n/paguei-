import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paguei/domain/entities/notification_preferences.dart';

/// Persists [NotificationPreferences] using [FlutterSecureStorage].
///
/// Preferences are serialised to JSON and stored under a single key.
/// All reads return the default preferences if no value has been saved yet,
/// so the app works correctly on first launch.
final class NotificationPreferencesRepository {
  const NotificationPreferencesRepository(this._storage);

  static const _key = 'notification_preferences_v1';

  final FlutterSecureStorage _storage;

  /// Loads persisted preferences, or the defaults if none exist.
  Future<NotificationPreferences> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return const NotificationPreferences();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPreferences.fromMap(map);
    } catch (_) {
      // If deserialization fails (e.g., schema migration), return defaults.
      return const NotificationPreferences();
    }
  }

  /// Persists [preferences].
  Future<void> save(NotificationPreferences preferences) async {
    final json = jsonEncode(preferences.toMap());
    await _storage.write(key: _key, value: json);
  }

  /// Resets to factory defaults.
  Future<void> reset() async {
    await _storage.delete(key: _key);
  }
}
