import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/di/app_environment.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

import 'drift_test_helpers.dart';

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpPagueiWidget(
    Widget widget, {
    AppDatabase? database,
  }) async {
    final db = database ?? buildInMemoryDatabase();

    await pumpWidget(
      ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.development),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),
          home: widget,
        ),
      ),
    );
  }
}

Matcher throwsAppException() => throwsA(isA<Exception>());

Future<AppDatabase> buildAndSeedDatabase() async {
  final db = buildInMemoryDatabase();
  await db.seedTestAccount();
  await db.seedTestCategory();
  return db;
}
