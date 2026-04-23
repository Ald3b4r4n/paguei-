import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/bills/widgets/bill_card.dart';
import 'package:paguei/presentation/bills/widgets/bill_status_chip.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

Bill _buildBill({
  String id = 'bill-1',
  String title = 'Energia Elétrica',
  BillStatus status = BillStatus.pending,
  DateTime? dueDate,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Bill(
    id: id,
    title: title,
    amount: Money.fromDouble(120.0),
    dueDate: dueDate ?? DateTime.utc(2026, 5, 10),
    status: status,
    isRecurring: false,
    reminderDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildCard(Bill bill,
    {VoidCallback? onMarkAsPaid, VoidCallback? onDelete}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt', 'BR')],
    locale: const Locale('pt', 'BR'),
    home: Scaffold(
      body: BillCard(
        bill: bill,
        onMarkAsPaid: onMarkAsPaid,
        onDelete: onDelete,
      ),
    ),
  );
}

void main() {
  group('BillCard', () {
    testWidgets('exibe título do boleto', (tester) async {
      await tester.pumpWidget(_buildCard(_buildBill()));
      expect(find.text('Energia Elétrica'), findsOneWidget);
    });

    testWidgets(r'exibe valor formatado em R$', (tester) async {
      await tester.pumpWidget(_buildCard(_buildBill()));
      expect(find.textContaining('120'), findsOneWidget);
    });

    testWidgets('exibe BillStatusChip', (tester) async {
      await tester.pumpWidget(_buildCard(_buildBill()));
      expect(find.byType(BillStatusChip), findsOneWidget);
    });

    testWidgets('exibe ícone de marcar como pago para boleto pendente',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(_buildBill(), onMarkAsPaid: () {}),
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('não exibe ícone de marcar como pago para boleto pago',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          _buildBill(status: BillStatus.paid),
          onMarkAsPaid: () {},
        ),
      );
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('exibe chip Vencido para boleto overdue', (tester) async {
      await tester.pumpWidget(
        _buildCard(_buildBill(status: BillStatus.overdue)),
      );
      expect(find.text('Vencido'), findsOneWidget);
    });

    testWidgets('exibe chip Pago para boleto pago', (tester) async {
      await tester.pumpWidget(_buildCard(_buildBill(status: BillStatus.paid)));
      expect(find.text('Pago'), findsOneWidget);
    });
  });
}
