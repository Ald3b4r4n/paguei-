import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/funds/contribute_fund_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_fund_repository.dart';

void main() {
  late FakeFundRepository repo;
  late ContributeFundUseCase useCase;

  setUp(() async {
    repo = FakeFundRepository();
    useCase = ContributeFundUseCase(repo);

    await repo.create(
      id: 'fund-1',
      name: 'Reserva de Emergência',
      type: FundType.emergency,
      targetAmount: Money.fromDouble(10000),
    );
  });

  test('contribute increases fund currentAmount', () async {
    final updated = await useCase.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(500),
    );

    expect(updated.currentAmount, equals(Money.fromDouble(500)));
  });

  test('contribute marks completed when reaches target', () async {
    final updated = await useCase.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(10000),
    );

    expect(updated.isCompleted, isTrue);
  });

  test('contribute persists updated fund in repository', () async {
    await useCase.execute(
      fundId: 'fund-1',
      amount: Money.fromDouble(300),
    );

    final saved = await repo.getById('fund-1');
    expect(saved!.currentAmount, equals(Money.fromDouble(300)));
  });

  test('throws when fund does not exist', () async {
    expect(
      () => useCase.execute(
        fundId: 'nao-existe',
        amount: Money.fromDouble(100),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
