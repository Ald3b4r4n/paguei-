import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/accounts/deactivate_account_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';

class _FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _store = {};

  void seed(Account account) => _store[account.id] = account;
  Account? get(String id) => _store[id];

  @override
  Future<void> archive(String id) async {
    final account = _store[id];
    if (account == null)
      throw NotFoundException(message: 'Conta não encontrada: $id');
    _store[id] = account.archive();
  }

  @override
  Future<void> unarchive(String id) async {
    final account = _store[id];
    if (account == null)
      throw NotFoundException(message: 'Conta não encontrada: $id');
    _store[id] = account.unarchive();
  }

  @override
  Future<Account?> getById(String id) async => _store[id];

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
  Future<Account> update(Account account) async => account;

  @override
  Future<void> delete(String id) async => _store.remove(id);
}

Account _buildAccount({String id = 'acc-1', bool isArchived = false}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: 'Nubank',
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
  late _FakeAccountRepository repository;
  late DeactivateAccountUseCase useCase;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = DeactivateAccountUseCase(repository);
  });

  group('DeactivateAccountUseCase — archive', () {
    test('arquiva conta ativa com sucesso', () async {
      repository.seed(_buildAccount());

      await useCase.archive('acc-1');

      expect(repository.get('acc-1')!.isArchived, isTrue);
    });

    test('arquivar conta inexistente lança NotFoundException', () async {
      expect(
        () => useCase.archive('nao-existe'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('conta arquivada não aparece na listagem padrão', () async {
      repository.seed(_buildAccount());
      await useCase.archive('acc-1');

      final active = await repository.getAll();
      expect(active, isEmpty);
    });
  });

  group('DeactivateAccountUseCase — unarchive', () {
    test('restaura conta arquivada', () async {
      repository.seed(_buildAccount(isArchived: true));

      await useCase.unarchive('acc-1');

      expect(repository.get('acc-1')!.isArchived, isFalse);
    });

    test('restaurar conta inexistente lança NotFoundException', () async {
      expect(
        () => useCase.unarchive('nao-existe'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
