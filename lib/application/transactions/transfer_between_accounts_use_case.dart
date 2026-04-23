import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class TransferBetweenAccountsUseCase {
  const TransferBetweenAccountsUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Transaction> execute({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  }) {
    return _repository.createTransfer(
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
