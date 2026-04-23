import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/theme/app_theme.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';
import 'package:paguei/presentation/transactions/transaction_list_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

List<Transaction> _buildTransactions() {
  final now = DateTime.utc(2026, 4, 15);
  return [
    Transaction(
      id: 'txn-1',
      accountId: 'acc-1',
      type: TransactionType.expense,
      amount: Money(5000), // R$ 50,00
      description: 'Almoço',
      date: now,
      isRecurring: false,
      createdAt: now,
      updatedAt: now,
    ),
    Transaction(
      id: 'txn-2',
      accountId: 'acc-1',
      type: TransactionType.income,
      amount: Money(300000), // R$ 3.000,00
      description: 'Salário',
      date: now.subtract(const Duration(days: 5)),
      isRecurring: false,
      createdAt: now,
      updatedAt: now,
    ),
    Transaction(
      id: 'txn-3',
      accountId: 'acc-1',
      type: TransactionType.transfer,
      amount: Money(20000), // R$ 200,00
      description: 'Transferência poupança',
      date: now.subtract(const Duration(days: 2)),
      isRecurring: false,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

Widget _buildTestWidget({
  List<Transaction>? transactions,
  Money income = const Money(300000),
  Money expense = const Money(5000),
}) {
  return ProviderScope(
    overrides: [
      monthlyTransactionsProvider.overrideWith(
        (ref) => Stream.value(transactions ?? _buildTransactions()),
      ),
      monthlyIncomeProvider.overrideWith((ref) async => income),
      monthlyExpenseProvider.overrideWith((ref) async => expense),
      accountsStreamProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const TransactionListScreen(),
    ),
  );
}

void main() {
  group('TransactionListScreen', () {
    testWidgets('exibe transações do mês', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Salário'), findsOneWidget);
      expect(find.text('Transferência poupança'), findsOneWidget);
    });

    testWidgets('exibe estado vazio quando não há transações', (tester) async {
      await tester.pumpWidget(_buildTestWidget(transactions: []));
      await tester.pump();

      expect(find.text('Nenhuma transação neste mês'), findsOneWidget);
    });

    testWidgets('exibe sumário mensal de entrada e saída', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Entrou'), findsOneWidget);
      expect(find.text('Saiu'), findsOneWidget);
    });

    testWidgets('exibe FAB de adicionar transação', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('exibe barra de filtros por tipo', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Receitas'), findsAtLeastNWidgets(1));
      expect(find.text('Despesas'), findsAtLeastNWidgets(1));
      expect(find.text('Transferências'), findsOneWidget);
    });

    testWidgets('estado de loading exibe CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
            monthlyIncomeProvider.overrideWith((ref) async => Money.zero),
            monthlyExpenseProvider.overrideWith((ref) async => Money.zero),
            accountsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
            locale: const Locale('pt', 'BR'),
            home: const TransactionListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });
  });
}
