import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';

import '../../../helpers/drift_test_helpers.dart';

AccountsTableCompanion _buildCompanion({
  String id = 'acc-1',
  String name = 'Nubank',
  String type = 'checking',
  int currentBalanceCents = 0,
  bool isArchived = false,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return AccountsTableCompanion.insert(
    id: id,
    name: name,
    type: type,
    currentBalanceCents: Value(currentBalanceCents),
    isArchived: Value(isArchived),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late AccountsDao dao;

  setUp(() {
    db = buildInMemoryDatabase();
    dao = AccountsDao(db);
  });

  tearDown(() => db.close());

  group('AccountsDao — CRUD', () {
    test('insere e recupera conta por id', () async {
      await dao.insertAccount(_buildCompanion());

      final account = await dao.getById('acc-1');
      expect(account, isNotNull);
      expect(account!.name, equals('Nubank'));
      expect(account.type, equals('checking'));
      expect(account.currentBalanceCents, equals(0));
    });

    test('getAll retorna apenas contas ativas por padrão', () async {
      await dao.insertAccount(_buildCompanion(id: 'acc-1', name: 'Ativa'));
      await dao.insertAccount(
        _buildCompanion(id: 'acc-2', name: 'Arquivada', isArchived: true),
      );

      final active = await dao.getAll();
      expect(active.length, equals(1));
      expect(active.first.name, equals('Ativa'));
    });

    test('getAll com includeArchived = true retorna todas', () async {
      await dao.insertAccount(_buildCompanion(id: 'acc-1'));
      await dao.insertAccount(
        _buildCompanion(id: 'acc-2', isArchived: true),
      );

      final all = await dao.getAll(includeArchived: true);
      expect(all.length, equals(2));
    });

    test('atualiza conta via updateAccount', () async {
      final now = DateTime.utc(2026, 4, 19);
      await dao.insertAccount(_buildCompanion());

      await dao.updateAccount(
        AccountsTableCompanion(
          id: const Value('acc-1'),
          name: const Value('Itaú'),
          type: const Value('savings'),
          currentBalanceCents: const Value(0),
          currency: const Value('BRL'),
          isArchived: const Value(false),
          color: const Value(0xFF1B4332),
          icon: const Value('account_balance'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final updated = await dao.getById('acc-1');
      expect(updated!.name, equals('Itaú'));
      expect(updated.type, equals('savings'));
    });

    test('archiveAccount define isArchived = true', () async {
      await dao.insertAccount(_buildCompanion());

      await dao.archiveAccount('acc-1');

      final account = await dao.getById('acc-1');
      expect(account!.isArchived, isTrue);
    });

    test('unarchiveAccount define isArchived = false', () async {
      await dao.insertAccount(_buildCompanion(isArchived: true));

      await dao.unarchiveAccount('acc-1');

      final account = await dao.getById('acc-1');
      expect(account!.isArchived, isFalse);
    });

    test('deleteAccount remove a conta', () async {
      await dao.insertAccount(_buildCompanion());
      await dao.deleteAccount('acc-1');

      final account = await dao.getById('acc-1');
      expect(account, isNull);
    });

    test('saldo armazenado em centavos (R\$ 1.000,00 = 100000)', () async {
      await dao.insertAccount(
        _buildCompanion(currentBalanceCents: 100000),
      );

      final account = await dao.getById('acc-1');
      expect(account!.currentBalanceCents, equals(100000));
    });
  });

  group('AccountsDao — stream reativo', () {
    test('watchAll emite lista inicial', () async {
      await dao.insertAccount(_buildCompanion());

      final list = await dao.watchAll().first;
      expect(list.length, equals(1));
      expect(list.first.name, equals('Nubank'));
    });

    test('watchAll emite nova lista após insert', () async {
      final stream = dao.watchAll();

      await dao.insertAccount(_buildCompanion(id: 'acc-1', name: 'Nubank'));
      await dao.insertAccount(_buildCompanion(id: 'acc-2', name: 'Itaú'));

      final list = await stream.first;
      expect(list.length, equals(2));
    });
  });
}
