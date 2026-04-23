import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/daos/funds_dao.dart';
import 'package:paguei/data/models/fund_model.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class FundRepositoryImpl implements FundRepository {
  const FundRepositoryImpl(this._dao);

  final FundsDao _dao;

  @override
  Future<List<Fund>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Fund?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<List<Fund>> watchAll() {
    return _dao
        .watchAll()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Fund> create({
    required String id,
    required String name,
    required FundType type,
    required Money targetAmount,
    int color = 0xFF1B4332,
    String icon = 'savings',
    DateTime? targetDate,
    String? notes,
  }) async {
    final fund = Fund.create(
      id: id,
      name: name,
      type: type,
      targetAmount: targetAmount,
      color: color,
      icon: icon,
      targetDate: targetDate,
      notes: notes,
    );
    await _dao.insertFund(fund.toCompanion());
    return fund;
  }

  @override
  Future<Fund> update(Fund fund) async {
    final exists = await _dao.getById(fund.id);
    if (exists == null) {
      throw NotFoundException(message: 'Fundo não encontrado: ${fund.id}');
    }
    await _dao.updateFund(fund.toCompanion());
    return fund;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteFund(id);
  }
}
