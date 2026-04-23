import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/bills/create_bill_use_case.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_bill_repository.dart';

void main() {
  late FakeBillRepository repo;
  late CreateBillUseCase useCase;

  setUp(() {
    repo = FakeBillRepository();
    useCase = CreateBillUseCase(repo);
  });

  group('CreateBillUseCase', () {
    test('cria boleto e persiste no repositório', () async {
      final bill = await useCase.execute(
        id: 'bill-1',
        title: 'Energia Elétrica',
        amount: Money.fromDouble(120.0),
        dueDate: DateTime.utc(2026, 5, 10),
      );

      expect(bill.id, equals('bill-1'));
      expect(bill.title, equals('Energia Elétrica'));
      expect(bill.amount, equals(Money.fromDouble(120.0)));
      expect(bill.status, equals(BillStatus.pending));
    });

    test('boleto criado tem accountId quando fornecido', () async {
      final bill = await useCase.execute(
        id: 'bill-2',
        title: 'Água',
        amount: Money.fromDouble(80.0),
        dueDate: DateTime.utc(2026, 5, 15),
        accountId: 'acc-1',
      );
      expect(bill.accountId, equals('acc-1'));
    });

    test('repositório contém o boleto após criação', () async {
      await useCase.execute(
        id: 'bill-3',
        title: 'Internet',
        amount: Money.fromDouble(99.90),
        dueDate: DateTime.utc(2026, 5, 20),
      );
      final found = await repo.getById('bill-3');
      expect(found, isNotNull);
    });

    test('delega validação de amount para a entidade', () async {
      await expectLater(
        () => useCase.execute(
          id: 'bill-4',
          title: 'Boleto',
          amount: Money.zero,
          dueDate: DateTime.utc(2026, 5, 10),
        ),
        throwsException,
      );
    });
  });
}
