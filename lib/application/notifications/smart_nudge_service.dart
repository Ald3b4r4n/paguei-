import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/fund.dart';

// ---------------------------------------------------------------------------
// NudgeType
// ---------------------------------------------------------------------------

enum NudgeType {
  billsDueSoon,
  billsOverdue,
  fundNearGoal,
  salaryExpected,
  spendingInsight,
}

// ---------------------------------------------------------------------------
// NudgeMessage
// ---------------------------------------------------------------------------

/// A single smart notification message to be shown to the user.
final class NudgeMessage {
  const NudgeMessage({
    required this.type,
    required this.title,
    required this.body,
    this.priority = 0,
  });

  final NudgeType type;
  final String title;
  final String body;

  /// Higher value = shown first when sorting.
  final int priority;
}

// ---------------------------------------------------------------------------
// SmartNudgeService
// ---------------------------------------------------------------------------

/// Pure static service that generates contextual [NudgeMessage] objects from
/// the current app state.
///
/// This is intentionally platform-free and state-free — all inputs are
/// supplied by the caller so the output is fully deterministic and testable.
abstract final class SmartNudgeService {
  // ── Public entry-point ───────────────────────────────────────────────────

  /// Generates a prioritised list of nudges based on [bills] and [funds].
  ///
  /// [now] defaults to `DateTime.now().toUtc()` and is injectable for testing.
  static List<NudgeMessage> generateNudges({
    required List<Bill> bills,
    required List<Fund> funds,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now().toUtc();
    final nudges = <NudgeMessage>[
      ..._billOverdueNudges(bills, ref),
      ..._billsDueSoonNudges(bills, ref),
      ..._fundNearGoalNudges(funds),
    ];

    // Sort descending by priority so most important appear first.
    nudges.sort((a, b) => b.priority.compareTo(a.priority));
    return nudges;
  }

  // ── Bill: overdue ────────────────────────────────────────────────────────

  static List<NudgeMessage> _billOverdueNudges(List<Bill> bills, DateTime now) {
    final overdue = bills
        .where((b) => !b.isPaid && !b.isCancelled && b.dueDate.isBefore(now))
        .toList();
    if (overdue.isEmpty) return [];

    final count = overdue.length;
    final body = count == 1
        ? '⚠️ "${overdue.first.title}" está vencido. Regularize agora.'
        : '⚠️ Você tem $count boletos vencidos. Regularize sua situação.';

    return [
      NudgeMessage(
        type: NudgeType.billsOverdue,
        title:
            '🚨 Boleto${count > 1 ? 's' : ''} vencido${count > 1 ? 's' : ''}',
        body: body,
        priority: 100,
      ),
    ];
  }

  // ── Bill: due soon ───────────────────────────────────────────────────────

  static List<NudgeMessage> _billsDueSoonNudges(
      List<Bill> bills, DateTime now) {
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    final in2Days = DateTime.utc(now.year, now.month, now.day + 2);

    // "Due tomorrow" — exact next calendar day
    final dueTomorrow = bills
        .where(
            (b) => !b.isPaid && !b.isCancelled && _sameDay(b.dueDate, tomorrow))
        .toList();

    // "Due in 2 days"
    final dueIn2 = bills
        .where(
            (b) => !b.isPaid && !b.isCancelled && _sameDay(b.dueDate, in2Days))
        .toList();

    final all = {...dueTomorrow, ...dueIn2}.toList();
    if (all.isEmpty) return [];

    final count = all.length;
    final String body;
    if (count == 1) {
      body = '"${all.first.title}" vence amanhã. Não esqueça de pagar!';
    } else {
      body = 'Você tem $count contas vencendo amanhã. Revise seus boletos.';
    }

    return [
      NudgeMessage(
        type: NudgeType.billsDueSoon,
        title: '📋 Boleto${count > 1 ? 's' : ''} vencendo amanhã',
        body: body,
        priority: 80,
      ),
    ];
  }

  // ── Fund: near goal ──────────────────────────────────────────────────────

  static List<NudgeMessage> _fundNearGoalNudges(List<Fund> funds) {
    // Only active (not completed), with progress ≥ 70 %
    const nearThreshold = 0.70;
    final nearFunds = funds
        .where((f) => !f.isCompleted && f.progressRate >= nearThreshold)
        .toList();
    if (nearFunds.isEmpty) return [];

    return nearFunds.map((f) {
      final remaining = f.remainingToGoal;
      final remainingStr =
          remaining.amount.toStringAsFixed(2).replaceAll('.', ',');
      final pct = (f.progressRate * 100).round();
      return NudgeMessage(
        type: NudgeType.fundNearGoal,
        title: '🎯 Meta quase atingida!',
        body: 'Faltam R\$ $remainingStr para "${f.name}" ($pct% concluído). '
            'Continue contribuindo!',
        priority: 40,
      );
    }).toList();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Salary-expected nudge builder (called by salary-day scheduler)
// ---------------------------------------------------------------------------

/// Builds a salary-expected nudge for the given [salaryDay].
NudgeMessage salaryExpectedNudge({required int salaryDay}) {
  return NudgeMessage(
    type: NudgeType.salaryExpected,
    title: '💰 Dia de salário!',
    body: 'Hoje é o dia $salaryDay — seu salário costuma cair hoje. '
        'Lembre-se de revisar seus boletos.',
    priority: 60,
  );
}
