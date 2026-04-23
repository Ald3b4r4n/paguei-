import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

Transaction buildTestTransaction({
  String id = 'txn-test-1',
  String accountId = 'acc-test-1',
  TransactionType type = TransactionType.expense,
  Money? amount,
  String description = 'Almoço',
  DateTime? date,
  String? categoryId = 'cat-food',
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    type: type,
    amount: amount ?? Money(5000), // R$ 50,00
    description: description,
    date: date ?? DateTime.utc(2026, 4, 19),
    categoryId: categoryId,
    isRecurring: false,
    createdAt: DateTime.utc(2026, 4, 19),
    updatedAt: DateTime.utc(2026, 4, 19),
  );
}

void main() {
  group('Transaction — criação válida', () {
    test('cria transação de despesa com campos mínimos', () {
      final txn = buildTestTransaction();

      expect(txn.id, equals('txn-test-1'));
      expect(txn.accountId, equals('acc-test-1'));
      expect(txn.type, equals(TransactionType.expense));
      expect(txn.amount, equals(Money(5000)));
      expect(txn.description, equals('Almoço'));
      expect(txn.isRecurring, isFalse);
    });

    test('Transaction.create() com parâmetros válidos funciona', () {
      final txn = Transaction.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: Money(500000), // R$ 5.000,00
        description: 'Salário',
        date: DateTime.utc(2026, 4, 1),
      );

      expect(txn.id, equals('txn-1'));
      expect(txn.type, equals(TransactionType.income));
      expect(txn.amount, equals(Money(500000)));
    });

    test('Transaction.create() com notes opcional funciona', () {
      final txn = Transaction.create(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: Money(1000),
        description: 'Café',
        date: DateTime.utc(2026, 4, 19),
        notes: 'Cafeteria do trabalho',
      );

      expect(txn.notes, equals('Cafeteria do trabalho'));
    });
  });

  group('Transaction — validação', () {
    test('amount zero lança ValidationException', () {
      expect(
        () => Transaction.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money.zero,
          description: 'Teste',
          date: DateTime.utc(2026, 4, 19),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('amount negativo lança ValidationException', () {
      expect(
        () => Transaction.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money(-100),
          description: 'Teste',
          date: DateTime.utc(2026, 4, 19),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('descrição vazia lança ValidationException', () {
      expect(
        () => Transaction.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money(1000),
          description: '',
          date: DateTime.utc(2026, 4, 19),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('descrição somente espaços lança ValidationException', () {
      expect(
        () => Transaction.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money(1000),
          description: '   ',
          date: DateTime.utc(2026, 4, 19),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('descrição com mais de 255 caracteres lança ValidationException', () {
      expect(
        () => Transaction.create(
          id: 'txn-1',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money(1000),
          description: 'A' * 256,
          date: DateTime.utc(2026, 4, 19),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Transaction — balanceEffect', () {
    test('expense reduz saldo (balanceEffect negativo)', () {
      final txn = buildTestTransaction(
          type: TransactionType.expense, amount: Money(5000));
      expect(txn.balanceEffect, equals(Money(-5000)));
    });

    test('income aumenta saldo (balanceEffect positivo)', () {
      final txn = buildTestTransaction(
          type: TransactionType.income, amount: Money(100000));
      expect(txn.balanceEffect, equals(Money(100000)));
    });

    test('transfer não afeta saldo diretamente (balanceEffect zero)', () {
      final txn = buildTestTransaction(
          type: TransactionType.transfer, amount: Money(50000));
      expect(txn.balanceEffect, equals(Money.zero));
    });

    test('soma de income e expense reflete saldo líquido correto', () {
      final income = buildTestTransaction(
        id: 'txn-1',
        type: TransactionType.income,
        amount: Money(300000), // R$ 3.000,00
      );
      final expense = buildTestTransaction(
        id: 'txn-2',
        type: TransactionType.expense,
        amount: Money(50000), // R$ 500,00
      );
      final net = income.balanceEffect + expense.balanceEffect;
      expect(net, equals(Money(250000))); // R$ 2.500,00
    });
  });

  group('Transaction — copyWith', () {
    test('copyWith altera apenas os campos especificados', () {
      final txn = buildTestTransaction();
      final updated = txn.copyWith(description: 'Jantar');

      expect(updated.description, equals('Jantar'));
      expect(updated.id, equals(txn.id));
      expect(updated.amount, equals(txn.amount));
    });

    test('copyWith sem argumentos retorna objeto com mesmos valores', () {
      final txn = buildTestTransaction();
      final copy = txn.copyWith();

      expect(copy.id, equals(txn.id));
      expect(copy.type, equals(txn.type));
      expect(copy.amount, equals(txn.amount));
    });
  });

  group('Transaction — igualdade', () {
    test('transações com mesmo id são iguais', () {
      final t1 = buildTestTransaction();
      final t2 = buildTestTransaction();
      expect(t1, equals(t2));
    });

    test('transações com ids diferentes não são iguais', () {
      final t1 = buildTestTransaction(id: 'txn-1');
      final t2 = buildTestTransaction(id: 'txn-2');
      expect(t1, isNot(equals(t2)));
    });
  });

  group('TransactionType — labels', () {
    test('income tem label correto', () {
      expect(TransactionType.income.label, equals('Receita'));
    });

    test('expense tem label correto', () {
      expect(TransactionType.expense.label, equals('Despesa'));
    });

    test('transfer tem label correto', () {
      expect(TransactionType.transfer.label, equals('Transferência'));
    });
  });
}
