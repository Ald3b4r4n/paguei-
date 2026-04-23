import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/bills/delete_bill_use_case.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_bill_repository.dart';

void main() {
  late FakeBillRepository repo;
  late DeleteBillUseCase useCase;

  setUp(() {
    repo = FakeBillRepository();
    useCase = DeleteBillUseCase(repo);
  });

  group('DeleteBillUseCase', () {
    test('remove boleto do repositório', () async {
      await repo.create(
        id: 'bill-1',
        title: 'Conta de Luz',
        amount: Money.fromDouble(120.0),
        dueDate: DateTime.utc(2026, 5, 10),
      );

      await useCase.execute('bill-1');

      final found = await repo.getById('bill-1');
      expect(found, isNull);
    });

    test('não lança exceção para id inexistente', () async {
      await expectLater(
        () => useCase.execute('nao-existe'),
        returnsNormally,
      );
    });
  });
}
