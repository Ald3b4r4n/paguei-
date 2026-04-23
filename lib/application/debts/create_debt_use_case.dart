import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:uuid/uuid.dart';

final class CreateDebtUseCase {
  const CreateDebtUseCase(this._repository);

  final DebtRepository _repository;

  Future<Debt> execute({
    required String creditorName,
    required Money totalAmount,
    int? installments,
    Money? installmentAmount,
    double? interestRate,
    DateTime? expectedEndDate,
    String? notes,
  }) {
    return _repository.create(
      id: const Uuid().v4(),
      creditorName: creditorName,
      totalAmount: totalAmount,
      installments: installments,
      installmentAmount: installmentAmount,
      interestRate: interestRate,
      expectedEndDate: expectedEndDate,
      notes: notes,
    );
  }
}
