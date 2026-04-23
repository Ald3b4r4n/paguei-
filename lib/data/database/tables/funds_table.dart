import 'package:drift/drift.dart';

@TableIndex(name: 'idx_funds_type', columns: {#type})
@TableIndex(name: 'idx_funds_completed', columns: {#isCompleted})
class FundsTable extends Table {
  @override
  String get tableName => 'funds';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // emergency | goal | savings
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_debts_status', columns: {#status})
@TableIndex(name: 'idx_debts_start_date', columns: {#startDate})
class DebtsTable extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get creditorName => text().withLength(min: 1, max: 150)();
  RealColumn get totalAmount => real()();
  RealColumn get remainingAmount => real()();
  IntColumn get installments => integer().nullable()();
  IntColumn get installmentsPaid => integer().withDefault(const Constant(0))();
  RealColumn get installmentAmount => real().nullable()();
  RealColumn get interestRate => real().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get expectedEndDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
