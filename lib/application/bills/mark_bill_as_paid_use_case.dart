import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:uuid/uuid.dart';

final class MarkBillAsPaidUseCase {
  const MarkBillAsPaidUseCase(
      this._billRepository, this._transactionRepository);

  final BillRepository _billRepository;
  final TransactionRepository _transactionRepository;

  /// Marks a bill as paid and creates a linked expense transaction if the bill
  /// has an associated account.
  Future<Bill> execute({
    required String id,
    Money? paidAmount,
    DateTime? paidAt,
  }) async {
    final existing = await _billRepository.getById(id);
    if (existing == null) {
      throw NotFoundException(message: 'Boleto não encontrado: $id');
    }
    if (existing.isPaid) {
      throw const ValidationException(message: 'Boleto já está pago.');
    }
    if (existing.isCancelled) {
      throw const ValidationException(
          message: 'Boleto cancelado não pode ser marcado como pago.');
    }

    final effectivePaidAt = paidAt ?? DateTime.now().toUtc();
    final effectivePaidAmount = paidAmount ?? existing.amount;

    // Create a linked transaction if a debit account is set
    if (existing.accountId != null) {
      await _transactionRepository.create(
        id: const Uuid().v4(),
        accountId: existing.accountId!,
        type: TransactionType.expense,
        amount: effectivePaidAmount,
        description: existing.title,
        date: effectivePaidAt,
        categoryId: existing.categoryId,
        billId: existing.id,
      );
    }

    return _billRepository.markAsPaid(
      id: id,
      paidAmount: effectivePaidAmount,
      paidAt: effectivePaidAt,
    );
  }
}
