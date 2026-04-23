import 'package:flutter/foundation.dart';

/// Abstraction over any crash reporting backend.
///
/// Swap implementations at startup via the DI layer:
/// - [NoopCrashReporter]   — dev / when user has denied consent
/// - [LoggingCrashReporter] — staging (logs to console)
/// - `FirebaseCrashlyticsCrashReporter` — production (add when
///   `firebase_crashlytics` package is included in pubspec.yaml)
///
/// ## Adding Firebase Crashlytics
///
/// 1. Add to pubspec.yaml:
///    ```yaml
///    firebase_crashlytics: ^3.0.0
///    firebase_core: ^3.0.0
///    ```
///
/// 2. Create `lib/core/crash/crashlytics_crash_reporter.dart`:
///    ```dart
///    import 'package:firebase_crashlytics/firebase_crashlytics.dart';
///    import 'crash_reporter.dart';
///
///    final class FirebaseCrashlyticsCrashReporter implements CrashReporter {
///      const FirebaseCrashlyticsCrashReporter(this._crashlytics);
///      final FirebaseCrashlytics _crashlytics;
///
///      @override
///      Future<void> initialise() =>
///          _crashlytics.setCrashlyticsCollectionEnabled(true);
///
///      @override
///      Future<void> recordError(dynamic exception, StackTrace? stack,
///              {String? reason, bool fatal = false}) =>
///          _crashlytics.recordError(exception, stack,
///              reason: reason, fatal: fatal);
///
///      @override
///      Future<void> recordFlutterError(FlutterErrorDetails details) =>
///          _crashlytics.recordFlutterFatalError(details);
///
///      @override
///      Future<void> log(String message) => _crashlytics.log(message);
///
///      @override
///      Future<void> setUserIdentifier(String id) =>
///          _crashlytics.setUserIdentifier(id);
///
///      @override
///      Future<void> setCustomKey(String key, Object value) =>
///          _crashlytics.setCustomKey(key, value.toString());
///    }
///    ```
///
/// 3. Wire in `_bootstrap()` inside `main.dart`:
///    ```dart
///    await Firebase.initializeApp();
///    final reporter = FirebaseCrashlyticsCrashReporter(
///        FirebaseCrashlytics.instance);
///    ```
///
/// ## Adding Sentry
///
/// 1. Add `sentry_flutter: ^8.0.0` to pubspec.yaml.
/// 2. Create `SentryCrashReporter implements CrashReporter` following the
///    same interface.  The [initialise] method calls `SentryFlutter.init`.
abstract interface class CrashReporter {
  /// Called once at startup to configure the backend.
  Future<void> initialise();

  /// Records a Dart exception. Set [fatal] = true for unrecovered errors.
  ///
  /// **Privacy rule**: never pass PII (names, CPFs, amounts) as [reason].
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Records a Flutter framework error (connect to [FlutterError.onError]).
  Future<void> recordFlutterError(FlutterErrorDetails details);

  /// Appends a breadcrumb log message (max 64 KB per session).
  Future<void> log(String message);

  /// Sets an anonymous device/session identifier — NOT user PII.
  Future<void> setUserIdentifier(String id);

  /// Attaches arbitrary metadata (e.g. `{'db_version': 1}`).
  /// Values are truncated to 1 024 characters.
  Future<void> setCustomKey(String key, Object value);
}
