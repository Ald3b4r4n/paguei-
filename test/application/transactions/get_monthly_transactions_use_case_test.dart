import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'create_transaction_use_case_test.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
    repository.accountBalances['acc-1'] = 0;
  });

  group('GetMonthlyTransactionsUseCase behavior', () {
    test('retorna apenas transações do mês solicitado', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(5000),
        description: 'Café abril',
        date: DateTime.utc(2026, 4, 15),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(10000),
        description: 'Compra março',
        date: DateTime.utc(2026, 3, 20),
      );

      final april = await repository.getByMonth(year: 2026, month: 4);
      expect(april.length, equals(1));
      expect(april.first.id, equals('txn-1'));
    });

    test('retorna lista vazia para mês sem transações', () async {
      final txns = await repository.getByMonth(year: 2026, month: 5);
      expect(txns, isEmpty);
    });

    test('getMonthlySummary calcula income corretamente', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(300000), // R$ 3.000,00
        description: 'Salário',
        date: DateTime.utc(2026, 4, 1),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(50000), // R$ 500,00
        description: 'Freelance',
        date: DateTime.utc(2026, 4, 15),
      );

      final total = await repository.getMonthlySummary(
        year: 2026,
        month: 4,
        type: TransactionType.income,
      );
      expect(total, equals(Money(350000))); // R$ 3.500,00
    });

    test('getMonthlySummary calcula expense corretamente', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(15000),
        description: 'Mercado',
        date: DateTime.utc(2026, 4, 10),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(8000),
        description: 'Transporte',
        date: DateTime.utc(2026, 4, 12),
      );

      final total = await repository.getMonthlySummary(
        year: 2026,
        month: 4,
        type: TransactionType.expense,
      );
      expect(total, equals(Money(23000)));
    });

    test('getMonthlySummary sem tipo retorna resultado líquido', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(500000),
        description: 'Salário',
        date: DateTime.utc(2026, 4, 1),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(150000),
        description: 'Despesas',
        date: DateTime.utc(2026, 4, 15),
      );

      final net = await repository.getMonthlySummary(year: 2026, month: 4);
      expect(net, equals(Money(350000))); // 500000 - 150000
    });

    test('getMonthlySummary com accountId filtra por conta', () async {
      repository.accountBalances['acc-2'] = 0;

      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(10000),
        description: 'Acc1',
        date: DateTime.utc(2026, 4, 1),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-2',
        type: TransactionType.expense,
        amount: Money(20000),
        description: 'Acc2',
        date: DateTime.utc(2026, 4, 2),
      );

      final acc1Summary = await repository.getMonthlySummary(
        year: 2026,
        month: 4,
        type: TransactionType.expense,
        accountId: 'acc-1',
      );
      expect(acc1Summary, equals(Money(10000)));
    });

    test('transferência não afeta summary de income/expense', () async {
      await repository.create(
        id: 'txn-transfer',
        accountId: 'acc-1',
        type: TransactionType.transfer,
        amount: Money(50000),
        description: 'Transferência',
        date: DateTime.utc(2026, 4, 5),
      );

      final income = await repository.getMonthlySummary(
        year: 2026,
        month: 4,
        type: TransactionType.income,
      );
      final expense = await repository.getMonthlySummary(
        year: 2026,
        month: 4,
        type: TransactionType.expense,
      );

      expect(income, equals(Money.zero));
      expect(expense, equals(Money.zero));
    });
  });

  group('TransferBetweenAccountsUseCase behavior', () {
    setUp(() {
      repository.accountBalances['acc-2'] = 50000; // R$ 500,00
    });

    test('transfer debita conta de origem e credita destino', () async {
      await repository.createTransfer(
        id: 'txn-transfer-1',
        fromAccountId: 'acc-1',
        toAccountId: 'acc-2',
        amount: Money(30000), // R$ 300,00
        description: 'Transferência',
        date: DateTime.utc(2026, 4, 1),
      );

      // acc-1: 0 - 300 = -300
      // acc-2: 500 + 300 = 800
      expect(repository.balanceFor('acc-1'), equals(Money(-30000)));
      expect(repository.balanceFor('acc-2'), equals(Money(80000)));
    });

    test('saldo total é conservado na transferência', () async {
      final acc1Before = repository.balanceFor('acc-1');
      final acc2Before = repository.balanceFor('acc-2');
      final totalBefore = acc1Before + acc2Before;

      await repository.createTransfer(
        id: 'txn-transfer-1',
        fromAccountId: 'acc-1',
        toAccountId: 'acc-2',
        amount: Money(20000),
        description: 'Transferência',
        date: DateTime.utc(2026, 4, 1),
      );

      final totalAfter =
          repository.balanceFor('acc-1') + repository.balanceFor('acc-2');
      expect(totalAfter, equals(totalBefore)); // money is conserved
    });
  });

  group('UpdateTransactionUseCase behavior', () {
    test('atualiza transação recalcula delta de saldo corretamente', () async {
      repository.accountBalances['acc-1'] = 100000;

      final txn = await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(10000), // R$ 100,00
        description: 'Original',
        date: DateTime.utc(2026, 4, 1),
      );

      // Balance: 100000 - 10000 = 90000
      expect(repository.balanceFor('acc-1'), equals(Money(90000)));

      // Update to R$ 30000 (R$ 300)
      final updated = txn.copyWith(amount: Money(30000));
      await repository.update(updated);

      // Balance: 90000 + 10000 (reversal) - 30000 (new) = 70000
      expect(repository.balanceFor('acc-1'), equals(Money(70000)));
    });
  });
}
