import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class CreateTransactionUseCase {
  const CreateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Transaction> execute({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? billId,
    bool isRecurring = false,
    String? recurrenceGroupId,
    String? notes,
  }) async {
    if (accountId.trim().isEmpty) {
      throw const ValidationException(
        message: 'Escolha um local do dinheiro',
      );
    }

    return _repository.create(
      id: id,
      accountId: accountId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      billId: billId,
      isRecurring: isRecurring,
      recurrenceGroupId: recurrenceGroupId,
      notes: notes,
    );
  }
}
