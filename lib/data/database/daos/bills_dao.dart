import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/bills_table.dart';

part 'bills_dao.g.dart';

@DriftAccessor(tables: [BillsTable])
class BillsDao extends DatabaseAccessor<AppDatabase> with _$BillsDaoMixin {
  BillsDao(super.db);

  Future<List<BillsTableData>> getAll() {
    return (select(billsTable)..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
        .get();
  }

  Future<BillsTableData?> getById(String id) {
    return (select(billsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<BillsTableData>> getByStatus(String status) {
    return (select(billsTable)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  /// Returns pending bills (status = 'pending'), ordered by due date ascending.
  Future<List<BillsTableData>> getPending() {
    return (select(billsTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  /// Returns overdue bills: pending bills whose due date is before [now].
  Future<List<BillsTableData>> getOverdue(DateTime now) {
    return (select(billsTable)
          ..where(
            (t) =>
                t.status.equals('pending') & t.dueDate.isSmallerThanValue(now),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  /// Returns pending bills due before [cutoff] date.
  Future<List<BillsTableData>> getDueSoon(DateTime now, DateTime cutoff) {
    return (select(billsTable)
          ..where(
            (t) =>
                t.status.equals('pending') &
                t.dueDate.isBiggerOrEqualValue(now) &
                t.dueDate.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }

  Stream<List<BillsTableData>> watchAll() {
    return (select(billsTable)..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Stream<List<BillsTableData>> watchPending() {
    return (select(billsTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Future<void> insertBill(BillsTableCompanion companion) {
    return into(billsTable).insert(companion);
  }

  Future<bool> updateBill(BillsTableCompanion companion) {
    return update(billsTable).replace(companion);
  }

  Future<int> deleteBill(String id) {
    return (delete(billsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateStatus(String id, String status) {
    return (update(billsTable)..where((t) => t.id.equals(id))).write(
      BillsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> markAsPaid(
    String id,
    double paidAmount,
    DateTime paidAt,
  ) {
    return (update(billsTable)..where((t) => t.id.equals(id))).write(
      BillsTableCompanion(
        status: const Value('paid'),
        paidAmount: Value(paidAmount),
        paidAt: Value(paidAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
