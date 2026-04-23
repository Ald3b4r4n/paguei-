import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/presentation/accounts/widgets/account_card.dart';

Account _buildAccount({
  String id = 'acc-1',
  String name = 'Nubank',
  AccountType type = AccountType.checking,
  Money? balance,
  bool isArchived = false,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Account(
    id: id,
    name: name,
    type: type,
    currentBalance: balance ?? Money.zero,
    currency: 'BRL',
    isArchived: isArchived,
    color: 0xFF1B4332,
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AccountCard', () {
    testWidgets('exibe nome e tipo da conta', (tester) async {
      final account = _buildAccount(name: 'Nubank', type: AccountType.checking);

      await tester.pumpWidget(_wrap(AccountCard(account: account)));

      expect(find.text('Nubank'), findsOneWidget);
      expect(find.text('Banco'), findsOneWidget);
    });

    testWidgets('exibe saldo formatado em pt-BR', (tester) async {
      final account = _buildAccount(balance: Money(123456)); // R$ 1.234,56

      await tester.pumpWidget(_wrap(AccountCard(account: account)));

      // formatted() produces "R$ 1.234,56" — find substring
      expect(find.textContaining('1.234,56'), findsOneWidget);
    });

    testWidgets('exibe chip "Arquivada" quando isArchived = true',
        (tester) async {
      final account = _buildAccount(isArchived: true);

      await tester.pumpWidget(_wrap(AccountCard(account: account)));

      expect(find.text('Arquivada'), findsOneWidget);
    });

    testWidgets('não exibe chip "Arquivada" quando isArchived = false',
        (tester) async {
      final account = _buildAccount(isArchived: false);

      await tester.pumpWidget(_wrap(AccountCard(account: account)));

      expect(find.text('Arquivada'), findsNothing);
    });

    testWidgets('chama onTap ao tocar no card', (tester) async {
      var tapped = false;
      final account = _buildAccount();

      await tester.pumpWidget(_wrap(
        AccountCard(account: account, onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(AccountCard));
      expect(tapped, isTrue);
    });

    testWidgets('exibe label correto para cada tipo de conta', (tester) async {
      for (final type in AccountType.values) {
        final account = _buildAccount(type: type);
        await tester.pumpWidget(_wrap(AccountCard(account: account)));
        expect(find.text(type.label), findsOneWidget);
      }
    });
  });
}
