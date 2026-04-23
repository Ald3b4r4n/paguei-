import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  group('Schema v1 — criação de tabelas', () {
    test('tabela accounts existe e aceita inserção', () async {
      final now = DateTime.now().toUtc();
      await db.into(db.accountsTable).insert(
            AccountsTableCompanion.insert(
              id: 'acc-1',
              name: 'Nubank',
              type: 'checking',
              color: const Value(0xFF1B4332),
              icon: const Value('account_balance'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final rows = await db.select(db.accountsTable).get();
      expect(rows.length, equals(1));
      expect(rows.first.name, equals('Nubank'));
    });

    test('tabela bills existe e aceita inserção', () async {
      final now = DateTime.now().toUtc();
      await db.into(db.billsTable).insert(
            BillsTableCompanion.insert(
              id: 'bill-1',
              title: 'Conta de Energia',
              amount: 150.0,
              dueDate: now.add(const Duration(days: 5)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final rows = await db.select(db.billsTable).get();
      expect(rows.length, equals(1));
    });

    test('tabela categories é semeada com 14 categorias padrão', () async {
      final rows = await db.select(db.categoriesTable).get();
      expect(rows.length, equals(14));
    });

    test('categorias padrão incluem Alimentação e Salário', () async {
      final rows = await db.select(db.categoriesTable).get();
      final names = rows.map((r) => r.name).toList();
      expect(names, contains('Alimentação'));
      expect(names, contains('Salário'));
    });

    test('tabela funds existe', () async {
      final rows = await db.select(db.fundsTable).get();
      expect(rows, isEmpty);
    });

    test('tabela debts existe', () async {
      final rows = await db.select(db.debtsTable).get();
      expect(rows, isEmpty);
    });

    test('tabela subscriptions existe', () async {
      final rows = await db.select(db.subscriptionsTable).get();
      expect(rows, isEmpty);
    });

    test('tabela budget_limits existe', () async {
      final rows = await db.select(db.budgetLimitsTable).get();
      expect(rows, isEmpty);
    });

    test('tabela notification_logs existe', () async {
      final rows = await db.select(db.notificationLogsTable).get();
      expect(rows, isEmpty);
    });
  });

  group('Integridade referencial', () {
    test('bill com accountId inválido viola FK', () async {
      final now = DateTime.now().toUtc();
      await expectLater(
        db.into(db.billsTable).insert(
              BillsTableCompanion.insert(
                id: 'bill-fk',
                title: 'Boleto FK',
                amount: 100.0,
                dueDate: now,
                createdAt: now,
                updatedAt: now,
                accountId: const Value('conta-inexistente'),
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('Índices e constraints', () {
    test('budget_limits rejeita duplicata de categoryId + month + year',
        () async {
      final now = DateTime.now().toUtc();

      // Criar categoria primeiro
      await db.into(db.categoriesTable).insert(
            CategoriesTableCompanion.insert(
              id: 'cat-budget',
              name: 'Alimentação Teste',
              type: 'expense',
              icon: 'food',
              color: 0xFF4CAF50,
              createdAt: now,
            ),
          );

      await db.into(db.budgetLimitsTable).insert(
            BudgetLimitsTableCompanion.insert(
              id: 'bl-1',
              categoryId: 'cat-budget',
              limitAmount: 500.0,
              month: 4,
              year: 2026,
              createdAt: now,
            ),
          );

      await expectLater(
        db.into(db.budgetLimitsTable).insert(
              BudgetLimitsTableCompanion.insert(
                id: 'bl-2',
                categoryId: 'cat-budget',
                limitAmount: 600.0,
                month: 4,
                year: 2026,
                createdAt: now,
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('MigrationStrategy — schemaVersion', () {
    test('schemaVersion é 1', () {
      expect(db.schemaVersion, equals(1));
    });

    test('PRAGMA foreign_keys está ativo', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').get();
      expect(result.first.read<int>('foreign_keys'), equals(1));
    });
  });
}
