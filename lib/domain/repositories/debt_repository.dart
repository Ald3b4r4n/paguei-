import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

abstract interface class DebtRepository {
  Future<List<Debt>> getAll({DebtStatus? status});

  Future<Debt?> getById(String id);

  Stream<List<Debt>> watchAll({DebtStatus? status});

  Future<Debt> create({
    required String id,
    required String creditorName,
    required Money totalAmount,
    int? installments,
    Money? installmentAmount,
    double? interestRate,
    DateTime? expectedEndDate,
    String? notes,
  });

  Future<Debt> update(Debt debt);

  Future<void> delete(String id);
}
