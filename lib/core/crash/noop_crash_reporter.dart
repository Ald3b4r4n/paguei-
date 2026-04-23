import 'package:flutter/foundation.dart';
import 'crash_reporter.dart';

/// No-op crash reporter.
///
/// Used when:
/// - [AppEnvironment.enableCrashReporting] is false (development).
/// - The user has opted out of analytics / crash data collection.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> initialise() async {}

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setUserIdentifier(String id) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}
