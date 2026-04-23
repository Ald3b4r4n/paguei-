import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class GetMonthlyTransactionsUseCase {
  const GetMonthlyTransactionsUseCase(this._repository);

  final TransactionRepository _repository;

  Future<List<Transaction>> execute({required int year, required int month}) =>
      _repository.getByMonth(year: year, month: month);

  Stream<List<Transaction>> watch({required int year, required int month}) =>
      _repository.watchByMonth(year: year, month: month);

  Future<Money> getSummary({
    required int year,
    required int month,
    TransactionType? type,
    String? accountId,
  }) =>
      _repository.getMonthlySummary(
        year: year,
        month: month,
        type: type,
        accountId: accountId,
      );
}
