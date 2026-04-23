import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/bills/mark_bill_as_paid_use_case.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

import '../transactions/create_transaction_use_case_test.dart';
import 'fake_bill_repository.dart';

Bill _buildBill({
  String id = 'bill-1',
  String? accountId = 'acc-1',
  BillStatus status = BillStatus.pending,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Bill(
    id: id,
    title: 'Energia',
    amount: Money.fromDouble(120.0),
    dueDate: DateTime.utc(2026, 5, 10),
    status: status,
    accountId: accountId,
    isRecurring: false,
    reminderDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeBillRepository billRepo;
  late FakeTransactionRepository txnRepo;
  late MarkBillAsPaidUseCase useCase;

  setUp(() {
    billRepo = FakeBillRepository();
    txnRepo = FakeTransactionRepository();
    useCase = MarkBillAsPaidUseCase(billRepo, txnRepo);
  });

  group('MarkBillAsPaidUseCase', () {
    test('marca boleto como pago e retorna bill atualizado', () async {
      await billRepo.update(_buildBill());

      final paid = await useCase.execute(id: 'bill-1');

      expect(paid.status, equals(BillStatus.paid));
      expect(paid.paidAt, isNotNull);
      expect(paid.paidAmount, equals(Money.fromDouble(120.0)));
    });

    test('cria transação de despesa vinculada quando accountId está definido',
        () async {
      await billRepo.update(_buildBill(accountId: 'acc-1'));

      await useCase.execute(id: 'bill-1');

      final txns = await txnRepo.getByMonth(
        year: DateTime.now().year,
        month: DateTime.now().month,
      );
      expect(txns, isNotEmpty);
      expect(txns.first.type, equals(TransactionType.expense));
      expect(txns.first.billId, equals('bill-1'));
    });

    test('não cria transação quando accountId é nulo', () async {
      await billRepo.update(_buildBill(accountId: null));

      await useCase.execute(id: 'bill-1');

      final txns = await txnRepo.getByMonth(
        year: DateTime.now().year,
        month: DateTime.now().month,
      );
      expect(txns, isEmpty);
    });

    test('desconta paidAmount da conta quando fornecido', () async {
      txnRepo.accountBalances['acc-1'] = 50000; // R$ 500,00
      await billRepo.update(_buildBill(accountId: 'acc-1'));

      await useCase.execute(
        id: 'bill-1',
        paidAmount: Money.fromDouble(100.0),
      );

      expect(txnRepo.accountBalances['acc-1'], equals(50000 - 10000));
    });

    test('lança NotFoundException para id inexistente', () async {
      expect(
        () => useCase.execute(id: 'nao-existe'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('lança ValidationException se boleto já estiver pago', () async {
      await billRepo.update(_buildBill(status: BillStatus.paid));

      expect(
        () => useCase.execute(id: 'bill-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('lança ValidationException se boleto estiver cancelado', () async {
      await billRepo.update(_buildBill(status: BillStatus.cancelled));

      expect(
        () => useCase.execute(id: 'bill-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
