import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class FakeDebtRepository implements DebtRepository {
  final _store = <String, Debt>{};

  @override
  Future<Debt> create({
    required String id,
    required String creditorName,
    required Money totalAmount,
    int? installments,
    Money? installmentAmount,
    double? interestRate,
    DateTime? expectedEndDate,
    String? notes,
  }) async {
    final debt = Debt.create(
      id: id,
      creditorName: creditorName,
      totalAmount: totalAmount,
      installments: installments,
      installmentAmount: installmentAmount,
      interestRate: interestRate,
      expectedEndDate: expectedEndDate,
      notes: notes,
    );
    _store[id] = debt;
    return debt;
  }

  @override
  Future<List<Debt>> getAll({DebtStatus? status}) async {
    return _store.values
        .where((d) => status == null || d.status == status)
        .toList();
  }

  @override
  Future<Debt?> getById(String id) async => _store[id];

  @override
  Stream<List<Debt>> watchAll({DebtStatus? status}) => Stream.value(
        _store.values
            .where((d) => status == null || d.status == status)
            .toList(),
      );

  @override
  Future<Debt> update(Debt debt) async {
    _store[debt.id] = debt;
    return debt;
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
