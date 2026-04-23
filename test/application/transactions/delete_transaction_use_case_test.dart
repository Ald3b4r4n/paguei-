import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'create_transaction_use_case_test.dart';

void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
    repository.accountBalances['acc-1'] = 100000; // R$ 1.000,00
  });

  group('DeleteTransactionUseCase behavior', () {
    test('deletar expense restaura saldo (rollback)', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(30000), // R$ 300,00
        description: 'Compra',
        date: DateTime.utc(2026, 4, 1),
      );
      expect(repository.balanceFor('acc-1'), equals(Money(70000)));

      await repository.delete('txn-1');
      expect(repository.balanceFor('acc-1'), equals(Money(100000))); // restored
    });

    test('deletar income restaura saldo', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(50000),
        description: 'Salário extra',
        date: DateTime.utc(2026, 4, 1),
      );
      expect(repository.balanceFor('acc-1'), equals(Money(150000)));

      await repository.delete('txn-1');
      expect(repository.balanceFor('acc-1'), equals(Money(100000)));
    });

    test('deletar transação remove do repositório', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(1000),
        description: 'Café',
        date: DateTime.utc(2026, 4, 1),
      );

      await repository.delete('txn-1');

      final txn = await repository.getById('txn-1');
      expect(txn, isNull);
    });

    test('deletar uma de várias transações preserva as demais', () async {
      await repository.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(10000),
        description: 'Compra 1',
        date: DateTime.utc(2026, 4, 1),
      );
      await repository.create(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(20000),
        description: 'Compra 2',
        date: DateTime.utc(2026, 4, 2),
      );

      await repository.delete('txn-1');

      final txns = await repository.getByMonth(year: 2026, month: 4);
      expect(txns.length, equals(1));
      expect(txns.first.id, equals('txn-2'));
      // 100000 - 20000 = 80000
      expect(repository.balanceFor('acc-1'), equals(Money(80000)));
    });
  });
}
