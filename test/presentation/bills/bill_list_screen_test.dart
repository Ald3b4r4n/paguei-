import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/bills/bill_list_screen.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

List<Bill> _buildBills() {
  final now = DateTime.utc(2026, 4, 19);
  return [
    Bill(
      id: 'b1',
      title: 'Energia',
      amount: Money.fromDouble(120.0),
      dueDate: DateTime.utc(2026, 5, 10),
      status: BillStatus.pending,
      isRecurring: false,
      reminderDaysBefore: 3,
      createdAt: now,
      updatedAt: now,
    ),
    Bill(
      id: 'b2',
      title: 'Internet',
      amount: Money.fromDouble(99.90),
      dueDate: DateTime.utc(2020, 1, 1), // past date → overdue
      status: BillStatus.pending,
      isRecurring: false,
      reminderDaysBefore: 3,
      createdAt: now,
      updatedAt: now,
    ),
    Bill(
      id: 'b3',
      title: 'Água',
      amount: Money.fromDouble(50.0),
      dueDate: DateTime.utc(2026, 4, 15),
      status: BillStatus.paid,
      isRecurring: false,
      reminderDaysBefore: 3,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

Widget _buildWidget({List<Bill>? bills}) {
  return ProviderScope(
    overrides: [
      allBillsProvider.overrideWith(
        (ref) => Stream.value(bills ?? _buildBills()),
      ),
      pendingBillsProvider.overrideWith(
        (ref) => Stream.value(
          (bills ?? _buildBills())
              .where((b) => b.status == BillStatus.pending)
              .toList(),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const BillListScreen(),
    ),
  );
}

void main() {
  group('BillListScreen', () {
    testWidgets('exibe abas Pendentes, Vencidos, Pagos', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.text('Vencidos'), findsOneWidget);
      expect(find.text('Pagos'), findsOneWidget);
    });

    testWidgets('exibe ações visíveis para cadastrar boleto', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.text('Escanear QRCode PIX'), findsOneWidget);
      expect(find.text('Escanear Código de Barras'), findsOneWidget);
      expect(find.text('Importar PDF'), findsOneWidget);
      expect(find.text('Ler Imagem'), findsOneWidget);
      expect(find.text('Inserir Manualmente'), findsOneWidget);
    });

    testWidgets('exibe boletos pendentes na aba Pendentes', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      expect(find.text('Energia'), findsOneWidget);
    });

    testWidgets('estado vazio exibe mensagem na aba Pendentes', (tester) async {
      await tester.pumpWidget(_buildWidget(bills: []));
      await tester.pump();

      expect(find.text('Nenhum boleto pendente'), findsOneWidget);
    });

    testWidgets('estado de loading exibe CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allBillsProvider.overrideWith((ref) => const Stream.empty()),
            pendingBillsProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('pt', 'BR')],
            locale: const Locale('pt', 'BR'),
            home: const BillListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('aba Pagos mostra boleto pago', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.tap(find.text('Pagos'));
      await tester.pumpAndSettle();

      expect(find.text('Água'), findsOneWidget);
    });
  });
}
