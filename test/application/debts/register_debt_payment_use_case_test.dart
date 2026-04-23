import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/debts/register_debt_payment_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_debt_repository.dart';

void main() {
  late FakeDebtRepository repo;
  late RegisterDebtPaymentUseCase useCase;

  setUp(() async {
    repo = FakeDebtRepository();
    useCase = RegisterDebtPaymentUseCase(repo);

    await repo.create(
      id: 'debt-1',
      creditorName: 'Banco Itaú',
      totalAmount: Money.fromDouble(12000),
      installments: 12,
      installmentAmount: Money.fromDouble(1000),
    );
  });

  test('debt payment reduces remainingAmount', () async {
    final updated = await useCase.execute(
      debtId: 'debt-1',
      amount: Money.fromDouble(1000),
    );

    expect(updated.remainingAmount, equals(Money.fromDouble(11000)));
  });

  test('debt payment increments installmentsPaid', () async {
    final updated = await useCase.execute(
      debtId: 'debt-1',
      amount: Money.fromDouble(1000),
    );

    expect(updated.installmentsPaid, equals(1));
  });

  test('debt fully paid changes status to paid', () async {
    final updated = await useCase.execute(
      debtId: 'debt-1',
      amount: Money.fromDouble(12000),
    );

    expect(updated.status, equals(DebtStatus.paid));
    expect(updated.remainingAmount, equals(Money.zero));
  });

  test('net worth = assets - liabilities', () async {
    final debts = await repo.getAll(status: DebtStatus.active);
    final totalDebt = debts.fold(
      Money.zero,
      (acc, d) => acc + d.remainingAmount,
    );
    final assets = Money.fromDouble(20000);
    final netWorth = assets - totalDebt;

    expect(netWorth, equals(Money.fromDouble(8000)));
  });

  test('payment persists in repository', () async {
    await useCase.execute(
      debtId: 'debt-1',
      amount: Money.fromDouble(2000),
    );

    final saved = await repo.getById('debt-1');
    expect(saved!.remainingAmount, equals(Money.fromDouble(10000)));
  });

  test('throws when debt does not exist', () async {
    expect(
      () => useCase.execute(
        debtId: 'nao-existe',
        amount: Money.fromDouble(500),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('throws when payment exceeds remaining', () async {
    expect(
      () => useCase.execute(
        debtId: 'debt-1',
        amount: Money.fromDouble(12001),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
