import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/dashboard_summary.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class GetDashboardSummaryUseCase {
  const GetDashboardSummaryUseCase({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
    required BillRepository billRepository,
    FundRepository? fundRepository,
    DebtRepository? debtRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository,
        _billRepository = billRepository,
        _fundRepository = fundRepository,
        _debtRepository = debtRepository;

  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;
  final BillRepository _billRepository;
  final FundRepository? _fundRepository;
  final DebtRepository? _debtRepository;

  Future<DashboardSummary> execute({required DateTime month}) async {
    final now = DateTime.now().toUtc();
    final prevMonth = DateTime(month.year, month.month - 1);

    // Run independent queries in parallel for performance.
    final results = await Future.wait<Object?>([
      _getTotalBalance(),
      _getMonthlyAmount(month, TransactionType.income),
      _getMonthlyAmount(month, TransactionType.expense),
      _getMonthlyAmount(prevMonth, TransactionType.income),
      _getMonthlyAmount(prevMonth, TransactionType.expense),
      _billRepository.getAll(),
      _getFundsTotal(),
      _getDebtsTotal(),
    ]);

    final totalBalance = results[0] as Money;
    final monthlyIncome = results[1] as Money;
    final monthlyExpense = results[2] as Money;
    final prevIncome = results[3] as Money;
    final prevExpense = results[4] as Money;
    final allBills = results[5] as List<Bill>;
    final fundsTotal = results[6] as Money;
    final debtsTotal = results[7] as Money;

    final pendingBillsTotal = allBills
        .where((b) => b.status == BillStatus.pending)
        .fold(Money.zero, (acc, b) => acc + b.amount);

    final overdueBills = allBills
        .where(
          (b) => b.status == BillStatus.pending && b.dueDate.isBefore(now),
        )
        .toList();
    final overdueBillsTotal =
        overdueBills.fold(Money.zero, (acc, b) => acc + b.amount);

    final sevenDaysCutoff = now.add(const Duration(days: 7));
    final upcomingBills = allBills
        .where(
          (b) =>
              b.status == BillStatus.pending &&
              !b.dueDate.isBefore(now) &&
              !b.dueDate.isAfter(sevenDaysCutoff),
        )
        .map((b) => BillSummary(
              id: b.id,
              title: b.title,
              amount: b.amount,
              dueDate: b.dueDate,
              effectiveStatus: b.effectiveStatus,
            ))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return DashboardSummary(
      totalBalance: totalBalance,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      pendingBillsTotal: pendingBillsTotal,
      overdueBillsTotal: overdueBillsTotal,
      overdueBillsCount: overdueBills.length,
      fundsTotal: fundsTotal,
      debtsTotal: debtsTotal,
      upcomingBills: upcomingBills,
      spendingTrends: const [],
      previousMonthIncome: prevIncome,
      previousMonthExpense: prevExpense,
      month: month,
    );
  }

  Future<DashboardSummary> executeForCurrentMonth() {
    final now = DateTime.now();
    return execute(month: DateTime(now.year, now.month));
  }

  Future<Money> _getTotalBalance() async {
    final accounts = await _accountRepository.getAll();
    return accounts.fold<Money>(Money.zero, (acc, a) => acc + a.currentBalance);
  }

  Future<Money> _getMonthlyAmount(DateTime month, TransactionType type) {
    return _transactionRepository.getMonthlySummary(
      year: month.year,
      month: month.month,
      type: type,
    );
  }

  Future<Money> _getFundsTotal() async {
    final repository = _fundRepository;
    if (repository == null) return Money.zero;
    final funds = await repository.getAll();
    return funds.fold<Money>(
      Money.zero,
      (sum, fund) => sum + fund.currentAmount,
    );
  }

  Future<Money> _getDebtsTotal() async {
    final repository = _debtRepository;
    if (repository == null) return Money.zero;
    final debts = await repository.getAll(status: DebtStatus.active);
    return debts.fold<Money>(
      Money.zero,
      (sum, debt) => sum + debt.remainingAmount,
    );
  }
}
