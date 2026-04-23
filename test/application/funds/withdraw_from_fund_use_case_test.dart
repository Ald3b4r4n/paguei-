import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/funds/contribute_fund_use_case.dart';
import 'package:paguei/application/funds/withdraw_from_fund_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_fund_repository.dart';

void main() {
  late FakeFundRepository repo;
  late ContributeFundUseCase contribute;
  late WithdrawFromFundUseCase withdraw;

  setUp(() async {
    repo = FakeFundRepository();
    contribute = ContributeFundUseCase(repo);
    withdraw = WithdrawFromFundUseCase(repo);

    await repo.create(
      id: 'fund-1',
      name: 'Reserva de Emergência',
      type: FundType.emergency,
      targetAmount: Money.fromDouble(10000),
    );
    await contribute.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(5000),
    );
  });

  test('withdraw decreases fund safely', () async {
    final updated = await withdraw.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(2000),
    );

    expect(updated.currentAmount, equals(Money.fromDouble(3000)));
  });

  test('withdraw full balance leaves zero', () async {
    final updated = await withdraw.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(5000),
    );

    expect(updated.currentAmount, equals(Money.zero));
  });

  test('withdraw more than balance throws', () async {
    expect(
      () => withdraw.execute(
        fundId: 'fund-1',
        amount: Money.fromDouble(5001),
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('withdraw persists in repository', () async {
    await withdraw.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(1000),
    );

    final saved = await repo.getById('fund-1');
    expect(saved!.currentAmount, equals(Money.fromDouble(4000)));
  });
}
