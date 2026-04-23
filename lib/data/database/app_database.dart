import 'package:drift/drift.dart';

import 'tables/accounts_table.dart';
import 'tables/bills_table.dart';
import 'tables/categories_table.dart';
import 'tables/funds_table.dart';
import 'tables/subscriptions_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transfers_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AccountsTable,
    CategoriesTable,
    TransactionsTable,
    BillsTable,
    FundsTable,
    DebtsTable,
    SubscriptionsTable,
    BudgetLimitsTable,
    TransfersTable,
    NotificationLogsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          for (var version = from + 1; version <= to; version++) {
            await _runMigration(m, version);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );

  Future<void> _runMigration(Migrator m, int version) async {
    switch (version) {
      // Futuras migrações serão adicionadas aqui como:
      // case 2: await m.addColumn(table, column); break;
      default:
        break;
    }
  }

  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now().toUtc();
    final defaultCategories = _buildDefaultCategories(now);

    for (final category in defaultCategories) {
      await into(categoriesTable).insert(category);
    }
  }

  List<CategoriesTableCompanion> _buildDefaultCategories(DateTime now) => [
        _expenseCategory('cat_food', 'Alimentação', 0xFF4CAF50, 'food', now),
        _expenseCategory(
          'cat_transport',
          'Transporte',
          0xFF2196F3,
          'transport',
          now,
        ),
        _expenseCategory(
          'cat_housing',
          'Moradia',
          0xFF795548,
          'housing',
          now,
        ),
        _expenseCategory('cat_health', 'Saúde', 0xFFE91E63, 'health', now),
        _expenseCategory(
          'cat_education',
          'Educação',
          0xFF9C27B0,
          'education',
          now,
        ),
        _expenseCategory(
          'cat_leisure',
          'Lazer',
          0xFFFF9800,
          'leisure',
          now,
        ),
        _expenseCategory(
          'cat_clothing',
          'Vestuário',
          0xFF00BCD4,
          'clothing',
          now,
        ),
        _expenseCategory(
          'cat_subscriptions',
          'Assinaturas',
          0xFF673AB7,
          'subscriptions',
          now,
        ),
        _expenseCategory('cat_taxes', 'Impostos', 0xFF607D8B, 'taxes', now),
        _expenseCategory('cat_other_exp', 'Outros', 0xFF9E9E9E, 'other', now),
        _incomeCategory(
          'cat_salary',
          'Salário',
          0xFF1B4332,
          'salary',
          now,
        ),
        _incomeCategory(
          'cat_freelance',
          'Freelance',
          0xFF52B788,
          'freelance',
          now,
        ),
        _incomeCategory(
          'cat_investments',
          'Investimentos',
          0xFF2D6A4F,
          'investments',
          now,
        ),
        _incomeCategory(
          'cat_other_inc',
          'Outros',
          0xFF74C69D,
          'other',
          now,
        ),
      ];

  CategoriesTableCompanion _expenseCategory(
    String id,
    String name,
    int color,
    String icon,
    DateTime now,
  ) =>
      CategoriesTableCompanion.insert(
        id: id,
        name: name,
        type: 'expense',
        icon: icon,
        color: color,
        isDefault: const Value(true),
        createdAt: now,
      );

  CategoriesTableCompanion _incomeCategory(
    String id,
    String name,
    int color,
    String icon,
    DateTime now,
  ) =>
      CategoriesTableCompanion.insert(
        id: id,
        name: name,
        type: 'income',
        icon: icon,
        color: color,
        isDefault: const Value(true),
        createdAt: now,
      );
}
