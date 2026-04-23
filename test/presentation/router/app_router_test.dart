import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/di/app_environment.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/presentation/router/app_router.dart';

import '../../helpers/drift_test_helpers.dart';

void main() {
  group('AppRoutes — constantes de rota', () {
    test('dashboard é /', () {
      expect(AppRoutes.dashboard, equals('/'));
    });

    test('bills é /boletos', () {
      expect(AppRoutes.bills, equals('/boletos'));
    });

    test('transactions é /transacoes', () {
      expect(AppRoutes.transactions, equals('/transacoes'));
    });

    test('summary é /resumo', () {
      expect(AppRoutes.summary, equals('/resumo'));
    });

    test('settings é /ajustes', () {
      expect(AppRoutes.settings, equals('/ajustes'));
    });

    test('billNew é /boletos/nova', () {
      expect(AppRoutes.billNew, equals('/boletos/nova'));
    });

    test('transactionNew é /transacoes/nova', () {
      expect(AppRoutes.transactionNew, equals('/transacoes/nova'));
    });

    test('accounts é /contas', () {
      expect(AppRoutes.accounts, equals('/contas'));
    });

    test('funds é /fundos', () {
      expect(AppRoutes.funds, equals('/fundos'));
    });

    test('debts é /dividas', () {
      expect(AppRoutes.debts, equals('/dividas'));
    });

    test('backupSettings é /ajustes/backup', () {
      expect(AppRoutes.backupSettings, equals('/ajustes/backup'));
    });

    test('diagnostics é /ajustes/diagnostico', () {
      expect(AppRoutes.diagnostics, equals('/ajustes/diagnostico'));
    });
  });

  group('AppShell — índice de aba', () {
    Widget buildApp(AppDatabase db) {
      return ProviderScope(
        overrides: [
          appEnvironmentProvider.overrideWithValue(AppEnvironment.development),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      );
    }

    testWidgets('renderiza NavigationBar com 5 destinos', (tester) async {
      final db = buildInMemoryDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(buildApp(db));
      await tester.pump(); // first frame

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('rota inicial é dashboard (índice 0)', (tester) async {
      final db = buildInMemoryDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(buildApp(db));
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(0));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('tap em Boletos navega para /boletos', (tester) async {
      final db = buildInMemoryDatabase();
      addTearDown(db.close);

      await tester.pumpWidget(buildApp(db));
      await tester.pump();

      await tester.tap(find.text('Boletos'));
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(1));

      // Dispose animated widgets to avoid pending timers from flutter_animate.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}
