import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class RegisterDebtPaymentUseCase {
  const RegisterDebtPaymentUseCase(this._repository);

  final DebtRepository _repository;

  Future<Debt> execute({required String debtId, required Money amount}) async {
    final debt = await _repository.getById(debtId);
    if (debt == null) {
      throw ValidationException(message: 'Dívida não encontrada: $debtId');
    }
    final updated = debt.registerPayment(amount);
    return _repository.update(updated);
  }
}
