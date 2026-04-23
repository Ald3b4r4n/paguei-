import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/application/bills/create_bill_use_case.dart';
import 'package:paguei/application/bills/delete_bill_use_case.dart';
import 'package:paguei/application/bills/get_bills_by_status_use_case.dart';
import 'package:paguei/application/bills/mark_bill_as_paid_use_case.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/data/database/daos/bills_dao.dart';
import 'package:paguei/data/repositories/bill_repository_impl.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/transactions/providers/transactions_provider.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final billsDaoProvider = Provider<BillsDao>((ref) {
  return BillsDao(ref.watch(appDatabaseProvider));
});

final billRepositoryProvider = Provider<BillRepositoryImpl>((ref) {
  return BillRepositoryImpl(ref.watch(billsDaoProvider));
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final createBillUseCaseProvider = Provider<CreateBillUseCase>((ref) {
  return CreateBillUseCase(ref.watch(billRepositoryProvider));
});

final deleteBillUseCaseProvider = Provider<DeleteBillUseCase>((ref) {
  return DeleteBillUseCase(ref.watch(billRepositoryProvider));
});

final getBillsByStatusUseCaseProvider =
    Provider<GetBillsByStatusUseCase>((ref) {
  return GetBillsByStatusUseCase(ref.watch(billRepositoryProvider));
});

final markBillAsPaidUseCaseProvider = Provider<MarkBillAsPaidUseCase>((ref) {
  return MarkBillAsPaidUseCase(
    ref.watch(billRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Stream providers for reactive UI
// ---------------------------------------------------------------------------

final allBillsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(getBillsByStatusUseCaseProvider).watchAll();
});

final pendingBillsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(getBillsByStatusUseCaseProvider).watchPending();
});

// ---------------------------------------------------------------------------
// BillNotifier — imperative mutations
// ---------------------------------------------------------------------------

class BillNotifier extends Notifier<AsyncValue<List<Bill>>> {
  @override
  AsyncValue<List<Bill>> build() {
    ref.watch(allBillsProvider).whenData(
          (bills) => state = AsyncData(bills),
        );
    return const AsyncLoading();
  }

  Future<void> markAsPaid({
    required String id,
    Money? paidAmount,
    DateTime? paidAt,
  }) async {
    await ref.read(markBillAsPaidUseCaseProvider).execute(
          id: id,
          paidAmount: paidAmount,
          paidAt: paidAt,
        );
  }

  Future<void> deleteBill(String id) async {
    await ref.read(deleteBillUseCaseProvider).execute(id);
  }

  Future<void> cancelBill(String id) async {
    await ref.read(billRepositoryProvider).cancel(id);
  }
}

final billNotifierProvider =
    NotifierProvider<BillNotifier, AsyncValue<List<Bill>>>(
  BillNotifier.new,
);

/// Separate stream per status for tab-based UI.
final billsByStatusProvider =
    StreamProvider.family<List<Bill>, BillStatus>((ref, status) async* {
  final repo = ref.watch(billRepositoryProvider);
  yield await repo.getByStatus(status);
  yield* repo.watchAll().map(
        (bills) => bills.where((b) => b.status == status).toList(),
      );
});
