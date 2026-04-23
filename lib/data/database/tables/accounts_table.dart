import 'package:drift/drift.dart';

/// Persists [Account] entities.
///
/// Balance is stored as integer centavos to avoid floating-point errors,
/// matching the [Money] value object strategy in the domain layer.
class AccountsTable extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// AccountType serialized as string: checking | savings | wallet | investment
  TextColumn get type => text()();

  /// Current balance in centavos (R$ 1,00 = 100).
  IntColumn get currentBalanceCents =>
      integer().withDefault(const Constant(0))();

  TextColumn get currency => text().withDefault(const Constant('BRL'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get color => integer().withDefault(const Constant(0xFF1B4332))();
  TextColumn get icon =>
      text().withDefault(const Constant('account_balance'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
