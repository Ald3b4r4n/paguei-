import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'transactions_table.dart';

class TransfersTable extends Table {
  @override
  String get tableName => 'transfers';

  TextColumn get id => text()();
  TextColumn get fromAccountId => text().references(AccountsTable, #id)();
  TextColumn get toAccountId => text().references(AccountsTable, #id)();
  TextColumn get transactionId => text().references(TransactionsTable, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class NotificationLogsTable extends Table {
  @override
  String get tableName => 'notification_logs';

  TextColumn get id => text()();
  TextColumn get type =>
      text()(); // bill_due | overdue | budget_exceeded | reminder
  TextColumn get referenceId => text()();
  TextColumn get referenceType => text()(); // bill | subscription | budget
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
