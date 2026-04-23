import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/bills/get_bills_by_status_use_case.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

import 'fake_bill_repository.dart';

void main() {
  late FakeBillRepository repo;
  late GetBillsByStatusUseCase useCase;

  setUp(() async {
    repo = FakeBillRepository();
    useCase = GetBillsByStatusUseCase(repo);

    await repo.create(
      id: 'bill-1',
      title: 'Energia',
      amount: Money.fromDouble(120.0),
      dueDate: DateTime.now().toUtc().add(const Duration(days: 5)),
    );
    await repo.create(
      id: 'bill-2',
      title: 'Internet',
      amount: Money.fromDouble(99.90),
      dueDate: DateTime.now().toUtc().add(const Duration(days: 15)),
    );
    final paidBill = await repo.create(
      id: 'bill-3',
      title: 'Água',
      amount: Money.fromDouble(50.0),
      dueDate: DateTime.now().toUtc().subtract(const Duration(days: 2)),
    );
    await repo.markAsPaid(id: paidBill.id);
  });

  group('GetBillsByStatusUseCase', () {
    test('execute(pending) retorna apenas boletos pendentes', () async {
      final result = await useCase.execute(BillStatus.pending);
      expect(result.length, equals(2));
      expect(result.every((b) => b.status == BillStatus.pending), isTrue);
    });

    test('execute(paid) retorna apenas boletos pagos', () async {
      final result = await useCase.execute(BillStatus.paid);
      expect(result.length, equals(1));
      expect(result.first.title, equals('Água'));
    });

    test('getPending retorna boletos pending e overdue', () async {
      final result = await useCase.getPending();
      expect(result.length, equals(2));
    });

    test('getDueSoon retorna boletos vencendo nos próximos 7 dias', () async {
      final result = await useCase.getDueSoon(days: 7);
      expect(result, isNotEmpty);
      expect(result.every((b) => b.title == 'Energia'), isTrue);
    });

    test('watchPending retorna stream de boletos pendentes', () async {
      final result = await useCase.watchPending().first;
      expect(result.length, equals(2));
    });
  });
}
