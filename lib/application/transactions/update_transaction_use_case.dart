import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Transaction> execute({
    required String id,
    String? description,
    Money? amount,
    DateTime? date,
    TransactionType? type,
    String? categoryId,
    String? notes,
  }) async {
    final existing = await _repository.getById(id);
    if (existing == null) {
      throw StateError('Transação não encontrada: $id');
    }

    final updated = existing.copyWith(
      description: description,
      amount: amount,
      date: date,
      type: type,
      categoryId: categoryId,
      notes: notes,
      updatedAt: DateTime.now().toUtc(),
    );

    return _repository.update(updated);
  }
}
