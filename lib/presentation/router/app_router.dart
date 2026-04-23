import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/parsed_bill_data.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/presentation/accounts/account_form_screen.dart';
import 'package:paguei/presentation/accounts/account_list_screen.dart';
import 'package:paguei/presentation/bills/bill_form_screen.dart';
import 'package:paguei/presentation/bills/bill_list_screen.dart';
import 'package:paguei/presentation/dashboard/dashboard_screen.dart';
import 'package:paguei/presentation/debts/debt_form_screen.dart';
import 'package:paguei/presentation/debts/debt_list_screen.dart';
import 'package:paguei/presentation/feedback/feedback_screen.dart';
import 'package:paguei/presentation/funds/fund_form_screen.dart';
import 'package:paguei/presentation/funds/fund_list_screen.dart';
import 'package:paguei/presentation/scanner/bill_review_screen.dart';
import 'package:paguei/presentation/scanner/bill_scan_screen.dart';
import 'package:paguei/presentation/settings/backup_settings_screen.dart';
import 'package:paguei/presentation/settings/diagnostics_screen.dart';
import 'package:paguei/presentation/settings/export_center_screen.dart';
import 'package:paguei/presentation/settings/notification_settings_screen.dart';
import 'package:paguei/presentation/settings/settings_screen.dart';
import 'package:paguei/presentation/summary/summary_screen.dart';
import 'package:paguei/presentation/transactions/transaction_form_screen.dart';
import 'package:paguei/presentation/transactions/transaction_list_screen.dart';
import 'package:paguei/presentation/transactions/transfer_form_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.dashboard,
  debugLogDiagnostics: true,
  routes: [
    // ── Top-level routes (full-screen, no bottom nav) ────────────────────────

    GoRoute(
      path: AppRoutes.accounts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AccountListScreen(),
      routes: [
        GoRoute(
          path: 'nova',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AccountFormScreen(),
        ),
        GoRoute(
          path: ':id/editar',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final account = state.extra as Account?;
            return AccountFormScreen(existingAccount: account);
          },
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.funds,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FundListScreen(),
      routes: [
        GoRoute(
          path: 'nova',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const FundFormScreen(),
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.debts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DebtListScreen(),
      routes: [
        GoRoute(
          path: 'nova',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const DebtFormScreen(),
        ),
      ],
    ),

    // ── Shell route (with bottom navigation bar) ─────────────────────────────

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.bills,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BillListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'nova',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const BillFormScreen(),
            ),
            GoRoute(
              path: 'scan',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final initialAction = state.extra is BillScanInitialAction
                    ? state.extra! as BillScanInitialAction
                    : BillScanInitialAction.scan;
                return BillScanScreen(initialAction: initialAction);
              },
            ),
            GoRoute(
              path: 'review',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final data = state.extra as ParsedBillData?;
                if (data == null) {
                  return const _MissingDataScreen(
                    message:
                        'Dados do boleto não encontrados.\nTente escanear novamente.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return BillReviewScreen(parsedData: data);
              },
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              redirect: (_, __) => AppRoutes.bills,
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.transactions,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TransactionListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'nova',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const TransactionFormScreen(),
            ),
            GoRoute(
              path: 'transferencia',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const TransferFormScreen(),
            ),
            GoRoute(
              path: ':id/editar',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final txn = state.extra as Transaction?;
                return TransactionFormScreen(existingTransaction: txn);
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.summary,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SummaryScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'notificacoes',
              builder: (context, state) => const NotificationSettingsScreen(),
            ),
            GoRoute(
              path: 'backup',
              builder: (context, state) => const BackupSettingsScreen(),
            ),
            GoRoute(
              path: 'exportar',
              builder: (context, state) => const ExportCenterScreen(),
            ),
            GoRoute(
              path: 'diagnostico',
              builder: (context, state) => const DiagnosticsScreen(),
            ),
            GoRoute(
              path: 'privacidade',
              builder: (context, state) => const PrivacyConsentScreen(),
            ),
            GoRoute(
              path: 'feedback',
              builder: (context, state) => const FeedbackScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _MissingDataScreen(
    message: 'Página não encontrada:\n${state.uri}',
    icon: Icons.explore_off_outlined,
  ),
);

abstract final class AppRoutes {
  // ── Tab roots ──────────────────────────────────────────────────────────────
  static const dashboard = '/';
  static const bills = '/boletos';
  static const transactions = '/transacoes';
  static const summary = '/resumo';
  static const settings = '/ajustes';

  // ── Bill sub-routes ────────────────────────────────────────────────────────
  static const billNew = '/boletos/nova';
  static const billScan = '/boletos/scan';
  static const billReview = '/boletos/review';

  // ── Transaction sub-routes ─────────────────────────────────────────────────
  static const transactionNew = '/transacoes/nova';
  static const transactionTransfer = '/transacoes/transferencia';

  // ── Settings sub-routes ────────────────────────────────────────────────────
  static const notificationSettings = '/ajustes/notificacoes';
  static const backupSettings = '/ajustes/backup';
  static const exportCenter = '/ajustes/exportar';
  static const diagnostics = '/ajustes/diagnostico';
  static const privacyConsent = '/ajustes/privacidade';
  static const feedback = '/ajustes/feedback';

  // ── Feature screens (full-screen, no bottom nav) ───────────────────────────
  static const accounts = '/contas';
  static const accountNew = '/contas/nova';
  static const funds = '/fundos';
  static const fundNew = '/fundos/nova';
  static const debts = '/dividas';
  static const debtNew = '/dividas/nova';
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    AppRoutes.dashboard,
    AppRoutes.bills,
    AppRoutes.transactions,
    AppRoutes.summary,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Boletos',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.bills)) return 1;
    if (location.startsWith(AppRoutes.transactions)) return 2;
    if (location.startsWith(AppRoutes.summary)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }
}

// ---------------------------------------------------------------------------
// Internal fallback widget — shown when route data is missing.
// ---------------------------------------------------------------------------

class _MissingDataScreen extends StatelessWidget {
  const _MissingDataScreen({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
