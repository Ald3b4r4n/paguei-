import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class ContributeFundUseCase {
  const ContributeFundUseCase(this._repository);

  final FundRepository _repository;

  Future<Fund> execute({required String fundId, required Money amount}) async {
    final fund = await _repository.getById(fundId);
    if (fund == null) {
      throw ValidationException(message: 'Fundo não encontrado: $fundId');
    }
    final updated = fund.contribute(amount);
    return _repository.update(updated);
  }
}
