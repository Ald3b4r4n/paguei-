import 'package:drift/drift.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/tables/accounts_table.dart';
import 'package:paguei/data/database/tables/bills_table.dart';
import 'package:paguei/data/database/tables/categories_table.dart';
import 'package:paguei/data/database/tables/funds_table.dart';
import 'package:paguei/data/database/tables/transactions_table.dart';

part 'dashboard_dao.g.dart';

/// Aggregate result for a single category's monthly spending.
class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
  });

  final String categoryId;
  final String categoryName;
  final double totalAmount;
}

@DriftAccessor(tables: [
  AccountsTable,
  TransactionsTable,
  BillsTable,
  FundsTable,
  DebtsTable,
  CategoriesTable,
])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(super.db);

  // -------------------------------------------------------------------------
  // Accounts aggregate
  // -------------------------------------------------------------------------

  /// Returns sum of `currentBalanceCents` for all non-archived accounts.
  Future<int> getTotalBalanceCents() async {
    final sumExpr = accountsTable.currentBalanceCents.sum();
    final query = selectOnly(accountsTable)
      ..addColumns([sumExpr])
      ..where(accountsTable.isArchived.equals(false));
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0;
  }

  // -------------------------------------------------------------------------
  // Transactions aggregates
  // -------------------------------------------------------------------------

  Future<double> _sumTransactionsByType({
    required int year,
    required int month,
    required String type,
  }) async {
    final start = DateTime(year, month).toUtc();
    final end = DateTime(year, month + 1).toUtc();
    final sumExpr = transactionsTable.amount.sum();
    final query = selectOnly(transactionsTable)
      ..addColumns([sumExpr])
      ..where(
        transactionsTable.type.equals(type) &
            transactionsTable.date.isBiggerOrEqualValue(start) &
            transactionsTable.date.isSmallerThanValue(end),
      );
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  Future<double> getMonthlyIncome({required int year, required int month}) =>
      _sumTransactionsByType(year: year, month: month, type: 'income');

  Future<double> getMonthlyExpense({required int year, required int month}) =>
      _sumTransactionsByType(year: year, month: month, type: 'expense');

  // -------------------------------------------------------------------------
  // Bills aggregates
  // -------------------------------------------------------------------------

  Future<double> getPendingBillsTotal() async {
    final sumExpr = billsTable.amount.sum();
    final query = selectOnly(billsTable)
      ..addColumns([sumExpr])
      ..where(billsTable.status.equals('pending'));
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  Future<(double total, int count)> getOverdueBillsAggregate(
      DateTime now) async {
    final sumExpr = billsTable.amount.sum();
    final countExpr = billsTable.id.count();
    final query = selectOnly(billsTable)
      ..addColumns([sumExpr, countExpr])
      ..where(
        billsTable.status.equals('pending') &
            billsTable.dueDate.isSmallerThanValue(now),
      );
    final row = await query.getSingleOrNull();
    final total = row?.read(sumExpr) ?? 0.0;
    final count = row?.read(countExpr) ?? 0;
    return (total, count);
  }

  /// Returns bills due between [now] and [now + days days], ordered by dueDate.
  Future<List<BillsTableData>> getUpcomingBills(
      {required DateTime now, required int days}) {
    final cutoff = now.add(Duration(days: days));
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

  // -------------------------------------------------------------------------
  // Funds aggregate
  // -------------------------------------------------------------------------

  Future<double> getFundsTotal() async {
    final sumExpr = fundsTable.currentAmount.sum();
    final query = selectOnly(fundsTable)..addColumns([sumExpr]);
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  // -------------------------------------------------------------------------
  // Debts aggregate
  // -------------------------------------------------------------------------

  Future<double> getDebtsTotal() async {
    final sumExpr = debtsTable.remainingAmount.sum();
    final query = selectOnly(debtsTable)
      ..addColumns([sumExpr])
      ..where(debtsTable.status.equals('active'));
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0.0;
  }

  // -------------------------------------------------------------------------
  // Category spending breakdown
  // -------------------------------------------------------------------------

  /// Returns top spending categories for [month] in [year], ordered by amount desc.
  Future<List<CategorySpending>> getSpendingByCategory({
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month).toUtc();
    final end = DateTime(year, month + 1).toUtc();

    final sumExpr = transactionsTable.amount.sum();
    final catId = categoriesTable.id;
    final catName = categoriesTable.name;

    final query = select(transactionsTable).join([
      innerJoin(
        categoriesTable,
        categoriesTable.id.equalsExp(transactionsTable.categoryId),
      ),
    ])
      ..addColumns([sumExpr])
      ..where(
        transactionsTable.type.equals('expense') &
            transactionsTable.date.isBiggerOrEqualValue(start) &
            transactionsTable.date.isSmallerThanValue(end) &
            transactionsTable.categoryId.isNotNull(),
      )
      ..groupBy([catId])
      ..orderBy([OrderingTerm.desc(sumExpr)]);

    final rows = await query.get();
    return rows.map((row) {
      return CategorySpending(
        categoryId: row.read(catId)!,
        categoryName: row.read(catName)!,
        totalAmount: row.read(sumExpr) ?? 0.0,
      );
    }).toList();
  }
}
