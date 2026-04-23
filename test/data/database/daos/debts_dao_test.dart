import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/debts_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

DebtsTableCompanion _buildCompanion({
  String id = 'debt-1',
  String creditorName = 'Banco Itaú',
  double totalAmount = 12000.0,
  double remainingAmount = 12000.0,
  int? installments = 12,
  int installmentsPaid = 0,
  double? installmentAmount = 1000.0,
  String status = 'active',
}) {
  final now = DateTime.utc(2026, 4, 19);
  return DebtsTableCompanion.insert(
    id: id,
    creditorName: creditorName,
    totalAmount: totalAmount,
    remainingAmount: remainingAmount,
    installments: Value(installments),
    installmentsPaid: Value(installmentsPaid),
    installmentAmount: Value(installmentAmount),
    status: Value(status),
    startDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late DebtsDao dao;

  setUp(() {
    db = buildInMemoryDatabase();
    dao = DebtsDao(db);
  });

  tearDown(() => db.close());

  group('DebtsDao — CRUD', () {
    test('insere e recupera dívida por id', () async {
      await dao.insertDebt(_buildCompanion());

      final debt = await dao.getById('debt-1');
      expect(debt, isNotNull);
      expect(debt!.creditorName, equals('Banco Itaú'));
      expect(debt.totalAmount, equals(12000.0));
      expect(debt.remainingAmount, equals(12000.0));
      expect(debt.status, equals('active'));
      expect(debt.installmentsPaid, equals(0));
    });

    test('getAll retorna todas as dívidas sem filtro', () async {
      await dao.insertDebt(_buildCompanion(id: 'debt-1'));
      await dao.insertDebt(
        _buildCompanion(id: 'debt-2', creditorName: 'Nubank', status: 'paid'),
      );

      final all = await dao.getAll();
      expect(all.length, equals(2));
    });

    test('getAll filtra por status', () async {
      await dao.insertDebt(_buildCompanion(id: 'debt-1', status: 'active'));
      await dao.insertDebt(
        _buildCompanion(id: 'debt-2', creditorName: 'Nubank', status: 'paid'),
      );

      final active = await dao.getAll(status: 'active');
      expect(active.length, equals(1));
      expect(active.first.status, equals('active'));
    });

    test('getById retorna null para id inexistente', () async {
      final debt = await dao.getById('nao-existe');
      expect(debt, isNull);
    });

    test('updateDebt persiste mudanças', () async {
      await dao.insertDebt(_buildCompanion());

      final now = DateTime.utc(2026, 4, 19);
      await dao.updateDebt(
        DebtsTableCompanion(
          id: const Value('debt-1'),
          creditorName: const Value('Banco Itaú'),
          totalAmount: const Value(12000.0),
          remainingAmount: const Value(11000.0),
          installmentsPaid: const Value(1),
          status: const Value('active'),
          startDate: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await dao.getById('debt-1');
      expect(updated!.remainingAmount, equals(11000.0));
      expect(updated.installmentsPaid, equals(1));
    });

    test('updateDebt muda status para paid quando quitada', () async {
      await dao.insertDebt(_buildCompanion());

      final now = DateTime.utc(2026, 4, 19);
      await dao.updateDebt(
        DebtsTableCompanion(
          id: const Value('debt-1'),
          creditorName: const Value('Banco Itaú'),
          totalAmount: const Value(12000.0),
          remainingAmount: const Value(0.0),
          installmentsPaid: const Value(12),
          status: const Value('paid'),
          startDate: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await dao.getById('debt-1');
      expect(updated!.status, equals('paid'));
      expect(updated.remainingAmount, equals(0.0));
    });

    test('deleteDebt remove a dívida', () async {
      await dao.insertDebt(_buildCompanion());
      await dao.deleteDebt('debt-1');

      final debt = await dao.getById('debt-1');
      expect(debt, isNull);
    });

    test('getTotalRemainingAmount soma dívidas ativas', () async {
      await dao.insertDebt(
        _buildCompanion(id: 'debt-1', remainingAmount: 8000.0),
      );
      await dao.insertDebt(
        _buildCompanion(
            id: 'debt-2', creditorName: 'Nubank', remainingAmount: 3000.0),
      );
      await dao.insertDebt(
        _buildCompanion(
            id: 'debt-3',
            creditorName: 'Outro',
            remainingAmount: 0.0,
            status: 'paid'),
      );

      final total = await dao.getTotalRemainingAmount();
      expect(total, closeTo(11000.0, 0.01));
    });
  });

  group('DebtsDao — stream reativo', () {
    test('watchAll emite lista inicial vazia', () async {
      final list = await dao.watchAll().first;
      expect(list, isEmpty);
    });

    test('watchAll filtra por status', () async {
      await dao.insertDebt(_buildCompanion(id: 'debt-1', status: 'active'));
      await dao.insertDebt(
        _buildCompanion(id: 'debt-2', creditorName: 'X', status: 'paid'),
      );

      final active = await dao.watchAll(status: 'active').first;
      expect(active.length, equals(1));
    });
  });
}
