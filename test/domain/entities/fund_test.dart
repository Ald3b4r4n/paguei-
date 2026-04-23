import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

void main() {
  group('Fund.create', () {
    test('creates fund with valid data', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Reserva de Emergência',
        type: FundType.emergency,
        targetAmount: Money.fromDouble(10000),
        color: 0xFF1B4332,
        icon: 'savings',
      );

      expect(fund.id, 'f1');
      expect(fund.name, 'Reserva de Emergência');
      expect(fund.type, FundType.emergency);
      expect(fund.targetAmount, Money.fromDouble(10000));
      expect(fund.currentAmount, Money.zero);
      expect(fund.isCompleted, isFalse);
    });

    test('throws when name is empty', () {
      expect(
        () => Fund.create(
          id: 'f1',
          name: '',
          type: FundType.emergency,
          targetAmount: Money.fromDouble(10000),
          color: 0xFF1B4332,
          icon: 'savings',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when name is whitespace only', () {
      expect(
        () => Fund.create(
          id: 'f1',
          name: '   ',
          type: FundType.emergency,
          targetAmount: Money.fromDouble(10000),
          color: 0xFF1B4332,
          icon: 'savings',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when name exceeds 100 chars', () {
      expect(
        () => Fund.create(
          id: 'f1',
          name: 'A' * 101,
          type: FundType.emergency,
          targetAmount: Money.fromDouble(10000),
          color: 0xFF1B4332,
          icon: 'savings',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when targetAmount is zero', () {
      expect(
        () => Fund.create(
          id: 'f1',
          name: 'Meta',
          type: FundType.goal,
          targetAmount: Money.zero,
          color: 0xFF1B4332,
          icon: 'savings',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when targetAmount is negative', () {
      expect(
        () => Fund.create(
          id: 'f1',
          name: 'Meta',
          type: FundType.goal,
          targetAmount: Money.fromDouble(-100),
          color: 0xFF1B4332,
          icon: 'savings',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Fund.contribute', () {
    late Fund fund;

    setUp(() {
      fund = Fund.create(
        id: 'f1',
        name: 'Reserva de Emergência',
        type: FundType.emergency,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      );
    });

    test('increases currentAmount', () {
      final updated = fund.contribute(Money.fromDouble(500));
      expect(updated.currentAmount, Money.fromDouble(500));
    });

    test('multiple contributions accumulate', () {
      final after1 = fund.contribute(Money.fromDouble(300));
      final after2 = after1.contribute(Money.fromDouble(200));
      expect(after2.currentAmount, Money.fromDouble(500));
    });

    test('marks isCompleted when reaches target', () {
      final updated = fund.contribute(Money.fromDouble(1000));
      expect(updated.isCompleted, isTrue);
    });

    test('marks isCompleted when exceeds target', () {
      final updated = fund.contribute(Money.fromDouble(1500));
      expect(updated.isCompleted, isTrue);
    });

    test('does not mark completed when below target', () {
      final updated = fund.contribute(Money.fromDouble(999));
      expect(updated.isCompleted, isFalse);
    });

    test('throws when contribution amount is zero', () {
      expect(
        () => fund.contribute(Money.zero),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when contribution amount is negative', () {
      expect(
        () => fund.contribute(Money.fromDouble(-50)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Fund.withdraw', () {
    late Fund fund;

    setUp(() {
      fund = Fund.create(
        id: 'f1',
        name: 'Reserva de Emergência',
        type: FundType.emergency,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(800));
    });

    test('decreases currentAmount', () {
      final updated = fund.withdraw(Money.fromDouble(300));
      expect(updated.currentAmount, Money.fromDouble(500));
    });

    test('allows withdrawing full balance', () {
      final updated = fund.withdraw(Money.fromDouble(800));
      expect(updated.currentAmount, Money.zero);
    });

    test('throws when withdraw exceeds balance', () {
      expect(
        () => fund.withdraw(Money.fromDouble(801)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when withdraw amount is zero', () {
      expect(
        () => fund.withdraw(Money.zero),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when withdraw amount is negative', () {
      expect(
        () => fund.withdraw(Money.fromDouble(-50)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('unsets isCompleted after withdrawal below target', () {
      final completed = fund.contribute(Money.fromDouble(200));
      expect(completed.isCompleted, isTrue);
      final afterWithdraw = completed.withdraw(Money.fromDouble(1));
      expect(afterWithdraw.isCompleted, isFalse);
    });
  });

  group('Fund.progressRate', () {
    test('returns 0.0 when currentAmount is zero', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      );
      expect(fund.progressRate, 0.0);
    });

    test('returns 0.5 when half funded', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(500));
      expect(fund.progressRate, closeTo(0.5, 0.001));
    });

    test('returns 1.0 when exactly at target', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(1000));
      expect(fund.progressRate, 1.0);
    });

    test('clamps to 1.0 when over target', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(2000));
      expect(fund.progressRate, 1.0);
    });
  });

  group('Fund.remainingToGoal', () {
    test('returns full target when empty', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      );
      expect(fund.remainingToGoal, Money.fromDouble(1000));
    });

    test('returns difference when partially funded', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(300));
      expect(fund.remainingToGoal, Money.fromDouble(700));
    });

    test('returns zero when completed', () {
      final fund = Fund.create(
        id: 'f1',
        name: 'Meta',
        type: FundType.goal,
        targetAmount: Money.fromDouble(1000),
        color: 0xFF1B4332,
        icon: 'savings',
      ).contribute(Money.fromDouble(1000));
      expect(fund.remainingToGoal, Money.zero);
    });
  });
}
