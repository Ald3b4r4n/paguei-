import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/bills_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

BillsTableCompanion _buildCompanion({
  String id = 'bill-1',
  String title = 'Conta de Luz',
  double amount = 120.0,
  DateTime? dueDate,
  String status = 'pending',
  String? accountId,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return BillsTableCompanion.insert(
    id: id,
    title: title,
    amount: amount,
    dueDate: dueDate ?? DateTime.utc(2026, 5, 10),
    createdAt: now,
    updatedAt: now,
    status: Value(status),
    accountId: Value(accountId),
  );
}

void main() {
  late AppDatabase db;
  late BillsDao dao;

  setUp(() {
    db = buildInMemoryDatabase();
    dao = BillsDao(db);
  });

  tearDown(() => db.close());

  group('BillsDao — CRUD', () {
    test('insere e recupera boleto por id', () async {
      await dao.insertBill(_buildCompanion());

      final bill = await dao.getById('bill-1');
      expect(bill, isNotNull);
      expect(bill!.title, equals('Conta de Luz'));
      expect(bill.amount, equals(120.0));
      expect(bill.status, equals('pending'));
    });

    test('deleteBill remove o boleto', () async {
      await dao.insertBill(_buildCompanion());
      await dao.deleteBill('bill-1');

      expect(await dao.getById('bill-1'), isNull);
    });

    test('updateBill persiste as alterações', () async {
      await dao.insertBill(_buildCompanion());

      final updated = BillsTableCompanion(
        id: const Value('bill-1'),
        title: const Value('Água'),
        amount: const Value(80.0),
        dueDate: Value(DateTime.utc(2026, 5, 15)),
        createdAt: Value(DateTime.utc(2026, 4, 19)),
        updatedAt: Value(DateTime.now().toUtc()),
        status: const Value('pending'),
      );
      await dao.updateBill(updated);

      final bill = await dao.getById('bill-1');
      expect(bill!.title, equals('Água'));
      expect(bill.amount, equals(80.0));
    });

    test('getAll retorna todos os boletos', () async {
      await dao.insertBill(_buildCompanion(id: 'bill-1'));
      await dao.insertBill(_buildCompanion(id: 'bill-2', title: 'Internet'));

      final bills = await dao.getAll();
      expect(bills.length, equals(2));
    });
  });

  group('BillsDao — filtros por status', () {
    setUp(() async {
      await dao.insertBill(_buildCompanion(id: 'b1', status: 'pending'));
      await dao.insertBill(_buildCompanion(id: 'b2', status: 'pending'));
      await dao.insertBill(_buildCompanion(id: 'b3', status: 'paid'));
      await dao.insertBill(_buildCompanion(id: 'b4', status: 'cancelled'));
    });

    test('getByStatus(pending) retorna apenas pendentes', () async {
      final result = await dao.getByStatus('pending');
      expect(result.length, equals(2));
    });

    test('getByStatus(paid) retorna apenas pagos', () async {
      final result = await dao.getByStatus('paid');
      expect(result.length, equals(1));
    });

    test('getPending retorna boletos com status pending', () async {
      final result = await dao.getPending();
      expect(result.length, equals(2));
    });
  });

  group('BillsDao — boletos vencidos', () {
    test('getOverdue retorna pending com dueDate anterior a now', () async {
      final pastDate = DateTime.utc(2020, 1, 1);
      final futureDate = DateTime.utc(2030, 1, 1);
      await dao.insertBill(_buildCompanion(id: 'b-past', dueDate: pastDate));
      await dao
          .insertBill(_buildCompanion(id: 'b-future', dueDate: futureDate));

      final overdue = await dao.getOverdue(DateTime.utc(2026, 4, 19));
      expect(overdue.length, equals(1));
      expect(overdue.first.id, equals('b-past'));
    });

    test('boletos pagos não aparecem em getOverdue', () async {
      await dao.insertBill(
        _buildCompanion(
          id: 'b-paid-past',
          dueDate: DateTime.utc(2020, 1, 1),
          status: 'paid',
        ),
      );

      final overdue = await dao.getOverdue(DateTime.utc(2026, 4, 19));
      expect(overdue, isEmpty);
    });
  });

  group('BillsDao — getDueSoon', () {
    test('retorna apenas boletos vencendo dentro da janela', () async {
      final now = DateTime.utc(2026, 4, 19);
      final soon = DateTime.utc(2026, 4, 22); // 3 dias
      final later = DateTime.utc(2026, 5, 10);

      await dao.insertBill(_buildCompanion(id: 'b-soon', dueDate: soon));
      await dao.insertBill(_buildCompanion(id: 'b-later', dueDate: later));

      final cutoff = now.add(const Duration(days: 7));
      final result = await dao.getDueSoon(now, cutoff);
      expect(result.length, equals(1));
      expect(result.first.id, equals('b-soon'));
    });
  });

  group('BillsDao — markAsPaid', () {
    test('atualiza status para paid e registra paidAt e paidAmount', () async {
      await dao.insertBill(_buildCompanion());

      final paidAt = DateTime.utc(2026, 4, 20);
      await dao.markAsPaid('bill-1', 120.0, paidAt);

      final bill = await dao.getById('bill-1');
      expect(bill!.status, equals('paid'));
      expect(bill.paidAmount, equals(120.0));
      expect(bill.paidAt?.toUtc(), equals(paidAt));
    });
  });

  group('BillsDao — streams reativos', () {
    test('watchAll emite lista de boletos', () async {
      await dao.insertBill(_buildCompanion(id: 'b1'));
      await dao.insertBill(_buildCompanion(id: 'b2', title: 'Internet'));

      final bills = await dao.watchAll().first;
      expect(bills.length, equals(2));
    });

    test('watchPending emite apenas boletos pendentes', () async {
      await dao.insertBill(_buildCompanion(id: 'b1', status: 'pending'));
      await dao.insertBill(_buildCompanion(id: 'b2', status: 'paid'));

      final pending = await dao.watchPending().first;
      expect(pending.length, equals(1));
      expect(pending.first.status, equals('pending'));
    });
  });

  group('BillsDao — seedTestBill helper', () {
    test('seedTestBill insere boleto de teste', () async {
      await db.seedTestBill();
      final bill = await dao.getById('test-bill-1');
      expect(bill, isNotNull);
      expect(bill!.title, equals('Conta de Luz'));
    });
  });
}
