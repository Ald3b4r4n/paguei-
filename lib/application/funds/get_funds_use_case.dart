import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';

final class GetFundsUseCase {
  const GetFundsUseCase(this._repository);

  final FundRepository _repository;

  Future<List<Fund>> execute() => _repository.getAll();

  Stream<List<Fund>> watch() => _repository.watchAll();
}
