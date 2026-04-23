import 'package:paguei/domain/repositories/bill_repository.dart';

final class DeleteBillUseCase {
  const DeleteBillUseCase(this._repository);

  final BillRepository _repository;

  Future<void> execute(String id) => _repository.delete(id);
}
