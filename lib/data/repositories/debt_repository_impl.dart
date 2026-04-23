import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/daos/debts_dao.dart';
import 'package:paguei/data/models/debt_model.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl(this._dao);

  final DebtsDao _dao;

  @override
  Future<List<Debt>> getAll({DebtStatus? status}) async {
    final rows = await _dao.getAll(status: status?.name);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Debt?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<List<Debt>> watchAll({DebtStatus? status}) {
    return _dao
        .watchAll(status: status?.name)
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

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
    await _dao.insertDebt(debt.toCompanion());
    return debt;
  }

  @override
  Future<Debt> update(Debt debt) async {
    final exists = await _dao.getById(debt.id);
    if (exists == null) {
      throw NotFoundException(message: 'Dívida não encontrada: ${debt.id}');
    }
    await _dao.updateDebt(debt.toCompanion());
    return debt;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteDebt(id);
  }
}
