import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/app_environment.dart';
import 'core/di/providers.dart';
import 'core/notifications/notification_initializer.dart';
import 'presentation/app.dart';

void main() => _bootstrap(AppEnvironment.development);

Future<void> _bootstrap(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await buildDatabase(env);

  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(env),
      appDatabaseProvider.overrideWithValue(database),
    ],
  );

  // Notifications are initialised in development too, so the full flow
  // can be tested on a simulator/device.
  NotificationInitializer.run(container).ignore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PagueiApp(),
    ),
  );
}
