import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/transactions/create_transaction_use_case.dart';
import 'package:paguei/application/transactions/delete_transaction_use_case.dart';
import 'package:paguei/application/transactions/get_monthly_transactions_use_case.dart';
import 'package:paguei/application/transactions/transfer_between_accounts_use_case.dart';
import 'package:paguei/application/transactions/update_transaction_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/transactions_dao.dart';
import 'package:paguei/data/repositories/transaction_repository_impl.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final transactionsDaoProvider = Provider<TransactionsDao>((ref) {
  return TransactionsDao(ref.watch(appDatabaseProvider));
});

final transactionRepositoryProvider =
    Provider<TransactionRepositoryImpl>((ref) {
  return TransactionRepositoryImpl(
    ref.watch(transactionsDaoProvider),
    ref.watch(accountsDaoProvider),
  );
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final createTransactionUseCaseProvider =
    Provider<CreateTransactionUseCase>((ref) {
  return CreateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider =
    Provider<UpdateTransactionUseCase>((ref) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider =
    Provider<DeleteTransactionUseCase>((ref) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final getMonthlyTransactionsUseCaseProvider =
    Provider<GetMonthlyTransactionsUseCase>((ref) {
  return GetMonthlyTransactionsUseCase(
      ref.watch(transactionRepositoryProvider));
});

final transferBetweenAccountsUseCaseProvider =
    Provider<TransferBetweenAccountsUseCase>((ref) {
  return TransferBetweenAccountsUseCase(
      ref.watch(transactionRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Selected month state
// ---------------------------------------------------------------------------

class _SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  set month(DateTime value) => state = value;
}

final selectedMonthProvider =
    NotifierProvider<_SelectedMonthNotifier, DateTime>(
  _SelectedMonthNotifier.new,
);

// ---------------------------------------------------------------------------
// Transactions stream for the selected month
// ---------------------------------------------------------------------------

final monthlyTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final DateTime month = ref.watch(selectedMonthProvider);
  return ref.watch(getMonthlyTransactionsUseCaseProvider).watch(
        year: month.year,
        month: month.month,
      );
});

final monthlyIncomeProvider = FutureProvider<Money>((ref) async {
  final DateTime month = ref.watch(selectedMonthProvider);
  ref.watch(monthlyTransactionsProvider);
  return ref.watch(getMonthlyTransactionsUseCaseProvider).getSummary(
        year: month.year,
        month: month.month,
        type: TransactionType.income,
      );
});

final monthlyExpenseProvider = FutureProvider<Money>((ref) async {
  final DateTime month = ref.watch(selectedMonthProvider);
  ref.watch(monthlyTransactionsProvider);
  return ref.watch(getMonthlyTransactionsUseCaseProvider).getSummary(
        year: month.year,
        month: month.month,
        type: TransactionType.expense,
      );
});

// ---------------------------------------------------------------------------
// TransactionNotifier — imperative mutations
// ---------------------------------------------------------------------------

class TransactionNotifier extends Notifier<AsyncValue<List<Transaction>>> {
  @override
  AsyncValue<List<Transaction>> build() {
    ref.watch(monthlyTransactionsProvider).whenData(
          (txns) => state = AsyncData(txns),
        );
    return const AsyncLoading();
  }

  Future<void> createTransaction({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? notes,
  }) async {
    await ref.read(createTransactionUseCaseProvider).execute(
          id: id,
          accountId: accountId,
          type: type,
          amount: amount,
          description: description,
          date: date,
          categoryId: categoryId,
          notes: notes,
        );
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(deleteTransactionUseCaseProvider).execute(id);
  }

  Future<void> transfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  }) async {
    await ref.read(transferBetweenAccountsUseCaseProvider).execute(
          id: id,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          description: description,
          date: date,
          notes: notes,
        );
  }
}

final transactionNotifierProvider =
    NotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>(
  TransactionNotifier.new,
);
