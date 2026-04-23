import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/accounts_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [AccountsTable])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<AccountsTableData>> getAll({bool includeArchived = false}) {
    final query = select(accountsTable);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.get();
  }

  Future<AccountsTableData?> getById(String id) {
    return (select(accountsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<AccountsTableData>> watchAll({bool includeArchived = false}) {
    final query = select(accountsTable);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<void> insertAccount(AccountsTableCompanion companion) {
    return into(accountsTable).insert(companion);
  }

  Future<bool> updateAccount(AccountsTableCompanion companion) {
    return update(accountsTable).replace(companion);
  }

  Future<int> archiveAccount(String id) {
    return (update(accountsTable)..where((t) => t.id.equals(id))).write(
      AccountsTableCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> unarchiveAccount(String id) {
    return (update(accountsTable)..where((t) => t.id.equals(id))).write(
      AccountsTableCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> deleteAccount(String id) {
    return (delete(accountsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> adjustBalanceCents(String id, int newBalanceCents) {
    return (update(accountsTable)..where((t) => t.id.equals(id))).write(
      AccountsTableCompanion(
        currentBalanceCents: Value(newBalanceCents),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
