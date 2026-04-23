import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class FakeFundRepository implements FundRepository {
  final _store = <String, Fund>{};

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
    _store[id] = fund;
    return fund;
  }

  @override
  Future<List<Fund>> getAll() async => _store.values.toList();

  @override
  Future<Fund?> getById(String id) async => _store[id];

  @override
  Stream<List<Fund>> watchAll() => Stream.value(_store.values.toList());

  @override
  Future<Fund> update(Fund fund) async {
    _store[fund.id] = fund;
    return fund;
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
