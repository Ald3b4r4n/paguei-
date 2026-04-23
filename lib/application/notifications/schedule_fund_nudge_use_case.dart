import 'package:paguei/application/notifications/notification_recurrence_engine.dart';
import 'package:paguei/data/datasources/notifications/notification_datasource.dart';
import 'package:paguei/domain/entities/fund.dart';

/// Schedules a monthly contribution reminder for an active [Fund].
///
/// Fires on the 5th of each month at 09:00 UTC (configurable via [dayOfMonth])
/// with a smart nudge showing progress towards the fund's target.
///
/// If the fund is completed, any existing reminder is cancelled.
final class ScheduleFundNudgeUseCase {
  const ScheduleFundNudgeUseCase(this._notifications);

  final NotificationDatasource _notifications;

  Future<void> execute({
    required Fund fund,
    QuietHours? quietHours,
    int dayOfMonth = 5,
  }) async {
    if (fund.isCompleted) {
      await _cancel(fund.id);
      return;
    }

    final now = DateTime.now().toUtc();
    final daysInCurrentMonth = DateTime.utc(now.year, now.month + 1, 0).day;
    final clampedDay = dayOfMonth.clamp(1, daysInCurrentMonth);

    // Target: 5th of current month (or next month if already past)
    var target = DateTime.utc(now.year, now.month, clampedDay, 9, 0);
    if (!target.isAfter(now)) {
      // Advance to next month
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final daysNext = DateTime.utc(nextYear, nextMonth + 1, 0).day;
      target = DateTime.utc(
          nextYear, nextMonth, dayOfMonth.clamp(1, daysNext), 9, 0);
    }

    final adjusted = NotificationRecurrenceEngine.applyQuietHours(
      scheduled: target,
      quietHours: quietHours,
    );

    if (!adjusted.isAfter(now)) return;

    final remaining = fund.remainingToGoal;
    final progressPct = (fund.progressRate * 100).round();

    final body = remaining.amount > 0
        ? 'Faltam R\$ ${remaining.amount.toStringAsFixed(2).replaceAll('.', ',')} '
            'para sua meta "${fund.name}" ($progressPct% concluído).'
        : '"${fund.name}" está quase lá! Contribua hoje.';

    await _notifications.schedule(
      NotificationPayload(
        id: notificationIdFor('fund_${fund.id}'),
        title: '🎯 Lembrete de reserva',
        body: body,
        type: NotificationType.fundContributionNudge,
        scheduledAt: adjusted,
        referenceId: fund.id,
        groupKey: 'funds',
        payload: 'fund:${fund.id}',
      ),
    );
  }

  Future<void> cancel(String fundId) =>
      _notifications.cancel(notificationIdFor('fund_$fundId'));

  Future<void> _cancel(String fundId) => cancel(fundId);
}
