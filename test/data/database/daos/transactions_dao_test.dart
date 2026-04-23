import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/transactions_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

TransactionsTableCompanion _buildCompanion({
  String id = 'txn-1',
  String accountId = 'test-account-1',
  String type = 'expense',
  double amount = 50.0,
  String description = 'Café',
  DateTime? date,
  String? categoryId,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return TransactionsTableCompanion.insert(
    id: id,
    accountId: accountId,
    type: type,
    amount: amount,
    description: description,
    date: date ?? now,
    categoryId: Value(categoryId),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late TransactionsDao dao;

  setUp(() async {
    db = buildInMemoryDatabase();
    dao = TransactionsDao(db);
    // Seed the required account (FK constraint)
    await db.seedTestAccount();
  });

  tearDown(() => db.close());

  group('TransactionsDao — CRUD', () {
    test('insere e recupera transação por id', () async {
      await dao.insertTransaction(_buildCompanion());

      final txn = await dao.getById('txn-1');
      expect(txn, isNotNull);
      expect(txn!.description, equals('Café'));
      expect(txn.type, equals('expense'));
      expect(txn.amount, equals(50.0));
    });

    test('deleteTransaction remove a transação', () async {
      await dao.insertTransaction(_buildCompanion());
      await dao.deleteTransaction('txn-1');

      final txn = await dao.getById('txn-1');
      expect(txn, isNull);
    });

    test('updateTransaction altera campos', () async {
      final now = DateTime.utc(2026, 4, 19);
      await dao.insertTransaction(_buildCompanion());

      await dao.updateTransaction(
        TransactionsTableCompanion(
          id: const Value('txn-1'),
          accountId: const Value('test-account-1'),
          type: const Value('income'),
          amount: const Value(100.0),
          description: const Value('Salário'),
          date: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await dao.getById('txn-1');
      expect(updated!.type, equals('income'));
      expect(updated.amount, equals(100.0));
      expect(updated.description, equals('Salário'));
    });
  });

  group('TransactionsDao — queries por mês', () {
    test('getByMonth retorna apenas transações do mês', () async {
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-1', date: DateTime.utc(2026, 4, 15)),
      );
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-2', date: DateTime.utc(2026, 3, 20)),
      );
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-3', date: DateTime.utc(2026, 5, 1)),
      );

      final april = await dao.getByMonth(year: 2026, month: 4);
      expect(april.length, equals(1));
      expect(april.first.id, equals('txn-1'));
    });

    test('getByMonth retorna lista vazia para mês sem transações', () async {
      final txns = await dao.getByMonth(year: 2026, month: 6);
      expect(txns, isEmpty);
    });

    test('getByMonth inclui transações de todo o mês (1º ao último dia)',
        () async {
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-1', date: DateTime.utc(2026, 4, 1)),
      );
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-2', date: DateTime.utc(2026, 4, 30)),
      );

      final april = await dao.getByMonth(year: 2026, month: 4);
      expect(april.length, equals(2));
    });

    test('getByMonth retorna transações ordenadas por data desc', () async {
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-1', date: DateTime.utc(2026, 4, 5)),
      );
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-2', date: DateTime.utc(2026, 4, 20)),
      );
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-3', date: DateTime.utc(2026, 4, 10)),
      );

      final txns = await dao.getByMonth(year: 2026, month: 4);
      expect(txns[0].id, equals('txn-2')); // most recent first
      expect(txns[1].id, equals('txn-3'));
      expect(txns[2].id, equals('txn-1'));
    });
  });

  group('TransactionsDao — queries por conta', () {
    test('getByAccount filtra por accountId', () async {
      await db.seedTestAccount(id: 'acc-2', name: 'Conta 2');

      await dao.insertTransaction(
          _buildCompanion(id: 'txn-1', accountId: 'test-account-1'));
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-2', accountId: 'acc-2'),
      );

      final acc1Txns = await dao.getByAccount('test-account-1');
      expect(acc1Txns.length, equals(1));
      expect(acc1Txns.first.id, equals('txn-1'));
    });
  });

  group('TransactionsDao — aggregações mensais', () {
    test('sumByType calcula total de despesas do mês', () async {
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-1',
            type: 'expense',
            amount: 100.0,
            date: DateTime.utc(2026, 4, 1)),
      );
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-2',
            type: 'expense',
            amount: 50.0,
            date: DateTime.utc(2026, 4, 15)),
      );
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-3',
            type: 'income',
            amount: 500.0,
            date: DateTime.utc(2026, 4, 10)),
      );

      final total = await dao.sumByType(year: 2026, month: 4, type: 'expense');
      expect(total, closeTo(150.0, 0.01));
    });

    test('sumByType calcula total de receitas do mês', () async {
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-1',
            type: 'income',
            amount: 3000.0,
            date: DateTime.utc(2026, 4, 1)),
      );
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-2',
            type: 'income',
            amount: 500.0,
            date: DateTime.utc(2026, 4, 10)),
      );

      final total = await dao.sumByType(year: 2026, month: 4, type: 'income');
      expect(total, closeTo(3500.0, 0.01));
    });

    test('sumByType retorna 0 quando não há transações', () async {
      final total = await dao.sumByType(year: 2026, month: 4, type: 'expense');
      expect(total, closeTo(0.0, 0.001));
    });

    test('sumByType não inclui transações de outros meses', () async {
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-1',
            type: 'expense',
            amount: 200.0,
            date: DateTime.utc(2026, 3, 31)),
      );
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-2',
            type: 'expense',
            amount: 100.0,
            date: DateTime.utc(2026, 4, 1)),
      );

      final april = await dao.sumByType(year: 2026, month: 4, type: 'expense');
      expect(april, closeTo(100.0, 0.01));
    });

    test('sumByType filtra por accountId quando informado', () async {
      await db.seedTestAccount(id: 'acc-2', name: 'Outra Conta');

      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-1',
            accountId: 'test-account-1',
            type: 'expense',
            amount: 100.0,
            date: DateTime.utc(2026, 4, 1)),
      );
      await dao.insertTransaction(
        _buildCompanion(
            id: 'txn-2',
            accountId: 'acc-2',
            type: 'expense',
            amount: 200.0,
            date: DateTime.utc(2026, 4, 2)),
      );

      final acc1Total = await dao.sumByType(
        year: 2026,
        month: 4,
        type: 'expense',
        accountId: 'test-account-1',
      );
      expect(acc1Total, closeTo(100.0, 0.01));
    });
  });

  group('TransactionsDao — stream reativo', () {
    test('watchByMonth emite lista inicial', () async {
      await dao.insertTransaction(
        _buildCompanion(id: 'txn-1', date: DateTime.utc(2026, 4, 15)),
      );

      final list = await dao.watchByMonth(year: 2026, month: 4).first;
      expect(list.length, equals(1));
    });

    test('watchByMonth emite nova lista após insert', () async {
      final stream = dao.watchByMonth(year: 2026, month: 4);

      await dao.insertTransaction(
        _buildCompanion(id: 'txn-1', date: DateTime.utc(2026, 4, 1)),
      );

      final list = await stream.first;
      expect(list.length, equals(1));
    });
  });
}
