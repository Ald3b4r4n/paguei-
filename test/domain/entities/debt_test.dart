import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

Debt _buildDebt({
  String id = 'd1',
  String creditorName = 'Banco Itaú',
  double totalAmount = 12000.0,
  double remainingAmount = 12000.0,
  int? installments = 12,
  int installmentsPaid = 0,
  double? installmentAmount = 1000.0,
  DebtStatus status = DebtStatus.active,
}) {
  final now = DateTime.utc(2026, 4, 19);
  return Debt(
    id: id,
    creditorName: creditorName,
    totalAmount: Money.fromDouble(totalAmount),
    remainingAmount: Money.fromDouble(remainingAmount),
    installments: installments,
    installmentsPaid: installmentsPaid,
    installmentAmount:
        installmentAmount != null ? Money.fromDouble(installmentAmount) : null,
    interestRate: null,
    startDate: now,
    expectedEndDate: null,
    status: status,
    notes: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Debt.create', () {
    test('creates debt with valid data', () {
      final debt = Debt.create(
        id: 'd1',
        creditorName: 'Banco Itaú',
        totalAmount: Money.fromDouble(12000),
        installments: 12,
        installmentAmount: Money.fromDouble(1000),
      );

      expect(debt.id, 'd1');
      expect(debt.creditorName, 'Banco Itaú');
      expect(debt.totalAmount, Money.fromDouble(12000));
      expect(debt.remainingAmount, Money.fromDouble(12000));
      expect(debt.installmentsPaid, 0);
      expect(debt.status, DebtStatus.active);
    });

    test('throws when creditorName is empty', () {
      expect(
        () => Debt.create(
          id: 'd1',
          creditorName: '',
          totalAmount: Money.fromDouble(1000),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when creditorName exceeds 150 chars', () {
      expect(
        () => Debt.create(
          id: 'd1',
          creditorName: 'A' * 151,
          totalAmount: Money.fromDouble(1000),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when totalAmount is zero', () {
      expect(
        () => Debt.create(
          id: 'd1',
          creditorName: 'Credor',
          totalAmount: Money.zero,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when installmentAmount is negative', () {
      expect(
        () => Debt.create(
          id: 'd1',
          creditorName: 'Credor',
          totalAmount: Money.fromDouble(1000),
          installmentAmount: Money.fromDouble(-100),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Debt.registerPayment', () {
    late Debt debt;

    setUp(() {
      debt = _buildDebt(
        totalAmount: 12000,
        remainingAmount: 12000,
        installments: 12,
        installmentsPaid: 0,
        installmentAmount: 1000,
      );
    });

    test('reduces remainingAmount', () {
      final updated = debt.registerPayment(Money.fromDouble(1000));
      expect(updated.remainingAmount, Money.fromDouble(11000));
    });

    test('increments installmentsPaid', () {
      final updated = debt.registerPayment(Money.fromDouble(1000));
      expect(updated.installmentsPaid, 1);
    });

    test('changes status to paid when fully paid', () {
      final updated = debt.registerPayment(Money.fromDouble(12000));
      expect(updated.status, DebtStatus.paid);
      expect(updated.remainingAmount, Money.zero);
    });

    test('partial payment does not change status', () {
      final updated = debt.registerPayment(Money.fromDouble(1000));
      expect(updated.status, DebtStatus.active);
    });

    test('throws when payment exceeds remainingAmount', () {
      expect(
        () => debt.registerPayment(Money.fromDouble(12001)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when payment amount is zero', () {
      expect(
        () => debt.registerPayment(Money.zero),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when payment amount is negative', () {
      expect(
        () => debt.registerPayment(Money.fromDouble(-500)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Debt.progressRate', () {
    test('returns 0.0 when fully unpaid', () {
      final debt = _buildDebt(totalAmount: 12000, remainingAmount: 12000);
      expect(debt.progressRate, 0.0);
    });

    test('returns 0.5 when half paid', () {
      final debt = _buildDebt(totalAmount: 12000, remainingAmount: 6000);
      expect(debt.progressRate, closeTo(0.5, 0.001));
    });

    test('returns 1.0 when fully paid', () {
      final debt = _buildDebt(
        totalAmount: 12000,
        remainingAmount: 0,
        status: DebtStatus.paid,
      );
      expect(debt.progressRate, 1.0);
    });
  });

  group('Debt.dueDay', () {
    test('returns day of startDate', () {
      final now = DateTime.utc(2026, 4, 15);
      final debt = Debt(
        id: 'd1',
        creditorName: 'Credor',
        totalAmount: Money.fromDouble(1000),
        remainingAmount: Money.fromDouble(1000),
        installments: 12,
        installmentsPaid: 0,
        installmentAmount: Money.fromDouble(100),
        interestRate: null,
        startDate: now,
        expectedEndDate: null,
        status: DebtStatus.active,
        notes: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(debt.dueDay, 15);
    });
  });

  group('Debt.installmentsRemaining', () {
    test('returns remaining installments when set', () {
      final debt = _buildDebt(installments: 12, installmentsPaid: 4);
      expect(debt.installmentsRemaining, 8);
    });

    test('returns null when installments is null', () {
      final now = DateTime.utc(2026, 4, 19);
      final debt = Debt(
        id: 'd1',
        creditorName: 'Credor',
        totalAmount: Money.fromDouble(1000),
        remainingAmount: Money.fromDouble(1000),
        installments: null,
        installmentsPaid: 0,
        installmentAmount: null,
        interestRate: null,
        startDate: now,
        expectedEndDate: null,
        status: DebtStatus.active,
        notes: null,
        createdAt: now,
        updatedAt: now,
      );
      expect(debt.installmentsRemaining, isNull);
    });
  });
}
