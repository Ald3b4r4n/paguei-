import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/accounts/create_account_use_case.dart';
import 'package:paguei/application/accounts/deactivate_account_use_case.dart';
import 'package:paguei/application/accounts/get_accounts_use_case.dart';
import 'package:paguei/application/accounts/update_account_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/repositories/account_repository_impl.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final accountsDaoProvider = Provider<AccountsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountsDao(db);
});

final accountRepositoryProvider = Provider<AccountRepositoryImpl>((ref) {
  return AccountRepositoryImpl(ref.watch(accountsDaoProvider));
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>((ref) {
  return CreateAccountUseCase(ref.watch(accountRepositoryProvider));
});

final getAccountsUseCaseProvider = Provider<GetAccountsUseCase>((ref) {
  return GetAccountsUseCase(ref.watch(accountRepositoryProvider));
});

final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>((ref) {
  return UpdateAccountUseCase(ref.watch(accountRepositoryProvider));
});

final deactivateAccountUseCaseProvider =
    Provider<DeactivateAccountUseCase>((ref) {
  return DeactivateAccountUseCase(ref.watch(accountRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Accounts stream — reactive list for UI
// ---------------------------------------------------------------------------

/// Streams all active (non-archived) accounts, updating automatically on change.
final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(getAccountsUseCaseProvider).watch();
});

/// Streams all accounts including archived ones (for settings / history screens).
final allAccountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(getAccountsUseCaseProvider).watch(includeArchived: true);
});

// ---------------------------------------------------------------------------
// AccountNotifier — imperative mutations wired to use cases
// ---------------------------------------------------------------------------

class AccountNotifier extends Notifier<AsyncValue<List<Account>>> {
  @override
  AsyncValue<List<Account>> build() {
    ref.watch(accountsStreamProvider).whenData(
          (accounts) => state = AsyncData(accounts),
        );
    return const AsyncLoading();
  }

  Future<void> createAccount({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async {
    await ref.read(createAccountUseCaseProvider).execute(
          id: id,
          name: name,
          type: type,
          initialBalance: initialBalance,
          currency: currency,
          color: color,
          icon: icon,
        );
  }

  Future<void> updateAccount({
    required String id,
    String? name,
    AccountType? type,
    Money? currentBalance,
    int? color,
    String? icon,
  }) async {
    await ref.read(updateAccountUseCaseProvider).execute(
          id: id,
          name: name,
          type: type,
          currentBalance: currentBalance,
          color: color,
          icon: icon,
        );
  }

  Future<void> archive(String id) async {
    await ref.read(deactivateAccountUseCaseProvider).archive(id);
  }

  Future<void> unarchive(String id) async {
    await ref.read(deactivateAccountUseCaseProvider).unarchive(id);
  }
}

final accountNotifierProvider =
    NotifierProvider<AccountNotifier, AsyncValue<List<Account>>>(
  AccountNotifier.new,
);
