import 'package:flutter/foundation.dart';
import 'package:paguei/core/logging/app_logger.dart';
import 'crash_reporter.dart';

/// Crash reporter that writes to [AppLogger] instead of a remote backend.
///
/// Suitable for **staging** and local QA: every crash/error becomes a
/// console log line that CI or a tester can inspect without needing
/// Firebase or Sentry credentials.
final class LoggingCrashReporter implements CrashReporter {
  const LoggingCrashReporter(this._logger);

  final AppLogger _logger;

  @override
  Future<void> initialise() async {
    _logger.info('[CrashReporter] LoggingCrashReporter initialised.');
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final tag = fatal ? 'FATAL' : 'ERROR';
    _logger.error(
      '[CrashReporter] $tag${reason != null ? ' ($reason)' : ''}: $exception',
      error: exception,
      stackTrace: stack,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    _logger.error(
      '[CrashReporter] FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  }

  @override
  Future<void> log(String message) async {
    _logger.debug('[CrashReporter] breadcrumb: $message');
  }

  @override
  Future<void> setUserIdentifier(String id) async {
    _logger.debug('[CrashReporter] userIdentifier: $id');
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    _logger.debug(
        '[CrashReporter] customKey $key=${value.toString().substring(0, value.toString().length.clamp(0, 120))}');
  }
}
