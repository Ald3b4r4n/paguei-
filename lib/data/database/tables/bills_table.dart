import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

@TableIndex(name: 'idx_bills_due_date', columns: {#dueDate})
@TableIndex(name: 'idx_bills_status', columns: {#status})
@TableIndex(name: 'idx_bills_account', columns: {#accountId})
@TableIndex(name: 'idx_bills_status_due', columns: {#status, #dueDate})
class BillsTable extends Table {
  @override
  String get tableName => 'bills';

  TextColumn get id => text()();
  TextColumn get accountId =>
      text().nullable().references(AccountsTable, #id)();
  TextColumn get categoryId =>
      text().nullable().references(CategoriesTable, #id)();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  RealColumn get amount => real()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get barcode => text().nullable()();
  TextColumn get pixCode => text().nullable()();
  TextColumn get beneficiary => text().nullable()();
  TextColumn get issuer => text().nullable()();
  TextColumn get documentType => text().nullable()(); // boleto | pix | other
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  DateTimeColumn get paidAt => dateTime().nullable()();
  RealColumn get paidAmount => real().nullable()();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(3))();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
