import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/funds/widgets/fund_card.dart';

Fund _buildFund({
  String id = 'fund-1',
  String name = 'Reserva de Emergência',
  FundType type = FundType.emergency,
  double targetAmount = 10000.0,
  double currentAmount = 5000.0,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Fund(
    id: id,
    name: name,
    type: type,
    targetAmount: Money.fromDouble(targetAmount),
    currentAmount: Money.fromDouble(currentAmount),
    color: 0xFF1B4332,
    icon: 'savings',
    isCompleted: currentAmount >= targetAmount,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FundCard', () {
    testWidgets('exibe nome e tipo do fundo', (tester) async {
      await tester.pumpWidget(_wrap(
        FundCard(
          fund: _buildFund(name: 'Fundo Pessoal'),
          onTap: () {},
          onContribute: () {},
          onWithdraw: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fundo Pessoal'), findsOneWidget);
      expect(find.text('Reserva de Emergência'), findsOneWidget);
    });

    testWidgets('exibe barra de progresso', (tester) async {
      await tester.pumpWidget(_wrap(
        FundCard(
          fund: _buildFund(currentAmount: 5000, targetAmount: 10000),
          onTap: () {},
          onContribute: () {},
          onWithdraw: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('exibe badge "Concluído" quando fundo está completo',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FundCard(
          fund: _buildFund(currentAmount: 10000, targetAmount: 10000),
          onTap: () {},
          onContribute: () {},
          onWithdraw: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Concluído'), findsOneWidget);
    });

    testWidgets('não exibe badge "Concluído" quando fundo incompleto',
        (tester) async {
      await tester.pumpWidget(_wrap(
        FundCard(
          fund: _buildFund(currentAmount: 5000, targetAmount: 10000),
          onTap: () {},
          onContribute: () {},
          onWithdraw: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Concluído'), findsNothing);
    });

    testWidgets('chama onContribute ao selecionar ação', (tester) async {
      var contributed = false;
      await tester.pumpWidget(_wrap(
        FundCard(
          fund: _buildFund(),
          onTap: () {},
          onContribute: () => contributed = true,
          onWithdraw: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aportar'));
      await tester.pumpAndSettle();

      expect(contributed, isTrue);
    });
  });
}
