import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/app_environment.dart';
import 'core/di/providers.dart';
import 'presentation/app.dart';

void main() => _bootstrap(AppEnvironment.staging);

Future<void> _bootstrap(AppEnvironment env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await buildDatabase(env);

  runApp(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(env),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const PagueiApp(),
    ),
  );
}
