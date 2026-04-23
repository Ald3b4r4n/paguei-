import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:paguei/domain/value_objects/money.dart';

void main() {
  setUpAll(() => Intl.defaultLocale = 'pt_BR');

  group('Money — construção', () {
    test('zero() retorna Money com 0 centavos', () {
      expect(Money.zero.cents, equals(0));
    });

    test('fromCents(100) representa R\$ 1,00', () {
      final money = Money(100);
      expect(money.cents, equals(100));
      expect(money.amount, closeTo(1.0, 0.001));
    });

    test('fromDouble(1.50) resulta em 150 centavos', () {
      final money = Money.fromDouble(1.50);
      expect(money.cents, equals(150));
    });

    test('fromDouble arredonda corretamente para 3 casas decimais', () {
      final money = Money.fromDouble(1.005);
      expect(money.cents, equals(101));
    });

    test('fromDouble de valor negativo é válido', () {
      final money = Money.fromDouble(-50.0);
      expect(money.cents, equals(-5000));
      expect(money.isNegative, isTrue);
    });
  });

  group('Money — aritmética', () {
    test('adição de dois valores positivos', () {
      final result = Money(100) + Money(200);
      expect(result.cents, equals(300));
    });

    test('subtração resulta em valor correto', () {
      final result = Money(500) - Money(200);
      expect(result.cents, equals(300));
    });

    test('subtração pode resultar em valor negativo', () {
      final result = Money(100) - Money(300);
      expect(result.cents, equals(-200));
      expect(result.isNegative, isTrue);
    });

    test('multiplicação por fator inteiro', () {
      final result = Money(100) * 3;
      expect(result.cents, equals(300));
    });

    test('multiplicação por fator decimal arredonda', () {
      final result = Money(100) * 0.333;
      expect(result.cents, equals(33));
    });

    test('negação inverte o sinal', () {
      expect((-Money(100)).cents, equals(-100));
      expect((-Money(-50)).cents, equals(50));
    });

    test('abs() retorna valor absoluto', () {
      expect(Money(-250).abs().cents, equals(250));
      expect(Money(250).abs().cents, equals(250));
    });
  });

  group('Money — comparação', () {
    test('valores iguais são iguais', () {
      expect(Money(100), equals(Money(100)));
    });

    test('valores diferentes não são iguais', () {
      expect(Money(100), isNot(equals(Money(200))));
    });

    test('< funciona corretamente', () {
      expect(Money(100) < Money(200), isTrue);
      expect(Money(200) < Money(100), isFalse);
    });

    test('<= funciona corretamente', () {
      expect(Money(100) <= Money(100), isTrue);
      expect(Money(100) <= Money(200), isTrue);
      expect(Money(200) <= Money(100), isFalse);
    });

    test('> funciona corretamente', () {
      expect(Money(200) > Money(100), isTrue);
      expect(Money(100) > Money(200), isFalse);
    });

    test('>= funciona corretamente', () {
      expect(Money(100) >= Money(100), isTrue);
      expect(Money(200) >= Money(100), isTrue);
    });

    test('compareTo retorna negativo, zero ou positivo', () {
      expect(Money(100).compareTo(Money(200)), isNegative);
      expect(Money(100).compareTo(Money(100)), equals(0));
      expect(Money(200).compareTo(Money(100)), isPositive);
    });
  });

  group('Money — propriedades', () {
    test('isZero retorna true para zero', () {
      expect(Money.zero.isZero, isTrue);
      expect(Money(1).isZero, isFalse);
    });

    test('isPositive retorna true para valor positivo', () {
      expect(Money(1).isPositive, isTrue);
      expect(Money(0).isPositive, isFalse);
      expect(Money(-1).isPositive, isFalse);
    });

    test('isNegative retorna true para valor negativo', () {
      expect(Money(-1).isNegative, isTrue);
      expect(Money(0).isNegative, isFalse);
      expect(Money(1).isNegative, isFalse);
    });
  });

  group('Money — formatação', () {
    test('formatted() retorna string em pt-BR', () {
      final money = Money(123456); // R$ 1.234,56
      expect(money.formatted(), contains('1.234,56'));
    });

    test('zero formata como R\$ 0,00', () {
      expect(Money.zero.formatted(), contains('0,00'));
    });

    test('toString() é igual a formatted()', () {
      final money = Money(5000);
      expect(money.toString(), equals(money.formatted()));
    });
  });

  group('Money — serialização', () {
    test('cents permite reconstruir o mesmo valor', () {
      final original = Money(12345);
      final reconstructed = Money(original.cents);
      expect(reconstructed, equals(original));
    });

    test('amount double permite fromDouble arredondado', () {
      final original = Money(100);
      final fromDouble = Money.fromDouble(original.amount);
      expect(fromDouble, equals(original));
    });
  });

  group('Money — hashCode', () {
    test('hashCode é consistente entre instâncias iguais', () {
      expect(Money(100).hashCode, equals(Money(100).hashCode));
    });

    test('hashCode difere entre instâncias diferentes', () {
      expect(Money(100).hashCode, isNot(equals(Money(200).hashCode)));
    });
  });
}
