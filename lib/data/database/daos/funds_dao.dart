import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/funds_table.dart';

part 'funds_dao.g.dart';

@DriftAccessor(tables: [FundsTable])
class FundsDao extends DatabaseAccessor<AppDatabase> with _$FundsDaoMixin {
  FundsDao(super.db);

  Future<List<FundsTableData>> getAll() => select(fundsTable).get();

  Future<FundsTableData?> getById(String id) {
    return (select(fundsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<FundsTableData>> watchAll() => select(fundsTable).watch();

  Future<void> insertFund(FundsTableCompanion companion) {
    return into(fundsTable).insert(companion);
  }

  Future<bool> updateFund(FundsTableCompanion companion) {
    return update(fundsTable).replace(companion);
  }

  Future<int> deleteFund(String id) {
    return (delete(fundsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getTotalCurrentAmount() async {
    final sumExpr = fundsTable.currentAmount.sum();
    final query = selectOnly(fundsTable)..addColumns([sumExpr]);
    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0.0;
  }
}
