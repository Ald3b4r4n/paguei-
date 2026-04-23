import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

void main() {
  const validEmv =
      '00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-4266554400005204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***63041D3D';

  group('PixCode — construção', () {
    test('aceita código EMV válido', () {
      final code = PixCode(validEmv);
      expect(code.value, equals(validEmv));
      expect(code.isEmvQr, isTrue);
    });

    test('aceita código com exatamente 10 caracteres', () {
      final code = PixCode('1234567890');
      expect(code.value, equals('1234567890'));
    });

    test('remove espaços em branco ao redor', () {
      final code = PixCode('  1234567890  ');
      expect(code.value, equals('1234567890'));
    });

    test('lança ValidationException para string vazia', () {
      expect(() => PixCode(''), throwsA(isA<ValidationException>()));
    });

    test('lança ValidationException para código muito curto (< 10)', () {
      expect(() => PixCode('123456789'), throwsA(isA<ValidationException>()));
    });

    test('lança ValidationException para código muito longo (> 512)', () {
      expect(() => PixCode('x' * 513), throwsA(isA<ValidationException>()));
    });
  });

  group('PixCode — isEmvQr', () {
    test('isEmvQr é true para código começando com 000201', () {
      expect(PixCode('00020100000000000'), isA<PixCode>());
      expect(PixCode('00020100000000000').isEmvQr, isTrue);
    });

    test('isEmvQr é false para código não EMV', () {
      expect(PixCode('1234567890').isEmvQr, isFalse);
    });
  });

  group('PixCode — igualdade', () {
    test('dois PixCodes com mesmo valor são iguais', () {
      expect(PixCode(validEmv), equals(PixCode(validEmv)));
    });

    test('dois PixCodes diferentes não são iguais', () {
      expect(PixCode('1234567890'), isNot(equals(PixCode('0987654321'))));
    });
  });

  group('PixCode — toString', () {
    test('toString retorna o valor', () {
      expect(PixCode('1234567890').toString(), equals('1234567890'));
    });
  });
}
