import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/accounts/create_account_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class _FakeAccountRepository implements AccountRepository {
  final List<Account> _accounts = [];

  @override
  Future<Account> create({
    required String id,
    required String name,
    required AccountType type,
    Money initialBalance = Money.zero,
    String currency = 'BRL',
    int color = 0xFF1B4332,
    String icon = 'account_balance',
  }) async {
    final account = Account.create(
      id: id,
      name: name,
      type: type,
      currentBalance: initialBalance,
      currency: currency,
      color: color,
      icon: icon,
    );
    _accounts.add(account);
    return account;
  }

  @override
  Future<void> archive(String id) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Account>> getAll({bool includeArchived = false}) async =>
      _accounts.where((a) => includeArchived || !a.isArchived).toList();

  @override
  Future<Account?> getById(String id) async =>
      _accounts.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> unarchive(String id) async {}

  @override
  Future<Account> update(Account account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx == -1) {
      throw NotFoundException(message: 'Conta não encontrada: ${account.id}');
    }
    _accounts[idx] = account;
    return account;
  }

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) =>
      Stream.value(
          _accounts.where((a) => includeArchived || !a.isArchived).toList());
}

void main() {
  late CreateAccountUseCase useCase;
  late _FakeAccountRepository repository;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = CreateAccountUseCase(repository);
  });

  group('CreateAccountUseCase', () {
    test('cria conta com parâmetros válidos', () async {
      final account = await useCase.execute(
        id: 'acc-1',
        name: 'Nubank',
        type: AccountType.checking,
      );

      expect(account.id, equals('acc-1'));
      expect(account.name, equals('Nubank'));
      expect(account.type, equals(AccountType.checking));
      expect(account.currency, equals('BRL'));
      expect(account.isArchived, isFalse);
    });

    test('cria conta com saldo inicial', () async {
      final account = await useCase.execute(
        id: 'acc-2',
        name: 'Poupança',
        type: AccountType.savings,
        initialBalance: Money(100000), // R$ 1.000,00
      );

      expect(account.currentBalance, equals(Money(100000)));
    });

    test('nome vazio propaga ValidationException', () async {
      expect(
        () =>
            useCase.execute(id: 'acc-3', name: '', type: AccountType.checking),
        throwsA(isA<ValidationException>()),
      );
    });

    test('conta criada é persistida no repositório', () async {
      await useCase.execute(
          id: 'acc-4', name: 'Itaú', type: AccountType.checking);

      final all = await repository.getAll();
      expect(all.length, equals(1));
      expect(all.first.name, equals('Itaú'));
    });
  });
}
