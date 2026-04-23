import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/funds_table.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [DebtsTable])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  Future<List<DebtsTableData>> getAll({String? status}) {
    final query = select(debtsTable);
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    return query.get();
  }

  Future<DebtsTableData?> getById(String id) {
    return (select(debtsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<DebtsTableData>> watchAll({String? status}) {
    final query = select(debtsTable);
    if (status != null) {
      query.where((t) => t.status.equals(status));
    }
    return query.watch();
  }

  Future<void> insertDebt(DebtsTableCompanion companion) {
    return into(debtsTable).insert(companion);
  }

  Future<bool> updateDebt(DebtsTableCompanion companion) {
    return update(debtsTable).replace(companion);
  }

  Future<int> deleteDebt(String id) {
    return (delete(debtsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getTotalRemainingAmount(
      {String statusFilter = 'active'}) async {
    final sumExpr = debtsTable.remainingAmount.sum();
    final query = selectOnly(debtsTable)
      ..addColumns([sumExpr])
      ..where(debtsTable.status.equals(statusFilter));
    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0.0;
  }
}
