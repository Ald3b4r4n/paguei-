import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/dashboard/dashboard_screen.dart';
import 'package:paguei/presentation/dashboard/providers/dashboard_provider.dart';
import 'package:paguei/presentation/dashboard/widgets/balance_card.dart';
import 'package:paguei/presentation/dashboard/widgets/bills_summary_card.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

DashboardSummary _buildSummary({
  Money? totalBalance,
  Money? monthlyIncome,
  Money? monthlyExpense,
  int overdueBillsCount = 0,
  List<BillSummary> upcomingBills = const [],
}) {
  return DashboardSummary(
    totalBalance: totalBalance ?? Money.fromDouble(5000.0),
    monthlyIncome: monthlyIncome ?? Money.fromDouble(3000.0),
    monthlyExpense: monthlyExpense ?? Money.fromDouble(1500.0),
    pendingBillsTotal: Money.fromDouble(200.0),
    overdueBillsTotal:
        overdueBillsCount > 0 ? Money.fromDouble(120.0) : Money.zero,
    overdueBillsCount: overdueBillsCount,
    fundsTotal: Money.fromDouble(1000.0),
    debtsTotal: Money.fromDouble(500.0),
    upcomingBills: upcomingBills,
    spendingTrends: const [],
    previousMonthIncome: Money.fromDouble(2800.0),
    previousMonthExpense: Money.fromDouble(1400.0),
    month: DateTime(2026, 4),
  );
}

Widget _buildScreen(DashboardState state) {
  return ProviderScope(
    overrides: [
      dashboardNotifierProvider.overrideWith(() => _FakeNotifier(state)),
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
      home: const DashboardScreen(),
    ),
  );
}

class _FakeNotifier extends DashboardNotifier {
  _FakeNotifier(this._state);

  final DashboardState _state;

  @override
  DashboardState build() => _state;
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  DashboardState state,
) async {
  await tester.pumpWidget(_buildScreen(state));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));

  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

void main() {
  group('DashboardScreen — estado de Loading', () {
    testWidgets('exibe BalanceCardLoading durante carregamento',
        (tester) async {
      await _pumpDashboard(tester, const DashboardLoading());

      expect(find.byType(BalanceCardLoading), findsOneWidget);
    });

    testWidgets('exibe BillsSummaryCardLoading durante carregamento',
        (tester) async {
      await _pumpDashboard(tester, const DashboardLoading());

      expect(find.byType(BillsSummaryCardLoading), findsOneWidget);
    });
  });

  group('DashboardScreen — estado de Loaded', () {
    testWidgets(r'exibe saldo total formatado em R$', (tester) async {
      final summary = _buildSummary(totalBalance: Money.fromDouble(5000.0));
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.textContaining('5.000'), findsOneWidget);
    });

    testWidgets('exibe BalanceCard quando carregado', (tester) async {
      final summary = _buildSummary();
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.byType(BalanceCard), findsOneWidget);
    });

    testWidgets('exibe BillsSummaryCard quando carregado', (tester) async {
      final summary = _buildSummary();
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.byType(BillsSummaryCard), findsOneWidget);
    });

    testWidgets('exibe entradas e saídas do mês', (tester) async {
      final summary = _buildSummary(
        monthlyIncome: Money.fromDouble(3000.0),
        monthlyExpense: Money.fromDouble(1500.0),
      );
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.text('Entrou este mês'), findsOneWidget);
      expect(find.text('Saiu este mês'), findsOneWidget);
    });

    testWidgets('exibe banner de alerta quando há boletos vencidos',
        (tester) async {
      final summary = _buildSummary(overdueBillsCount: 2);
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.textContaining('vencido'), findsAtLeastNWidgets(1));
    });

    testWidgets('não exibe banner de alerta sem boletos vencidos',
        (tester) async {
      final summary = _buildSummary(overdueBillsCount: 0);
      await _pumpDashboard(tester, DashboardLoaded(summary));

      // No overdue warning banner
      expect(find.text('Regularize sua situação.'), findsNothing);
    });

    testWidgets('exibe seção de próximos vencimentos quando há boletos',
        (tester) async {
      final now = DateTime.now().toUtc();
      final summary = _buildSummary(
        upcomingBills: [
          BillSummary(
            id: 'b1',
            title: 'Energia',
            amount: Money.fromDouble(120.0),
            dueDate: now.add(const Duration(days: 3)),
            effectiveStatus: BillStatus.pending,
          ),
        ],
      );
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(find.text('Próximos 7 dias'), findsOneWidget);
      expect(find.text('Energia'), findsOneWidget);
    });

    testWidgets('exibe mensagem vazia quando não há boletos próximos',
        (tester) async {
      final summary = _buildSummary(upcomingBills: []);
      await _pumpDashboard(tester, DashboardLoaded(summary));

      expect(
        find.textContaining('Nenhum boleto vencendo'),
        findsOneWidget,
      );
    });
  });

  group('DashboardScreen — estado de Error', () {
    testWidgets('exibe mensagem de erro', (tester) async {
      await _pumpDashboard(
        tester,
        const DashboardError('Falha de conexão'),
      );

      expect(find.text('Erro ao carregar dashboard'), findsOneWidget);
      expect(find.text('Falha de conexão'), findsOneWidget);
    });

    testWidgets('exibe ícone de erro', (tester) async {
      await _pumpDashboard(tester, const DashboardError('Erro'));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
