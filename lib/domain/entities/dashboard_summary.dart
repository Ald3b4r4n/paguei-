import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

/// Lightweight snapshot of a bill for dashboard display.
final class BillSummary {
  const BillSummary({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.effectiveStatus,
  });

  final String id;
  final String title;
  final Money amount;
  final DateTime dueDate;
  final BillStatus effectiveStatus;
}

/// Spending amount for a single category in the current month.
final class SpendingTrend {
  const SpendingTrend({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    this.categoryId,
  });

  final String? categoryId;
  final String categoryName;
  final Money amount;

  /// Share of total monthly expenses (0.0 – 1.0).
  final double percentage;
}

/// Aggregated financial snapshot shown on the Dashboard.
final class DashboardSummary {
  const DashboardSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.pendingBillsTotal,
    required this.overdueBillsTotal,
    required this.overdueBillsCount,
    required this.fundsTotal,
    required this.debtsTotal,
    required this.upcomingBills,
    required this.spendingTrends,
    required this.previousMonthIncome,
    required this.previousMonthExpense,
    required this.month,
  });

  /// Sum of `currentBalanceCents` across all non-archived accounts.
  final Money totalBalance;

  /// Total income transactions in [month].
  final Money monthlyIncome;

  /// Total expense transactions in [month].
  final Money monthlyExpense;

  /// Net result: monthlyIncome − monthlyExpense.
  Money get netResult => monthlyIncome - monthlyExpense;

  /// Sum of all pending (and overdue) bill amounts.
  final Money pendingBillsTotal;

  /// Sum of bills that are already past their due date.
  final Money overdueBillsTotal;

  final int overdueBillsCount;

  bool get hasOverdueBills => overdueBillsCount > 0;

  /// Sum of `currentAmount` across all savings funds.
  final Money fundsTotal;

  /// Sum of `remainingAmount` across all active debts.
  final Money debtsTotal;

  /// Bills due within the next 7 days, sorted by dueDate.
  final List<BillSummary> upcomingBills;

  /// Top spending categories this month, sorted by amount descending.
  final List<SpendingTrend> spendingTrends;

  /// Previous month income — for % change indicator.
  final Money previousMonthIncome;

  /// Previous month expense — for % change indicator.
  final Money previousMonthExpense;

  /// The month this summary covers.
  final DateTime month;

  /// Net worth: total balance minus total debt.
  Money get netWorth => totalBalance - debtsTotal;

  /// Income growth vs previous month (null if no prev data).
  double? get incomeGrowthRate {
    if (previousMonthIncome.isZero) return null;
    return (monthlyIncome - previousMonthIncome).amount /
        previousMonthIncome.amount;
  }

  /// Expense growth vs previous month (null if no prev data).
  double? get expenseGrowthRate {
    if (previousMonthExpense.isZero) return null;
    return (monthlyExpense - previousMonthExpense).amount /
        previousMonthExpense.amount;
  }

  DashboardSummary copyWith({
    Money? totalBalance,
    Money? monthlyIncome,
    Money? monthlyExpense,
    Money? pendingBillsTotal,
    Money? overdueBillsTotal,
    int? overdueBillsCount,
    Money? fundsTotal,
    Money? debtsTotal,
    List<BillSummary>? upcomingBills,
    List<SpendingTrend>? spendingTrends,
    Money? previousMonthIncome,
    Money? previousMonthExpense,
    DateTime? month,
  }) {
    return DashboardSummary(
      totalBalance: totalBalance ?? this.totalBalance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      pendingBillsTotal: pendingBillsTotal ?? this.pendingBillsTotal,
      overdueBillsTotal: overdueBillsTotal ?? this.overdueBillsTotal,
      overdueBillsCount: overdueBillsCount ?? this.overdueBillsCount,
      fundsTotal: fundsTotal ?? this.fundsTotal,
      debtsTotal: debtsTotal ?? this.debtsTotal,
      upcomingBills: upcomingBills ?? this.upcomingBills,
      spendingTrends: spendingTrends ?? this.spendingTrends,
      previousMonthIncome: previousMonthIncome ?? this.previousMonthIncome,
      previousMonthExpense: previousMonthExpense ?? this.previousMonthExpense,
      month: month ?? this.month,
    );
  }
}
