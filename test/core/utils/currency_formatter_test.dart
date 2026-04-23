import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:paguei/core/utils/currency_formatter.dart';

void main() {
  setUpAll(() => Intl.defaultLocale = 'pt_BR');

  group('CurrencyFormatter.format', () {
    test('formata zero corretamente', () {
      expect(CurrencyFormatter.format(0), equals('R\$\u00a00,00'));
    });

    test('formata valor inteiro com duas casas decimais', () {
      expect(CurrencyFormatter.format(100), contains('100,00'));
    });

    test('formata valor com casas decimais', () {
      expect(CurrencyFormatter.format(1234.56), contains('1.234,56'));
    });

    test('formata valor negativo', () {
      final result = CurrencyFormatter.format(-500.0);
      expect(result, contains('500,00'));
    });

    test('formatAbsolute remove sinal negativo', () {
      expect(CurrencyFormatter.formatAbsolute(-200.0), isNot(contains('-')));
    });
  });

  group('CurrencyFormatter.parse', () {
    test('retorna null para string inválida', () {
      expect(CurrencyFormatter.parse('abc'), isNull);
    });

    test(r'parseia valor com R$ e pontos', () {
      final result = CurrencyFormatter.parse('R\$ 1.234,56');
      expect(result, closeTo(1234.56, 0.001));
    });

    test('parseia valor simples', () {
      final result = CurrencyFormatter.parse('100,00');
      expect(result, closeTo(100.0, 0.001));
    });
  });

  group('CurrencyFormatter.formatCompact', () {
    test('valores abaixo de 1000 usam formato completo', () {
      expect(CurrencyFormatter.formatCompact(999), contains('999'));
    });

    test('valores acima de 1000 usam formato compacto', () {
      final result = CurrencyFormatter.formatCompact(10000);
      expect(result, contains('R\$'));
    });
  });
}
