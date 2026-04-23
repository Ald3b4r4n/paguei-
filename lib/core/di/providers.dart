import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import '../crash/crash_reporter.dart';
import '../crash/logging_crash_reporter.dart';
import '../crash/noop_crash_reporter.dart';
import '../logging/app_logger.dart';
import '../logging/buffered_logger.dart';
import 'app_environment.dart';

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => throw UnimplementedError('Override in main'),
  name: 'appEnvironmentProvider',
);

/// Singleton [BufferedLogger] shared between [appLoggerProvider] and the
/// diagnostics screen.  Retains the last 100 sanitised log lines in memory.
final bufferedLoggerProvider = Provider<BufferedLogger>(
  (ref) {
    final env = ref.watch(appEnvironmentProvider);
    final level = switch (env.logLevel) {
      'debug' => LogLevel.debug,
      'info' => LogLevel.info,
      'warning' => LogLevel.warning,
      _ => LogLevel.error,
    };
    return BufferedLogger(minimumLevel: level);
  },
  name: 'bufferedLoggerProvider',
);

final appLoggerProvider = Provider<AppLogger>(
  (ref) => ref.watch(bufferedLoggerProvider),
  name: 'appLoggerProvider',
);

/// Provides the active [CrashReporter] for the current environment.
///
/// - development / consent denied → [NoopCrashReporter]
/// - staging / production          → [LoggingCrashReporter]
///   (swap for `FirebaseCrashlyticsCrashReporter` once the package is added)
final crashReporterProvider = Provider<CrashReporter>(
  (ref) {
    final env = ref.watch(appEnvironmentProvider);
    if (!env.enableCrashReporting) return const NoopCrashReporter();
    return LoggingCrashReporter(ref.watch(appLoggerProvider));
  },
  name: 'crashReporterProvider',
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Override in main with real database'),
  name: 'appDatabaseProvider',
);

Future<AppDatabase> buildDatabase(AppEnvironment env) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, env.databaseName);
  return AppDatabase(NativeDatabase.createInBackground(File(dbPath)));
}
