import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:paguei/data/database/app_database.dart';

AppDatabase buildInMemoryDatabase() => AppDatabase(NativeDatabase.memory());

extension AppDatabaseTestExtension on AppDatabase {
  Future<void> seedTestAccount({
    String id = 'test-account-1',
    String name = 'Conta Teste',
    String type = 'checking',
    double currentBalance = 1000.0,
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async {
    final now = DateTime.now().toUtc();
    await into(accountsTable).insert(
      AccountsTableCompanion.insert(
        id: id,
        name: name,
        type: type,
        color: Value(color),
        icon: Value(icon),
        createdAt: now,
        updatedAt: now,
        currentBalanceCents: Value((currentBalance * 100).round()),
      ),
    );
  }

  Future<void> seedTestCategory({
    String id = 'test-category-1',
    String name = 'Alimentação',
    String type = 'expense',
    String icon = 'food',
    int color = 0xFF4CAF50,
  }) async {
    final now = DateTime.now().toUtc();
    await into(categoriesTable).insert(
      CategoriesTableCompanion.insert(
        id: id,
        name: name,
        type: type,
        icon: icon,
        color: color,
        createdAt: now,
      ),
    );
  }

  Future<void> seedTestBill({
    String id = 'test-bill-1',
    String title = 'Conta de Luz',
    double amount = 120.0,
    DateTime? dueDate,
    String status = 'pending',
    String? accountId,
  }) async {
    final now = DateTime.now().toUtc();
    await into(billsTable).insert(
      BillsTableCompanion.insert(
        id: id,
        title: title,
        amount: amount,
        dueDate: dueDate ?? now.add(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
        accountId: Value(accountId),
        status: Value(status),
      ),
    );
  }

  Future<void> seedTestTransaction({
    String id = 'test-transaction-1',
    String accountId = 'test-account-1',
    String type = 'expense',
    double amount = 50.0,
    String description = 'Transação Teste',
    DateTime? date,
  }) async {
    final now = DateTime.now().toUtc();
    await into(transactionsTable).insert(
      TransactionsTableCompanion.insert(
        id: id,
        accountId: accountId,
        type: type,
        amount: amount,
        description: description,
        date: date ?? now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
