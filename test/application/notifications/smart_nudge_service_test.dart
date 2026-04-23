import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/notifications/smart_nudge_service.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Bill _bill({
  required String id,
  required String title,
  required double amount,
  required DateTime dueDate,
  BillStatus status = BillStatus.pending,
}) {
  final now = DateTime.now().toUtc();
  return Bill(
    id: id,
    title: title,
    amount: Money.fromDouble(amount),
    dueDate: dueDate,
    status: status,
    isRecurring: false,
    reminderDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
  );
}

Fund _fund({
  required String id,
  required String name,
  required double target,
  required double current,
  bool isCompleted = false,
}) {
  final now = DateTime.now().toUtc();
  return Fund(
    id: id,
    name: name,
    type: FundType.emergency,
    targetAmount: Money.fromDouble(target),
    currentAmount: Money.fromDouble(current),
    color: 0xFF2D6A4F,
    icon: 'savings',
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final today = DateTime.now().toUtc();
  final tomorrow = today.add(const Duration(days: 1));
  final _ = today.add(const Duration(days: 2));

  group('SmartNudgeService.generateNudges', () {
    // ── Bill nudges ─────────────────────────────────────────────────────────

    test('returns "vencendo amanhã" nudge for bills due tomorrow', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Conta de luz',
          amount: 150.0,
          dueDate: tomorrow,
        ),
        _bill(
          id: '2',
          title: 'Internet',
          amount: 89.90,
          dueDate: tomorrow,
        ),
      ];

      final nudges = SmartNudgeService.generateNudges(
        bills: bills,
        funds: [],
        now: today,
      );

      expect(nudges, isNotEmpty);
      final dueSoonNudge = nudges.firstWhere(
        (n) => n.type == NudgeType.billsDueSoon,
        orElse: () => throw StateError('Missing billsDueSoon nudge'),
      );
      expect(dueSoonNudge.body, contains('2'));
      expect(dueSoonNudge.body.toLowerCase(), contains('amanhã'));
    });

    test('returns single bill nudge with bill title when only 1 bill due', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Fatura Cartão',
          amount: 300.0,
          dueDate: tomorrow,
        ),
      ];

      final nudges = SmartNudgeService.generateNudges(
        bills: bills,
        funds: [],
        now: today,
      );

      final nudge = nudges.firstWhere((n) => n.type == NudgeType.billsDueSoon);
      // Single bill should mention its title
      expect(nudge.body, contains('Fatura Cartão'));
    });

    test('does not include paid or cancelled bills in due-soon count', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Boleto Pago',
          amount: 100.0,
          dueDate: tomorrow,
          status: BillStatus.paid,
        ),
        _bill(
          id: '2',
          title: 'Boleto Cancelado',
          amount: 100.0,
          dueDate: tomorrow,
          status: BillStatus.cancelled,
        ),
      ];

      final nudges = SmartNudgeService.generateNudges(
        bills: bills,
        funds: [],
        now: today,
      );

      expect(
        nudges.where((n) => n.type == NudgeType.billsDueSoon),
        isEmpty,
      );
    });

    test('overdue nudge is returned when bills are overdue', () {
      final overdueBill = _bill(
        id: '1',
        title: 'Conta vencida',
        amount: 200.0,
        dueDate: today.subtract(const Duration(days: 2)),
        status: BillStatus.pending,
      );

      final nudges = SmartNudgeService.generateNudges(
        bills: [overdueBill],
        funds: [],
        now: today,
      );

      expect(
        nudges.any((n) => n.type == NudgeType.billsOverdue),
        isTrue,
      );
    });

    // ── Fund nudges ─────────────────────────────────────────────────────────

    test('returns fund-progress nudge when fund is close to goal (>= 70%)', () {
      final fund = _fund(
        id: 'f1',
        name: 'Reserva de emergência',
        target: 10000.0,
        current: 7500.0, // 75%
      );

      final nudges = SmartNudgeService.generateNudges(
        bills: [],
        funds: [fund],
        now: today,
      );

      expect(nudges.any((n) => n.type == NudgeType.fundNearGoal), isTrue);
    });

    test('fund nudge contains remaining amount', () {
      final fund = _fund(
        id: 'f1',
        name: 'Viagem',
        target: 5000.0,
        current: 4700.0, // R$ 300 remaining
      );

      final nudges = SmartNudgeService.generateNudges(
        bills: [],
        funds: [fund],
        now: today,
      );

      final nudge = nudges.firstWhere(
        (n) => n.type == NudgeType.fundNearGoal,
        orElse: () => throw StateError('Missing fundNearGoal nudge'),
      );
      expect(nudge.body, contains('300'));
      expect(nudge.body, contains('Viagem'));
    });

    test('does not return fund nudge for completed funds', () {
      final fund = _fund(
        id: 'f1',
        name: 'Meta concluída',
        target: 1000.0,
        current: 1000.0,
        isCompleted: true,
      );

      final nudges = SmartNudgeService.generateNudges(
        bills: [],
        funds: [fund],
        now: today,
      );

      expect(nudges.any((n) => n.type == NudgeType.fundNearGoal), isFalse);
    });

    // ── General ─────────────────────────────────────────────────────────────

    test('returns empty list when no bills or funds', () {
      final nudges = SmartNudgeService.generateNudges(
        bills: [],
        funds: [],
        now: today,
      );
      expect(nudges, isEmpty);
    });

    test('each nudge has non-empty title and body', () {
      final bills = [
        _bill(id: '1', title: 'Aluguel', amount: 1200.0, dueDate: tomorrow),
      ];
      final nudges = SmartNudgeService.generateNudges(
        bills: bills,
        funds: [],
        now: today,
      );
      for (final nudge in nudges) {
        expect(nudge.title, isNotEmpty);
        expect(nudge.body, isNotEmpty);
      }
    });

    test('nudges are sorted by priority descending', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Vencido',
          amount: 100.0,
          dueDate: today.subtract(const Duration(days: 1)),
        ),
        _bill(id: '2', title: 'Amanhã', amount: 100.0, dueDate: tomorrow),
      ];

      final nudges = SmartNudgeService.generateNudges(
        bills: bills,
        funds: [],
        now: today,
      );

      // Overdue should come before due-soon
      final overdueIdx =
          nudges.indexWhere((n) => n.type == NudgeType.billsOverdue);
      final dueSoonIdx =
          nudges.indexWhere((n) => n.type == NudgeType.billsDueSoon);

      if (overdueIdx >= 0 && dueSoonIdx >= 0) {
        expect(overdueIdx, lessThan(dueSoonIdx));
      }
    });
  });
}
