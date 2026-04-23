import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/value_objects/barcode.dart';

void main() {
  // 44-digit barcode (digits only)
  const valid44 = '03399000000000100009062900000000001490510273';
  // 47-digit linha digitável (digits only)
  const valid47 = '12345678901234567890123456789012345678901234567';

  group('Barcode — construção', () {
    test('aceita string com 44 dígitos', () {
      final bc = Barcode(valid44);
      expect(bc.value, equals(valid44));
      expect(bc.isCodigoDeBarras, isTrue);
      expect(bc.isLinhaDigitavel, isFalse);
    });

    test('aceita string com 47 dígitos', () {
      final bc = Barcode(valid47);
      expect(bc.value, equals(valid47));
      expect(bc.isLinhaDigitavel, isTrue);
      expect(bc.isCodigoDeBarras, isFalse);
    });

    test('remove pontos, espaços e hífens antes de validar', () {
      const formatted =
          '12345.67890 12345.678901 23456.789012 3 45678901234567';
      final barcode = Barcode(formatted);
      expect(barcode.value.length, equals(47));
    });

    test('lança ValidationException para string vazia', () {
      expect(() => Barcode(''), throwsA(isA<ValidationException>()));
    });

    test('lança ValidationException se conter letras', () {
      expect(
        () => Barcode('3419187571271463269044932301800037897700000503X'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException para tamanho incorreto (< 44)', () {
      expect(() => Barcode('12345678901234567890'),
          throwsA(isA<ValidationException>()));
    });

    test('lança ValidationException para tamanho incorreto (45–46 dígitos)',
        () {
      expect(
        () => Barcode('123456789012345678901234567890123456789012345'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException para tamanho incorreto (> 47)', () {
      expect(
        () => Barcode('123456789012345678901234567890123456789012345678'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Barcode — igualdade', () {
    test('dois Barcodes com mesmo valor são iguais', () {
      expect(Barcode(valid44), equals(Barcode(valid44)));
    });

    test('dois Barcodes com valores diferentes não são iguais', () {
      expect(Barcode(valid44), isNot(equals(Barcode(valid47))));
    });
  });

  group('Barcode.validateMod10', () {
    test('retorna true para sequência com check digit correto', () {
      // sequence 123455 has valid mod10 check digit (5)
      expect(Barcode.validateMod10('123455'), isTrue);
    });

    test('retorna false para check digit incorreto', () {
      expect(Barcode.validateMod10('123451'), isFalse);
    });

    test('retorna false para string muito curta', () {
      expect(Barcode.validateMod10('1'), isFalse);
    });
  });

  group('Barcode.validateMod11', () {
    test('retorna true para check digit 1 quando resto é 0', () {
      // Sequence onde resto de mod11 = 0, esperado check = 1
      // 2*2+3*3+4*4+5*5=4+9+16+25=54, 54%11=10, check=1
      expect(Barcode.validateMod11('23451'), isTrue);
    });

    test('retorna false para check digit incorreto', () {
      expect(Barcode.validateMod11('12345'), isFalse);
    });

    test('retorna false para string muito curta', () {
      expect(Barcode.validateMod11('1'), isFalse);
    });
  });

  group('Barcode — toString', () {
    test('toString retorna o valor sem formatação', () {
      expect(Barcode(valid44).toString(), equals(valid44));
    });
  });
}
