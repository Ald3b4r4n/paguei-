import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/shared/widgets/money_text.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() => Intl.defaultLocale = 'pt_BR');

  group('MoneyText', () {
    testWidgets('exibe valor positivo formatado', (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money(123456))));
      expect(find.textContaining('1.234,56'), findsOneWidget);
    });

    testWidgets('exibe zero formatado', (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money.zero)));
      expect(find.textContaining('0,00'), findsOneWidget);
    });

    testWidgets('exibe valor negativo formatado', (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money(-5000))));
      expect(find.textContaining('50,00'), findsOneWidget);
    });

    testWidgets('showSign = true adiciona "+" para positivos', (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money(100), showSign: true)));
      final textFinder = find.byType(Text);
      final widget = tester.widget<Text>(textFinder);
      expect(widget.data, startsWith('+'));
    });

    testWidgets('showSign = true não adiciona "+" para negativos',
        (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money(-100), showSign: true)));
      final widget = tester.widget<Text>(find.byType(Text));
      expect(widget.data, isNot(startsWith('+')));
    });

    testWidgets('usa cor de erro para valor negativo', (tester) async {
      await tester.pumpWidget(_wrap(MoneyText(Money(-1))));
      await tester.pump();

      final text = tester.widget<Text>(find.byType(Text));
      final colorScheme =
          Theme.of(tester.element(find.byType(Text))).colorScheme;
      expect(text.style?.color, equals(colorScheme.error));
    });

    testWidgets('aceita style customizado', (tester) async {
      const customStyle = TextStyle(fontSize: 32, fontWeight: FontWeight.w900);
      await tester.pumpWidget(
        _wrap(MoneyText(Money(1000), style: customStyle)),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, equals(32));
      expect(text.style?.fontWeight, equals(FontWeight.w900));
    });
  });
}
