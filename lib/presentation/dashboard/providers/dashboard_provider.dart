import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/dashboard/get_dashboard_summary_use_case.dart';
import 'package:paguei/data/database/daos/dashboard_dao.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/debts/providers/debts_provider.dart';
import 'package:paguei/presentation/funds/providers/funds_provider.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';

// ---------------------------------------------------------------------------
// DashboardState sealed class (from UI contracts)
// ---------------------------------------------------------------------------

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.summary);

  final DashboardSummary summary;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  return DashboardDao(ref.watch(appDatabaseProvider));
});

final getDashboardSummaryUseCaseProvider =
    Provider<GetDashboardSummaryUseCase>((ref) {
  return GetDashboardSummaryUseCase(
    accountRepository: ref.watch(accountRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    billRepository: ref.watch(billRepositoryProvider),
    fundRepository: ref.watch(fundRepositoryProvider),
    debtRepository: ref.watch(debtRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Summary provider
// ---------------------------------------------------------------------------

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  // Re-run whenever source streams change after financial mutations.
  ref.watch(accountsStreamProvider);
  ref.watch(allBillsProvider);
  ref.watch(_currentMonthTransactionsProvider);
  ref.watch(fundsStreamProvider);
  ref.watch(activeDebtsStreamProvider);

  return ref.watch(getDashboardSummaryUseCaseProvider).executeForCurrentMonth();
});

final _currentMonthTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  final now = DateTime.now();
  return ref.watch(getMonthlyTransactionsUseCaseProvider).watch(
        year: now.year,
        month: now.month,
      );
});

// ---------------------------------------------------------------------------
// DashboardNotifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    ref.listen(
      dashboardSummaryProvider,
      (_, next) {
        next.when(
          data: (summary) => state = DashboardLoaded(summary),
          loading: () => state = const DashboardLoading(),
          error: (e, _) => state = DashboardError(e.toString()),
        );
      },
      fireImmediately: true,
    );
    return const DashboardLoading();
  }

  Future<void> refresh() async {
    state = const DashboardLoading();
    try {
      final summary = await ref
          .read(getDashboardSummaryUseCaseProvider)
          .executeForCurrentMonth();
      state = DashboardLoaded(summary);
    } catch (e) {
      state = DashboardError(e.toString());
    }
  }
}

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
