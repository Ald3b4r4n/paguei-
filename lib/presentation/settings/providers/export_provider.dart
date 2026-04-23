import 'dart:io';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paguei/application/export/csv_export_service.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/database/daos/bills_dao.dart';
import 'package:paguei/data/database/daos/debts_dao.dart';
import 'package:paguei/data/database/daos/transactions_dao.dart';
import 'package:paguei/data/repositories/bill_repository_impl.dart';
import 'package:paguei/data/repositories/debt_repository_impl.dart';
import 'package:paguei/data/repositories/transaction_repository_impl.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/presentation/accounts/providers/accounts_provider.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';

// ---------------------------------------------------------------------------
// Lightweight repo providers for export (separate instances from main app)
// ---------------------------------------------------------------------------

final _exportTransactionsDaoProvider = Provider<TransactionsDao>(
  (ref) => TransactionsDao(ref.watch(appDatabaseProvider)),
);
final _exportAccountsDaoProvider = Provider<AccountsDao>(
  (ref) => AccountsDao(ref.watch(appDatabaseProvider)),
);
final _exportBillsDaoProvider = Provider<BillsDao>(
  (ref) => BillsDao(ref.watch(appDatabaseProvider)),
);
final _exportDebtsDaoProvider = Provider<DebtsDao>(
  (ref) => DebtsDao(ref.watch(appDatabaseProvider)),
);

final _exportTransactionRepoProvider = Provider<TransactionRepositoryImpl>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(_exportTransactionsDaoProvider),
    ref.watch(_exportAccountsDaoProvider),
  ),
);
final _exportBillRepoProvider = Provider<BillRepositoryImpl>(
  (ref) => BillRepositoryImpl(ref.watch(_exportBillsDaoProvider)),
);
final _exportDebtRepoProvider = Provider<DebtRepositoryImpl>(
  (ref) => DebtRepositoryImpl(ref.watch(_exportDebtsDaoProvider)),
);

// ---------------------------------------------------------------------------
// CSV export state
// ---------------------------------------------------------------------------

sealed class CsvExportState {
  const CsvExportState();
}

final class CsvExportIdle extends CsvExportState {
  const CsvExportIdle();
}

final class CsvExportInProgress extends CsvExportState {
  const CsvExportInProgress();
}

final class CsvExportSuccess extends CsvExportState {
  /// The generated temp file ready for sharing.
  const CsvExportSuccess(this.file);
  final File file;
}

final class CsvExportError extends CsvExportState {
  const CsvExportError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// CsvExportNotifier
// ---------------------------------------------------------------------------

final csvExportProvider = NotifierProvider<CsvExportNotifier, CsvExportState>(
  CsvExportNotifier.new,
);

final class CsvExportNotifier extends Notifier<CsvExportState> {
  @override
  CsvExportState build() => const CsvExportIdle();

  // ── Transactions export ──────────────────────────────────────────────────

  /// Exports all transactions in [dateRange] (or all time if null) to CSV.
  Future<File?> exportTransactions({DateTimeRange? dateRange}) async {
    state = const CsvExportInProgress();
    try {
      final transactions = await _fetchTransactions(dateRange);
      final csv = CsvExportService.transactionsToCsv(
        transactions,
        categoryNames: _categoryNames(),
        accountNames: _accountNames(),
      );
      final file = await _writeCsv(csv, 'transacoes');
      state = CsvExportSuccess(file);
      return file;
    } catch (e) {
      state = CsvExportError('Erro ao exportar transações: $e');
      return null;
    }
  }

  // ── Monthly report export ────────────────────────────────────────────────

  Future<File?> exportMonthlyReport({
    required int year,
    required int month,
  }) async {
    state = const CsvExportInProgress();
    try {
      final transactions = await _fetchTransactions(
        DateTimeRange(
          start: DateTime.utc(year, month),
          end: DateTime.utc(year, month + 1, 0, 23, 59, 59),
        ),
      );
      final csv = CsvExportService.monthlyReportToCsv(
        transactions,
        categoryNames: _categoryNames(),
        year: year,
        month: month,
      );
      final label = 'relatorio_${year}_${month.toString().padLeft(2, '0')}';
      final file = await _writeCsv(csv, label);
      state = CsvExportSuccess(file);
      return file;
    } catch (e) {
      state = CsvExportError('Erro ao exportar relatório: $e');
      return null;
    }
  }

  // ── Bills export ─────────────────────────────────────────────────────────

  Future<File?> exportBills() async {
    state = const CsvExportInProgress();
    try {
      final bills = await _fetchBills();
      final csv = CsvExportService.billsToCsv(bills);
      final file = await _writeCsv(csv, 'boletos');
      state = CsvExportSuccess(file);
      return file;
    } catch (e) {
      state = CsvExportError('Erro ao exportar boletos: $e');
      return null;
    }
  }

  // ── Debts snapshot export ────────────────────────────────────────────────

  Future<File?> exportDebts() async {
    state = const CsvExportInProgress();
    try {
      final debts = await _fetchDebts();
      final csv = CsvExportService.debtsToCsv(debts);
      final file = await _writeCsv(csv, 'dividas');
      state = CsvExportSuccess(file);
      return file;
    } catch (e) {
      state = CsvExportError('Erro ao exportar dívidas: $e');
      return null;
    }
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  void clearStatus() => state = const CsvExportIdle();

  // ── Data access ───────────────────────────────────────────────────────────

  Future<List<Transaction>> _fetchTransactions(DateTimeRange? range) {
    return ref.read(_exportTransactionRepoProvider).getByDateRange(
          start: range?.start ?? DateTime.utc(2000),
          end: range?.end ?? DateTime.utc(2100),
        );
  }

  Future<List<Bill>> _fetchBills() =>
      ref.read(_exportBillRepoProvider).getAll();

  Future<List<Debt>> _fetchDebts() =>
      ref.read(_exportDebtRepoProvider).getAll();

  Map<String, String> _categoryNames() {
    final cats = ref.read(categoriesStreamProvider).asData?.value ?? [];
    return {for (final c in cats) c.id: c.name};
  }

  Map<String, String> _accountNames() {
    final accounts = ref.read(allAccountsStreamProvider).asData?.value ?? [];
    return {for (final a in accounts) a.id: a.name};
  }

  // ── File helpers ──────────────────────────────────────────────────────────

  Future<File> _writeCsv(String csv, String label) async {
    final tmp = await getTemporaryDirectory();
    final ts =
        DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${tmp.path}/paguei_${label}_$ts.csv');
    await file.writeAsString(csv, flush: true);
    return file;
  }
}
