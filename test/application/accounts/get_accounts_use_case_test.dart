import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/accounts/get_accounts_use_case.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class _FakeAccountRepository implements AccountRepository {
  final List<Account> _accounts;

  _FakeAccountRepository(this._accounts);

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async =>
      _accounts.where((a) => includeArchived || !a.isArchived).toList();

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) =>
      Stream.value(
          _accounts.where((a) => includeArchived || !a.isArchived).toList());

  @override
  Future<Account?> getById(String id) async =>
      _accounts.where((a) => a.id == id).firstOrNull;

  @override
  Future<Account> create({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> archive(String id) async {}

  @override
  Future<void> unarchive(String id) async {}

  @override
  Future<Account> update(Account account) async => account;

  @override
  Future<void> delete(String id) async {}
}

Account _buildAccount({
  required String id,
  required String name,
  bool isArchived = false,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: name,
    type: AccountType.checking,
    currentBalance: Money.zero,
    currency: 'BRL',
    isArchived: isArchived,
    color: 0xFF1B4332,
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetAccountsUseCase', () {
    test('retorna lista vazia quando não há contas', () async {
      final useCase = GetAccountsUseCase(_FakeAccountRepository([]));
      final accounts = await useCase.execute();
      expect(accounts, isEmpty);
    });

    test('retorna contas ativas por padrão', () async {
      final accounts = [
        _buildAccount(id: 'acc-1', name: 'Ativa'),
        _buildAccount(id: 'acc-2', name: 'Arquivada', isArchived: true),
      ];
      final useCase = GetAccountsUseCase(_FakeAccountRepository(accounts));

      final result = await useCase.execute();
      expect(result.length, equals(1));
      expect(result.first.name, equals('Ativa'));
    });

    test('inclui arquivadas quando includeArchived = true', () async {
      final accounts = [
        _buildAccount(id: 'acc-1', name: 'Ativa'),
        _buildAccount(id: 'acc-2', name: 'Arquivada', isArchived: true),
      ];
      final useCase = GetAccountsUseCase(_FakeAccountRepository(accounts));

      final result = await useCase.execute(includeArchived: true);
      expect(result.length, equals(2));
    });

    test('watchAll emite lista reativa', () async {
      final accounts = [
        _buildAccount(id: 'acc-1', name: 'Nubank'),
      ];
      final useCase = GetAccountsUseCase(_FakeAccountRepository(accounts));

      final stream = useCase.watch();
      final result = await stream.first;
      expect(result.length, equals(1));
      expect(result.first.name, equals('Nubank'));
    });
  });
}
