import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/presentation/bills/widgets/bill_status_chip.dart';
import 'package:paguei/presentation/theme/app_theme.dart';

Widget _buildChip(BillStatus status) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: BillStatusChip(status: status))),
  );
}

void main() {
  group('BillStatusChip', () {
    testWidgets('exibe label pt-BR para Pendente', (tester) async {
      await tester.pumpWidget(_buildChip(BillStatus.pending));
      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets('exibe label pt-BR para Pago', (tester) async {
      await tester.pumpWidget(_buildChip(BillStatus.paid));
      expect(find.text('Pago'), findsOneWidget);
    });

    testWidgets('exibe label pt-BR para Vencido', (tester) async {
      await tester.pumpWidget(_buildChip(BillStatus.overdue));
      expect(find.text('Vencido'), findsOneWidget);
    });

    testWidgets('exibe label pt-BR para Cancelado', (tester) async {
      await tester.pumpWidget(_buildChip(BillStatus.cancelled));
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('renderiza sem erro para todos os status', (tester) async {
      for (final status in BillStatus.values) {
        await tester.pumpWidget(_buildChip(status));
        expect(find.byType(BillStatusChip), findsOneWidget);
      }
    });
  });
}
