import 'package:drift/drift.dart';

import 'categories_table.dart';

class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  TextColumn get billingCycle =>
      text().withDefault(const Constant('monthly'))();
  DateTimeColumn get nextBillingDate => dateTime()();
  TextColumn get categoryId =>
      text().nullable().references(CategoriesTable, #id)();
  IntColumn get color => integer()();
  TextColumn get icon => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(3))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetLimitsTable extends Table {
  @override
  String get tableName => 'budget_limits';

  TextColumn get id => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();
  RealColumn get limitAmount => real()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get alertThreshold => real().withDefault(const Constant(0.8))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month, year},
      ];
}
