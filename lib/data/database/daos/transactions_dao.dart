import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<TransactionsTableData?> getById(String id) {
    return (select(transactionsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<TransactionsTableData>> getByMonth({
    required int year,
    required int month,
  }) {
    final start = DateTime.utc(year, month);
    final end = DateTime.utc(year, month + 1);
    return (select(transactionsTable)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<TransactionsTableData>> watchByMonth({
    required int year,
    required int month,
  }) {
    final start = DateTime.utc(year, month);
    final end = DateTime.utc(year, month + 1);
    return (select(transactionsTable)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<TransactionsTableData>> getByAccount(String accountId) {
    return (select(transactionsTable)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<TransactionsTableData>> getByCategory(String categoryId) {
    return (select(transactionsTable)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<TransactionsTableData>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    return (select(transactionsTable)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startUtc) &
                t.date.isSmallerOrEqualValue(endUtc),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<List<TransactionsTableData>> getByType(String type) {
    return (select(transactionsTable)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Future<double> sumByType({
    required int year,
    required int month,
    required String type,
    String? accountId,
  }) async {
    final start = DateTime.utc(year, month);
    final end = DateTime.utc(year, month + 1);

    final sumExpr = transactionsTable.amount.sum();
    final query = selectOnly(transactionsTable)..addColumns([sumExpr]);
    query.where(
      transactionsTable.date.isBiggerOrEqualValue(start) &
          transactionsTable.date.isSmallerThanValue(end) &
          transactionsTable.type.equals(type),
    );
    if (accountId != null) {
      query.where(transactionsTable.accountId.equals(accountId));
    }

    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  Future<void> insertTransaction(TransactionsTableCompanion companion) {
    return into(transactionsTable).insert(companion);
  }

  Future<bool> updateTransaction(TransactionsTableCompanion companion) {
    return update(transactionsTable).replace(companion);
  }

  Future<int> deleteTransaction(String id) {
    return (delete(transactionsTable)..where((t) => t.id.equals(id))).go();
  }
}
