import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/app_environment.dart';
import 'core/di/providers.dart';
import 'core/notifications/notification_initializer.dart';
import 'presentation/app.dart';

void main() => _bootstrap(AppEnvironment.production);

Future<void> _bootstrap(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await buildDatabase(env);

  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(env),
      appDatabaseProvider.overrideWithValue(database),
    ],
  );

  // ── Crash reporting ──────────────────────────────────────────────────────
  final crashReporter = container.read(crashReporterProvider);
  await crashReporter.initialise();

  // Route Flutter framework errors to the crash reporter.
  FlutterError.onError = (details) {
    FlutterError.presentError(details); // keep default dev console output
    crashReporter.recordFlutterError(details).ignore();
  };

  // Route unhandled async / platform errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    crashReporter.recordError(error, stack, fatal: true).ignore();
    return true;
  };

  // ── Notifications ────────────────────────────────────────────────────────
  // Runs in background so app startup is not blocked if permission dialog
  // is pending.
  NotificationInitializer.run(container).ignore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PagueiApp(),
    ),
  );
}
