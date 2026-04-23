import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/debts/create_debt_use_case.dart';
import 'package:paguei/application/debts/get_debts_use_case.dart';
import 'package:paguei/application/debts/register_debt_payment_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/debts_dao.dart';
import 'package:paguei/data/repositories/debt_repository_impl.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final debtsDaoProvider = Provider<DebtsDao>((ref) {
  return DebtsDao(ref.watch(appDatabaseProvider));
});

final debtRepositoryProvider = Provider<DebtRepositoryImpl>((ref) {
  return DebtRepositoryImpl(ref.watch(debtsDaoProvider));
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final createDebtUseCaseProvider = Provider<CreateDebtUseCase>((ref) {
  return CreateDebtUseCase(ref.watch(debtRepositoryProvider));
});

final getDebtsUseCaseProvider = Provider<GetDebtsUseCase>((ref) {
  return GetDebtsUseCase(ref.watch(debtRepositoryProvider));
});

final registerDebtPaymentUseCaseProvider =
    Provider<RegisterDebtPaymentUseCase>((ref) {
  return RegisterDebtPaymentUseCase(ref.watch(debtRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// All active debts, reactively updated.
final activeDebtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(getDebtsUseCaseProvider).watch(status: DebtStatus.active);
});

/// All debts regardless of status.
final allDebtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(getDebtsUseCaseProvider).watch();
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DebtNotifier extends Notifier<AsyncValue<List<Debt>>> {
  @override
  AsyncValue<List<Debt>> build() {
    ref.watch(allDebtsStreamProvider).whenData(
          (debts) => state = AsyncData(debts),
        );
    return const AsyncLoading();
  }

  Future<void> createDebt({
    required String creditorName,
    required Money totalAmount,
    int? installments,
    Money? installmentAmount,
    double? interestRate,
    DateTime? expectedEndDate,
    String? notes,
  }) async {
    await ref.read(createDebtUseCaseProvider).execute(
          creditorName: creditorName,
          totalAmount: totalAmount,
          installments: installments,
          installmentAmount: installmentAmount,
          interestRate: interestRate,
          expectedEndDate: expectedEndDate,
          notes: notes,
        );
  }

  Future<void> registerPayment(String debtId, Money amount) async {
    await ref.read(registerDebtPaymentUseCaseProvider).execute(
          debtId: debtId,
          amount: amount,
        );
  }

  Future<void> deleteDebt(String id) async {
    await ref.read(debtRepositoryProvider).delete(id);
  }
}

final debtNotifierProvider =
    NotifierProvider<DebtNotifier, AsyncValue<List<Debt>>>(DebtNotifier.new);
