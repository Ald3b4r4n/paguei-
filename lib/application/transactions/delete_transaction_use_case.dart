import 'package:paguei/domain/repositories/transaction_repository.dart';

final class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<void> execute(String id) => _repository.delete(id);
}
