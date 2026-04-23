import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paguei/application/export/backup_service.dart';
import 'package:paguei/application/export/export_database_use_case.dart';
import 'package:paguei/application/export/restore_service.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/database/daos/bills_dao.dart';
import 'package:paguei/data/database/daos/categories_dao.dart';
import 'package:paguei/data/database/daos/debts_dao.dart';
import 'package:paguei/data/database/daos/funds_dao.dart';
import 'package:paguei/data/database/daos/transactions_dao.dart';
import 'package:paguei/data/repositories/account_repository_impl.dart';
import 'package:paguei/data/repositories/bill_repository_impl.dart';
import 'package:paguei/data/repositories/category_repository_impl.dart';
import 'package:paguei/data/repositories/debt_repository_impl.dart';
import 'package:paguei/data/repositories/fund_repository_impl.dart';
import 'package:paguei/data/repositories/transaction_repository_impl.dart';
import 'package:paguei/presentation/notifications/providers/notifications_provider.dart';

// ---------------------------------------------------------------------------
// Storage key
// ---------------------------------------------------------------------------

const _kLastBackupKey = 'backup_last_at_v1';

// ---------------------------------------------------------------------------
// DAO providers (reuse database provider)
// ---------------------------------------------------------------------------

final _accountsDaoProvider = Provider<AccountsDao>(
  (ref) => AccountsDao(ref.watch(appDatabaseProvider)),
);
final _transactionsDaoProvider = Provider<TransactionsDao>(
  (ref) => TransactionsDao(ref.watch(appDatabaseProvider)),
);
final _billsDaoProvider = Provider<BillsDao>(
  (ref) => BillsDao(ref.watch(appDatabaseProvider)),
);
final _fundsDaoProvider = Provider<FundsDao>(
  (ref) => FundsDao(ref.watch(appDatabaseProvider)),
);
final _debtsDaoProvider = Provider<DebtsDao>(
  (ref) => DebtsDao(ref.watch(appDatabaseProvider)),
);
final _categoriesDaoProvider = Provider<CategoriesDao>(
  (ref) => CategoriesDao(ref.watch(appDatabaseProvider)),
);

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final _backupAccountRepoProvider = Provider<AccountRepositoryImpl>(
  (ref) => AccountRepositoryImpl(ref.watch(_accountsDaoProvider)),
);
final _backupTransactionRepoProvider = Provider<TransactionRepositoryImpl>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(_transactionsDaoProvider),
    ref.watch(_accountsDaoProvider),
  ),
);
final _backupBillRepoProvider = Provider<BillRepositoryImpl>(
  (ref) => BillRepositoryImpl(ref.watch(_billsDaoProvider)),
);
final _backupFundRepoProvider = Provider<FundRepositoryImpl>(
  (ref) => FundRepositoryImpl(ref.watch(_fundsDaoProvider)),
);
final _backupDebtRepoProvider = Provider<DebtRepositoryImpl>(
  (ref) => DebtRepositoryImpl(ref.watch(_debtsDaoProvider)),
);
final _backupCategoryRepoProvider = Provider<CategoryRepositoryImpl>(
  (ref) => CategoryRepositoryImpl(ref.watch(_categoriesDaoProvider)),
);

// ---------------------------------------------------------------------------
// ExportDatabaseUseCase provider
// ---------------------------------------------------------------------------

final exportDatabaseUseCaseProvider = Provider<ExportDatabaseUseCase>((ref) {
  return ExportDatabaseUseCase(
    accounts: ref.watch(_backupAccountRepoProvider),
    transactions: ref.watch(_backupTransactionRepoProvider),
    bills: ref.watch(_backupBillRepoProvider),
    funds: ref.watch(_backupFundRepoProvider),
    debts: ref.watch(_backupDebtRepoProvider),
    categories: ref.watch(_backupCategoryRepoProvider),
  );
});

// ---------------------------------------------------------------------------
// RestoreService provider
// ---------------------------------------------------------------------------

final restoreServiceProvider = Provider<RestoreService>((ref) {
  return RestoreService(
    accounts: ref.watch(_backupAccountRepoProvider),
    transactions: ref.watch(_backupTransactionRepoProvider),
    bills: ref.watch(_backupBillRepoProvider),
    funds: ref.watch(_backupFundRepoProvider),
    debts: ref.watch(_backupDebtRepoProvider),
    categories: ref.watch(_backupCategoryRepoProvider),
  );
});

// ---------------------------------------------------------------------------
// Last backup timestamp
// ---------------------------------------------------------------------------

/// Reads / writes the last backup timestamp from secure storage.
final lastBackupProvider = AsyncNotifierProvider<LastBackupNotifier, DateTime?>(
  LastBackupNotifier.new,
);

final class LastBackupNotifier extends AsyncNotifier<DateTime?> {
  FlutterSecureStorage get _storage => ref.watch(secureStorageProvider);

  @override
  Future<DateTime?> build() async {
    final raw = await _storage.read(key: _kLastBackupKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> markNow() async {
    final now = DateTime.now().toUtc();
    await _storage.write(
      key: _kLastBackupKey,
      value: now.toIso8601String(),
    );
    state = AsyncValue.data(now);
  }
}

// ---------------------------------------------------------------------------
// BackupState — for the BackupSettingsScreen
// ---------------------------------------------------------------------------

/// Represents the async operation state of a backup / restore action.
sealed class BackupOperationState {
  const BackupOperationState();
}

final class BackupIdle extends BackupOperationState {
  const BackupIdle();
}

final class BackupInProgress extends BackupOperationState {
  const BackupInProgress(this.message);
  final String message;
}

final class BackupSuccess extends BackupOperationState {
  const BackupSuccess(this.message);
  final String message;
}

final class BackupError extends BackupOperationState {
  const BackupError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// BackupSettingsNotifier
// ---------------------------------------------------------------------------

final backupSettingsProvider =
    NotifierProvider<BackupSettingsNotifier, BackupOperationState>(
  BackupSettingsNotifier.new,
);

final class BackupSettingsNotifier extends Notifier<BackupOperationState> {
  @override
  BackupOperationState build() => const BackupIdle();

  /// Creates a backup file in the app's documents directory and returns the
  /// [File] so the caller can share or save it.
  Future<File?> createBackup({
    required String appVersion,
    String? password,
  }) async {
    state = const BackupInProgress('Criando backup…');
    try {
      final data = await ref.read(exportDatabaseUseCaseProvider).execute();
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now()
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File('${dir.path}/paguei_backup_$ts.paguei.backup');

      await BackupService.writeBackup(
        file: file,
        data: data,
        appVersion: appVersion,
        password: password,
      );

      await ref.read(lastBackupProvider.notifier).markNow();
      state = const BackupSuccess('Backup criado com sucesso.');
      return file;
    } catch (e) {
      state = BackupError('Erro ao criar backup: $e');
      return null;
    }
  }

  /// Reads the manifest from [file] and returns a [RestorePreview] without
  /// decrypting the payload.
  Future<RestorePreview?> previewBackup(File file) async {
    state = const BackupInProgress('Lendo backup…');
    try {
      final manifest = await BackupService.readManifest(file);
      state = const BackupIdle();
      return RestorePreview.fromManifest(manifest);
    } catch (e) {
      state = BackupError('Erro ao ler backup: $e');
      return null;
    }
  }

  /// Fully restores a backup file.
  Future<RestoreResult?> restoreBackup({
    required File file,
    String? password,
    required RestoreMode mode,
  }) async {
    state = const BackupInProgress('Restaurando backup…');
    try {
      final data = await BackupService.decodeBackup(
        file: file,
        password: password,
      );
      final result = await ref.read(restoreServiceProvider).restore(
            data,
            mode: mode,
          );
      final summary = 'Restaurado: ${result.totalInserted} inseridos, '
          '${result.totalUpdated} atualizados, '
          '${result.totalSkipped} ignorados.';
      state = BackupSuccess(summary);
      return result;
    } on BackupDecryptionException catch (e) {
      state = BackupError(e.message);
      return null;
    } on BackupVersionException catch (e) {
      state = BackupError('Versão de backup incompatível (v${e.version}).');
      return null;
    } catch (e) {
      state = BackupError('Erro ao restaurar: $e');
      return null;
    }
  }

  void clearStatus() => state = const BackupIdle();
}
