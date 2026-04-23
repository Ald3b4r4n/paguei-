import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:paguei/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  group('DateFormatter.formatShort', () {
    test('formata data no padrão dd/MM/yyyy', () {
      final date = DateTime(2026, 4, 19);
      expect(DateFormatter.formatShort(date), equals('19/04/2026'));
    });
  });

  group('DateFormatter.formatDueDate', () {
    test('retorna "Vence hoje" para data de hoje', () {
      final today = DateTime.now();
      final result = DateFormatter.formatDueDate(today);
      expect(result, equals('Vence hoje'));
    });

    test('retorna "Vence amanhã" para amanhã', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(DateFormatter.formatDueDate(tomorrow), equals('Vence amanhã'));
    });

    test('retorna "Venceu ontem" para ontem', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatDueDate(yesterday), equals('Venceu ontem'));
    });

    test('retorna data formatada para datas passadas', () {
      final past = DateTime(2026, 1, 15);
      expect(DateFormatter.formatDueDate(past), contains('15/01/2026'));
    });

    test('retorna data formatada para datas futuras', () {
      final future = DateTime.now().add(const Duration(days: 10));
      expect(DateFormatter.formatDueDate(future), contains('Vence em'));
    });
  });

  group('DateFormatter.daysUntilDue', () {
    test('retorna 0 para hoje', () {
      final today = DateTime.now();
      expect(DateFormatter.daysUntilDue(today), equals(0));
    });

    test('retorna 1 para amanhã', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(DateFormatter.daysUntilDue(tomorrow), equals(1));
    });

    test('retorna negativo para datas passadas', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.daysUntilDue(past), equals(-3));
    });
  });

  group('DateFormatter.parseShort', () {
    test('retorna null para formato inválido', () {
      expect(DateFormatter.parseShort('data-invalida'), isNull);
    });

    test('parseia data no padrão dd/MM/yyyy', () {
      final result = DateFormatter.parseShort('19/04/2026');
      expect(result?.year, equals(2026));
      expect(result?.month, equals(4));
      expect(result?.day, equals(19));
    });
  });
}
