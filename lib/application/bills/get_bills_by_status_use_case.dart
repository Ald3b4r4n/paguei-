import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';

final class GetBillsByStatusUseCase {
  const GetBillsByStatusUseCase(this._repository);

  final BillRepository _repository;

  Future<List<Bill>> execute(BillStatus status) =>
      _repository.getByStatus(status);

  Future<List<Bill>> getPending() => _repository.getPending();

  Future<List<Bill>> getDueSoon({int days = 7}) =>
      _repository.getDueSoon(days: days);

  Stream<List<Bill>> watchPending() => _repository.watchPending();

  Stream<List<Bill>> watchAll() => _repository.watchAll();
}
