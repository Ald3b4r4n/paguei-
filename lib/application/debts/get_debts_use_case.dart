import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';

final class GetDebtsUseCase {
  const GetDebtsUseCase(this._repository);

  final DebtRepository _repository;

  Future<List<Debt>> execute({DebtStatus? status}) =>
      _repository.getAll(status: status);

  Stream<List<Debt>> watch({DebtStatus? status}) =>
      _repository.watchAll(status: status);
}
