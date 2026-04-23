import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

abstract interface class FundRepository {
  Future<List<Fund>> getAll();

  Future<Fund?> getById(String id);

  Stream<List<Fund>> watchAll();

  Future<Fund> create({
    required String id,
    required String name,
    required FundType type,
    required Money targetAmount,
    int color,
    String icon,
    DateTime? targetDate,
    String? notes,
  });

  Future<Fund> update(Fund fund);

  Future<void> delete(String id);
}
