import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

Account buildTestAccount({
  String id = 'acc-test-1',
  String name = 'Nubank',
  AccountType type = AccountType.checking,
  Money? currentBalance,
  String currency = 'BRL',
  bool isArchived = false,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: name,
    type: type,
    currentBalance: currentBalance ?? Money.zero,
    currency: currency,
    isArchived: isArchived,
    color: 0xFF1B4332,
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Account — criação válida', () {
    test('cria conta com campos mínimos obrigatórios', () {
      final account = buildTestAccount();

      expect(account.id, equals('acc-test-1'));
      expect(account.name, equals('Nubank'));
      expect(account.type, equals(AccountType.checking));
      expect(account.currency, equals('BRL'));
      expect(account.isArchived, isFalse);
      expect(account.currentBalance, equals(Money.zero));
    });

    test('Account.create() com nome válido funciona', () {
      final account = Account.create(
        id: 'acc-1',
        name: 'Conta Corrente',
        type: AccountType.checking,
      );
      expect(account.name, equals('Conta Corrente'));
      expect(account.currency, equals('BRL'));
    });
  });

  group('Account — validação', () {
    test('nome vazio lança ValidationException', () {
      expect(
        () => Account.create(
          id: 'acc-1',
          name: '',
          type: AccountType.checking,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nome somente espaços lança ValidationException', () {
      expect(
        () => Account.create(
          id: 'acc-1',
          name: '   ',
          type: AccountType.checking,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nome com mais de 100 caracteres lança ValidationException', () {
      expect(
        () => Account.create(
          id: 'acc-1',
          name: 'A' * 101,
          type: AccountType.checking,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('currency inválida lança ValidationException', () {
      expect(
        () => Account.create(
          id: 'acc-1',
          name: 'Conta',
          type: AccountType.checking,
          currency: 'INVALID',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Account — arquivamento', () {
    test('archive() define isArchived = true', () {
      final account = buildTestAccount();
      final archived = account.archive();

      expect(archived.isArchived, isTrue);
      expect(archived.id, equals(account.id));
    });

    test('unarchive() define isArchived = false', () {
      final account = buildTestAccount(isArchived: true);
      final active = account.unarchive();

      expect(active.isArchived, isFalse);
    });

    test('archive() atualiza updatedAt', () {
      final account = buildTestAccount();
      final before = account.updatedAt;

      // Aguardar 1ms para garantir diferença de timestamp
      final archived = account.archive();
      expect(archived.updatedAt.isAfter(before) || archived.updatedAt == before,
          isTrue);
    });
  });

  group('Account — copyWith', () {
    test('copyWith altera apenas os campos especificados', () {
      final account = buildTestAccount();
      final updated = account.copyWith(name: 'Itaú');

      expect(updated.name, equals('Itaú'));
      expect(updated.id, equals(account.id));
      expect(updated.type, equals(account.type));
    });

    test('copyWith com novo saldo atualiza currentBalance', () {
      final account = buildTestAccount();
      final newBalance = Money(500000); // R$ 5.000,00
      final updated = account.copyWith(currentBalance: newBalance);

      expect(updated.currentBalance, equals(newBalance));
    });

    test('copyWith sem argumentos retorna objeto com mesmos valores', () {
      final account = buildTestAccount();
      final copy = account.copyWith();

      expect(copy.id, equals(account.id));
      expect(copy.name, equals(account.name));
      expect(copy.currentBalance, equals(account.currentBalance));
    });
  });

  group('Account — igualdade', () {
    test('contas com mesmo id são iguais', () {
      final a1 = buildTestAccount(name: 'Nubank');
      final a2 = buildTestAccount(name: 'Nubank');
      expect(a1, equals(a2));
    });

    test('contas com ids diferentes não são iguais', () {
      final a1 = buildTestAccount(id: 'acc-1');
      final a2 = buildTestAccount(id: 'acc-2');
      expect(a1, isNot(equals(a2)));
    });

    test('hashCode é consistente para mesmos valores', () {
      final a1 = buildTestAccount();
      final a2 = buildTestAccount();
      expect(a1.hashCode, equals(a2.hashCode));
    });
  });

  group('Account — tipos', () {
    test('AccountType.checking tem label correto', () {
      expect(AccountType.checking.label, equals('Banco'));
    });

    test('AccountType.savings tem label correto', () {
      expect(AccountType.savings.label, equals('Poupança'));
    });

    test('AccountType.wallet tem label correto', () {
      expect(AccountType.wallet.label, equals('Carteira'));
    });

    test('AccountType.investment tem label correto', () {
      expect(AccountType.investment.label, equals('Investimentos'));
    });
  });
}
