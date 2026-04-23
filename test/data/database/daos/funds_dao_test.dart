import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/funds_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

FundsTableCompanion _buildCompanion({
  String id = 'fund-1',
  String name = 'Reserva de Emergência',
  String type = 'emergency',
  double targetAmount = 10000.0,
  double currentAmount = 0.0,
  bool isCompleted = false,
  int color = 0xFF1B4332,
  String icon = 'savings',
}) {
  final now = DateTime.utc(2026, 4, 19);
  return FundsTableCompanion.insert(
    id: id,
    name: name,
    type: type,
    targetAmount: targetAmount,
    currentAmount: Value(currentAmount),
    color: color,
    icon: icon,
    isCompleted: Value(isCompleted),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late FundsDao dao;

  setUp(() {
    db = buildInMemoryDatabase();
    dao = FundsDao(db);
  });

  tearDown(() => db.close());

  group('FundsDao — CRUD', () {
    test('insere e recupera fundo por id', () async {
      await dao.insertFund(_buildCompanion());

      final fund = await dao.getById('fund-1');
      expect(fund, isNotNull);
      expect(fund!.name, equals('Reserva de Emergência'));
      expect(fund.type, equals('emergency'));
      expect(fund.targetAmount, equals(10000.0));
      expect(fund.currentAmount, equals(0.0));
      expect(fund.isCompleted, isFalse);
    });

    test('getAll retorna todos os fundos', () async {
      await dao.insertFund(_buildCompanion(id: 'fund-1', name: 'Fundo A'));
      await dao.insertFund(_buildCompanion(id: 'fund-2', name: 'Fundo B'));

      final funds = await dao.getAll();
      expect(funds.length, equals(2));
    });

    test('getById retorna null para id inexistente', () async {
      final fund = await dao.getById('nao-existe');
      expect(fund, isNull);
    });

    test('updateFund persiste mudanças', () async {
      await dao.insertFund(_buildCompanion());

      final now = DateTime.utc(2026, 4, 19);
      await dao.updateFund(
        FundsTableCompanion(
          id: const Value('fund-1'),
          name: const Value('Meta Viagem'),
          type: const Value('goal'),
          targetAmount: const Value(5000.0),
          currentAmount: const Value(2500.0),
          isCompleted: const Value(false),
          color: const Value(0xFF1B4332),
          icon: const Value('savings'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await dao.getById('fund-1');
      expect(updated!.name, equals('Meta Viagem'));
      expect(updated.currentAmount, equals(2500.0));
    });

    test('deleteFund remove o fundo', () async {
      await dao.insertFund(_buildCompanion());
      await dao.deleteFund('fund-1');

      final fund = await dao.getById('fund-1');
      expect(fund, isNull);
    });

    test('getTotalCurrentAmount soma todos os saldos', () async {
      await dao.insertFund(_buildCompanion(
        id: 'fund-1',
        currentAmount: 3000.0,
      ));
      await dao.insertFund(_buildCompanion(
        id: 'fund-2',
        currentAmount: 2000.0,
      ));

      final total = await dao.getTotalCurrentAmount();
      expect(total, closeTo(5000.0, 0.01));
    });

    test('getTotalCurrentAmount retorna 0 quando não há fundos', () async {
      final total = await dao.getTotalCurrentAmount();
      expect(total, equals(0.0));
    });
  });

  group('FundsDao — stream reativo', () {
    test('watchAll emite lista inicial vazia', () async {
      final list = await dao.watchAll().first;
      expect(list, isEmpty);
    });

    test('watchAll emite nova lista após insert', () async {
      final stream = dao.watchAll();

      await dao.insertFund(_buildCompanion(id: 'fund-1', name: 'Fundo A'));
      await dao.insertFund(_buildCompanion(id: 'fund-2', name: 'Fundo B'));

      final list = await stream.first;
      expect(list.length, equals(2));
    });
  });
}
