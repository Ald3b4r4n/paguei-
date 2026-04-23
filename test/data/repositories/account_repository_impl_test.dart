import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/app_database.dart'
    show AccountsTableCompanion, AccountsTableData;
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/repositories/account_repository_impl.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

// ---------------------------------------------------------------------------
// Fake DAO — no build_runner required for unit tests
// ---------------------------------------------------------------------------
class _FakeAccountsDao implements AccountsDao {
  final Map<String, AccountsTableData> _store = {};

  AccountsTableData _fromCompanion(AccountsTableCompanion c) {
    return AccountsTableData(
      id: c.id.value,
      name: c.name.value,
      type: c.type.value,
      currentBalanceCents:
          c.currentBalanceCents.present ? c.currentBalanceCents.value : 0,
      currency: c.currency.present ? c.currency.value : 'BRL',
      isArchived: c.isArchived.present && c.isArchived.value,
      color: c.color.present ? c.color.value : 0xFF1B4332,
      icon: c.icon.present ? c.icon.value : 'account_balance',
      createdAt: c.createdAt.value,
      updatedAt: c.updatedAt.value,
    );
  }

  @override
  Future<List<AccountsTableData>> getAll(
          {bool includeArchived = false}) async =>
      _store.values.where((r) => includeArchived || !r.isArchived).toList();

  @override
  Future<AccountsTableData?> getById(String id) async => _store[id];

  @override
  Stream<List<AccountsTableData>> watchAll({bool includeArchived = false}) =>
      Stream.value(
        _store.values.where((r) => includeArchived || !r.isArchived).toList(),
      );

  @override
  Future<void> insertAccount(AccountsTableCompanion companion) async {
    _store[companion.id.value] = _fromCompanion(companion);
  }

  @override
  Future<bool> updateAccount(AccountsTableCompanion companion) async {
    if (!_store.containsKey(companion.id.value)) return false;
    _store[companion.id.value] = _fromCompanion(companion);
    return true;
  }

  @override
  Future<int> archiveAccount(String id) async {
    final row = _store[id];
    if (row == null) return 0;
    _store[id] = _copyWith(row, isArchived: true);
    return 1;
  }

  @override
  Future<int> unarchiveAccount(String id) async {
    final row = _store[id];
    if (row == null) return 0;
    _store[id] = _copyWith(row, isArchived: false);
    return 1;
  }

  @override
  Future<int> deleteAccount(String id) async {
    _store.remove(id);
    return 1;
  }

  AccountsTableData _copyWith(AccountsTableData row,
      {required bool isArchived}) {
    return AccountsTableData(
      id: row.id,
      name: row.name,
      type: row.type,
      currentBalanceCents: row.currentBalanceCents,
      currency: row.currency,
      isArchived: isArchived,
      color: row.color,
      icon: row.icon,
      createdAt: row.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
Account _buildGhostAccount() {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: 'ghost-acc',
    name: 'Ghost',
    type: AccountType.checking,
    currentBalance: Money.zero,
    currency: 'BRL',
    isArchived: false,
    color: 0xFF1B4332,
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _FakeAccountsDao fakeDao;
  late AccountRepositoryImpl repository;

  setUp(() {
    fakeDao = _FakeAccountsDao();
    repository = AccountRepositoryImpl(fakeDao);
  });

  group('AccountRepositoryImpl — create', () {
    test('cria conta e retorna entidade de domínio', () async {
      final account = await repository.create(
        id: 'acc-1',
        name: 'Nubank',
        type: AccountType.checking,
      );

      expect(account.id, equals('acc-1'));
      expect(account.name, equals('Nubank'));
      expect(account.currentBalance, equals(Money.zero));
    });

    test('cria conta com saldo inicial em centavos', () async {
      final account = await repository.create(
        id: 'acc-2',
        name: 'Poupança',
        type: AccountType.savings,
        initialBalance: Money(150000), // R$ 1.500,00
      );

      expect(account.currentBalance.cents, equals(150000));
    });

    test('nome vazio propaga ValidationException', () async {
      expect(
        () => repository.create(
            id: 'acc-3', name: '', type: AccountType.checking),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('AccountRepositoryImpl — read', () {
    test('getById retorna null quando não existe', () async {
      final result = await repository.getById('nao-existe');
      expect(result, isNull);
    });

    test('getAll retorna lista vazia inicialmente', () async {
      final list = await repository.getAll();
      expect(list, isEmpty);
    });

    test('getAll exclui arquivadas por padrão', () async {
      await repository.create(
          id: 'acc-1', name: 'Ativa', type: AccountType.checking);
      await repository.create(
          id: 'acc-2', name: 'Outra', type: AccountType.wallet);
      await repository.archive('acc-2');

      final active = await repository.getAll();
      expect(active.length, equals(1));
      expect(active.first.name, equals('Ativa'));
    });
  });

  group('AccountRepositoryImpl — archive / unarchive', () {
    test('archive define isArchived = true', () async {
      await repository.create(
          id: 'acc-1', name: 'Test', type: AccountType.checking);
      await repository.archive('acc-1');

      final account = await repository.getById('acc-1');
      expect(account!.isArchived, isTrue);
    });

    test('archive em conta inexistente lança NotFoundException', () async {
      expect(
        () => repository.archive('nao-existe'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('unarchive restaura conta arquivada', () async {
      await repository.create(
          id: 'acc-1', name: 'Test', type: AccountType.checking);
      await repository.archive('acc-1');
      await repository.unarchive('acc-1');

      final account = await repository.getById('acc-1');
      expect(account!.isArchived, isFalse);
    });
  });

  group('AccountRepositoryImpl — update', () {
    test('update propaga alterações', () async {
      final created = await repository.create(
        id: 'acc-1',
        name: 'Original',
        type: AccountType.checking,
      );

      final modified = created.copyWith(name: 'Atualizado');
      final result = await repository.update(modified);

      expect(result.name, equals('Atualizado'));
    });

    test('update em conta inexistente lança NotFoundException', () async {
      expect(
        () => repository.update(_buildGhostAccount()),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('AccountRepositoryImpl — delete', () {
    test('delete remove a conta do store', () async {
      await repository.create(
          id: 'acc-1', name: 'Test', type: AccountType.checking);
      await repository.delete('acc-1');

      final account = await repository.getById('acc-1');
      expect(account, isNull);
    });
  });
}
