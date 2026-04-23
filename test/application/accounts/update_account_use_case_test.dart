import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/accounts/update_account_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class _FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _store = {};

  void seed(Account account) => _store[account.id] = account;

  @override
  Future<Account?> getById(String id) async => _store[id];

  @override
  Future<Account> update(Account account) async {
    if (!_store.containsKey(account.id)) {
      throw NotFoundException(message: 'Conta não encontrada: ${account.id}');
    }
    _store[account.id] = account;
    return account;
  }

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async =>
      _store.values.where((a) => includeArchived || !a.isArchived).toList();

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) =>
      Stream.value(_store.values
          .where((a) => includeArchived || !a.isArchived)
          .toList());

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
  Future<void> archive(String id) async {
    final account = _store[id];
    if (account == null) {
      throw NotFoundException(message: 'Conta não encontrada: $id');
    }
    _store[id] = account.archive();
  }

  @override
  Future<void> unarchive(String id) async {
    final account = _store[id];
    if (account == null) {
      throw NotFoundException(message: 'Conta não encontrada: $id');
    }
    _store[id] = account.unarchive();
  }

  @override
  Future<void> delete(String id) async => _store.remove(id);
}

Account _buildAccount({String id = 'acc-1', String name = 'Nubank'}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: name,
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

void main() {
  late _FakeAccountRepository repository;
  late UpdateAccountUseCase useCase;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = UpdateAccountUseCase(repository);
  });

  group('UpdateAccountUseCase', () {
    test('atualiza nome da conta com sucesso', () async {
      repository.seed(_buildAccount());

      final updated = await useCase.execute(
        id: 'acc-1',
        name: 'Itaú',
      );

      expect(updated.name, equals('Itaú'));
      expect(updated.id, equals('acc-1'));
    });

    test('conta inexistente lança NotFoundException', () async {
      expect(
        () => useCase.execute(id: 'nao-existe', name: 'X'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('nome vazio lança ValidationException', () async {
      repository.seed(_buildAccount());

      expect(
        () => useCase.execute(id: 'acc-1', name: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('atualiza tipo da conta', () async {
      repository.seed(_buildAccount());

      final updated = await useCase.execute(
        id: 'acc-1',
        type: AccountType.savings,
      );

      expect(updated.type, equals(AccountType.savings));
    });

    test('atualiza saldo atual', () async {
      repository.seed(_buildAccount());
      final novoSaldo = Money(200000); // R$ 2.000,00

      final updated = await useCase.execute(
        id: 'acc-1',
        currentBalance: novoSaldo,
      );

      expect(updated.currentBalance, equals(novoSaldo));
    });
  });
}
