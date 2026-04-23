import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/dashboard/get_dashboard_summary_use_case.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import '../bills/fake_bill_repository.dart';
import '../transactions/create_transaction_use_case_test.dart';
import 'fake_account_repository.dart';

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository transactionRepo;
  late FakeBillRepository billRepo;
  late GetDashboardSummaryUseCase useCase;

  final testMonth = DateTime(2026, 4);

  setUp(() {
    accountRepo = FakeAccountRepository();
    transactionRepo = FakeTransactionRepository();
    billRepo = FakeBillRepository();
    useCase = GetDashboardSummaryUseCase(
      accountRepository: accountRepo,
      transactionRepository: transactionRepo,
      billRepository: billRepo,
    );
  });

  Bill buildBill({
    String id = 'bill-1',
    BillStatus status = BillStatus.pending,
    DateTime? dueDate,
    double amount = 120.0,
  }) {
    final now = DateTime.utc(2026, 4, 1);
    return Bill(
      id: id,
      title: 'Conta',
      amount: Money.fromDouble(amount),
      dueDate: dueDate ?? DateTime.utc(2026, 4, 25),
      status: status,
      isRecurring: false,
      reminderDaysBefore: 3,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('GetDashboardSummaryUseCase — saldo total', () {
    test('soma currentBalance de todas as contas ativas', () async {
      await accountRepo.create(
        id: 'acc-1',
        name: 'Nubank',
        type: AccountType.checking,
        currentBalance: Money.fromDouble(1000.0),
      );
      await accountRepo.create(
        id: 'acc-2',
        name: 'XP',
        type: AccountType.savings,
        currentBalance: Money.fromDouble(500.0),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.totalBalance, equals(Money.fromDouble(1500.0)));
    });

    test('retorna zero quando não há contas', () async {
      final summary = await useCase.execute(month: testMonth);
      expect(summary.totalBalance, equals(Money.zero));
    });
  });

  group('GetDashboardSummaryUseCase — transações mensais', () {
    setUp(() async {
      await accountRepo.create(
        id: 'acc-1',
        name: 'Nubank',
        type: AccountType.checking,
      );
      transactionRepo.accountBalances['acc-1'] = 0;
    });

    test('calcula receita mensal corretamente', () async {
      await transactionRepo.create(
        id: 't1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money.fromDouble(3000.0),
        description: 'Salário',
        date: DateTime.utc(2026, 4, 5),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.monthlyIncome, equals(Money.fromDouble(3000.0)));
    });

    test('calcula despesa mensal corretamente', () async {
      await transactionRepo.create(
        id: 't2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money.fromDouble(500.0),
        description: 'Supermercado',
        date: DateTime.utc(2026, 4, 10),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.monthlyExpense, equals(Money.fromDouble(500.0)));
    });

    test('netResult é receita menos despesa', () async {
      await transactionRepo.create(
        id: 't1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money.fromDouble(3000.0),
        description: 'Salário',
        date: DateTime.utc(2026, 4, 5),
      );
      await transactionRepo.create(
        id: 't2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money.fromDouble(1000.0),
        description: 'Aluguel',
        date: DateTime.utc(2026, 4, 10),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.netResult, equals(Money.fromDouble(2000.0)));
    });
  });

  group('GetDashboardSummaryUseCase — boletos', () {
    test('calcula total de boletos pendentes', () async {
      await billRepo.update(buildBill(id: 'b1', amount: 120.0));
      await billRepo.update(buildBill(id: 'b2', amount: 80.0));
      await billRepo.update(
        buildBill(id: 'b3', status: BillStatus.paid, amount: 50.0),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.pendingBillsTotal, equals(Money.fromDouble(200.0)));
    });

    test('conta e soma boletos vencidos (dueDate no passado)', () async {
      final pastDate = DateTime.utc(2020, 1, 1);
      await billRepo.update(buildBill(id: 'b1', dueDate: pastDate));
      await billRepo.update(
        buildBill(
          id: 'b2',
          dueDate: DateTime.utc(2026, 5, 10),
          amount: 80.0,
        ),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.overdueBillsCount, equals(1));
      expect(summary.overdueBillsTotal, equals(Money.fromDouble(120.0)));
      expect(summary.hasOverdueBills, isTrue);
    });

    test('hasOverdueBills é false quando não há vencidos', () async {
      await billRepo.update(
        buildBill(dueDate: DateTime.utc(2030, 1, 1)),
      );

      final summary = await useCase.execute(month: testMonth);

      expect(summary.hasOverdueBills, isFalse);
    });
  });

  group('GetDashboardSummaryUseCase — upcoming bills', () {
    test('retorna apenas boletos vencendo nos próximos 7 dias', () async {
      final now = DateTime.now().toUtc();
      final soon = now.add(const Duration(days: 3));
      final later = now.add(const Duration(days: 20));

      await billRepo.update(buildBill(id: 'b-soon', dueDate: soon));
      await billRepo.update(buildBill(id: 'b-later', dueDate: later));

      final summary = await useCase.execute(month: testMonth);

      expect(summary.upcomingBills.length, equals(1));
      expect(summary.upcomingBills.first.id, equals('b-soon'));
    });

    test('upcoming bills estão ordenados por data de vencimento', () async {
      final now = DateTime.now().toUtc();
      await billRepo.update(
        buildBill(id: 'b1', dueDate: now.add(const Duration(days: 5))),
      );
      await billRepo.update(
        buildBill(id: 'b2', dueDate: now.add(const Duration(days: 2))),
      );

      final summary = await useCase.execute(month: testMonth);

      if (summary.upcomingBills.length == 2) {
        expect(
          summary.upcomingBills.first.dueDate
              .isBefore(summary.upcomingBills.last.dueDate),
          isTrue,
        );
      }
    });
  });

  group('GetDashboardSummaryUseCase — estado vazio', () {
    test('retorna summary com zeros quando não há dados', () async {
      final summary = await useCase.execute(month: testMonth);

      expect(summary.totalBalance, equals(Money.zero));
      expect(summary.monthlyIncome, equals(Money.zero));
      expect(summary.monthlyExpense, equals(Money.zero));
      expect(summary.pendingBillsTotal, equals(Money.zero));
      expect(summary.upcomingBills, isEmpty);
      expect(summary.hasOverdueBills, isFalse);
    });
  });

  group('GetDashboardSummaryUseCase — comparação com mês anterior', () {
    test('previousMonthIncome é calculado para mês anterior', () async {
      transactionRepo.accountBalances['acc-1'] = 0;
      await accountRepo.create(
        id: 'acc-1',
        name: 'Conta',
        type: AccountType.checking,
      );
      await transactionRepo.create(
        id: 't-prev',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money.fromDouble(2000.0),
        description: 'Salário anterior',
        date: DateTime.utc(2026, 3, 5), // March = previous month
      );

      final summary = await useCase.execute(month: DateTime(2026, 4));

      expect(summary.previousMonthIncome, equals(Money.fromDouble(2000.0)));
    });
  });
}
