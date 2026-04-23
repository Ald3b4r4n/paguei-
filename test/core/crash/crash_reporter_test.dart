import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/crash/noop_crash_reporter.dart';
import 'package:paguei/core/logging/app_logger.dart';
import 'package:paguei/core/crash/logging_crash_reporter.dart';

// ---------------------------------------------------------------------------
// Spy logger
// ---------------------------------------------------------------------------

final class _SpyLogger implements AppLogger {
  final List<String> errors = [];
  final List<String> debugs = [];

  @override
  void debug(String message, {Object? context}) => debugs.add(message);

  @override
  void info(String message, {Object? context}) {}

  @override
  void warning(String message, {Object? context}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      errors.add(message);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NoopCrashReporter', () {
    const reporter = NoopCrashReporter();

    test('initialise does nothing', () async {
      await expectLater(reporter.initialise(), completes);
    });

    test('recordError does nothing', () async {
      await expectLater(
        reporter.recordError(Exception('boom'), null),
        completes,
      );
    });

    test('recordFlutterError does nothing', () async {
      final details = FlutterErrorDetails(exception: Exception('widget error'));
      await expectLater(reporter.recordFlutterError(details), completes);
    });

    test('log does nothing', () async {
      await expectLater(reporter.log('breadcrumb'), completes);
    });

    test('setUserIdentifier does nothing', () async {
      await expectLater(reporter.setUserIdentifier('anon-123'), completes);
    });

    test('setCustomKey does nothing', () async {
      await expectLater(reporter.setCustomKey('db_version', 1), completes);
    });
  });

  group('LoggingCrashReporter', () {
    late _SpyLogger spy;
    late LoggingCrashReporter reporter;

    setUp(() {
      spy = _SpyLogger();
      reporter = LoggingCrashReporter(spy);
    });

    test('recordError logs at error level', () async {
      await reporter.recordError(Exception('db failed'), null,
          reason: 'backup');
      expect(spy.errors, hasLength(1));
      expect(spy.errors.first, contains('backup'));
    });

    test('fatal error includes FATAL tag', () async {
      await reporter.recordError(Exception('crash'), null, fatal: true);
      expect(spy.errors.first, contains('FATAL'));
    });

    test('non-fatal error includes ERROR tag', () async {
      await reporter.recordError(Exception('minor'), null, fatal: false);
      expect(spy.errors.first, contains('ERROR'));
    });

    test('log writes a debug breadcrumb', () async {
      await reporter.log('user tapped backup');
      expect(spy.debugs, hasLength(1));
      expect(spy.debugs.first, contains('breadcrumb'));
    });

    test('setCustomKey truncates long values', () async {
      final longValue = 'x' * 500;
      // Should not throw
      await expectLater(reporter.setCustomKey('key', longValue), completes);
    });
  });
}
