import 'package:paguei/application/notifications/notification_recurrence_engine.dart';
import 'package:paguei/data/datasources/notifications/notification_datasource.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';

/// Schedules a monthly reminder for the next installment of a [Debt].
///
/// The reminder fires [advanceDays] before [debt.dueDay] in the current or
/// next month at 09:00 UTC, nudging the user before the installment falls due.
final class ScheduleDebtReminderUseCase {
  const ScheduleDebtReminderUseCase(this._notifications);

  final NotificationDatasource _notifications;

  Future<void> execute({
    required Debt debt,
    QuietHours? quietHours,
    int advanceDays = 3,
  }) async {
    if (debt.status != DebtStatus.active) {
      await _cancel(debt.id);
      return;
    }

    final now = DateTime.now().toUtc();

    // ── Find the next due date ─────────────────────────────────────────────
    final dueThisMonth = _dueDateInMonth(debt.dueDay, now.year, now.month);
    final effectiveDue =
        dueThisMonth.isAfter(now) ? dueThisMonth : _addOneMonth(dueThisMonth);

    // ── Compute reminder time ──────────────────────────────────────────────
    final raw = effectiveDue.subtract(Duration(days: advanceDays));
    final reminderAtNine = DateTime.utc(raw.year, raw.month, raw.day, 9, 0);
    final adjusted = NotificationRecurrenceEngine.applyQuietHours(
      scheduled: reminderAtNine,
      quietHours: quietHours,
    );

    if (!adjusted.isAfter(now)) return; // already passed, skip

    final installmentLabel = debt.installments != null
        ? '${debt.installmentsPaid + 1}/${debt.installments}'
        : '${debt.installmentsPaid + 1}';

    await _notifications.schedule(
      NotificationPayload(
        id: notificationIdFor('debt_${debt.id}'),
        title: '💳 Parcela a vencer',
        body: '${debt.creditorName}: parcela $installmentLabel '
            'vence em $advanceDays ${advanceDays == 1 ? 'dia' : 'dias'}.',
        type: NotificationType.debtInstallmentReminder,
        scheduledAt: adjusted,
        referenceId: debt.id,
        groupKey: 'debts',
        payload: 'debt:${debt.id}',
      ),
    );
  }

  Future<void> cancel(String debtId) =>
      _notifications.cancel(notificationIdFor('debt_$debtId'));

  Future<void> _cancel(String debtId) => cancel(debtId);

  /// Returns a [DateTime] for [dueDay] in the given [year]/[month], clamped
  /// to the actual number of days in that month.
  static DateTime _dueDateInMonth(int dueDay, int year, int month) {
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    final day = dueDay.clamp(1, daysInMonth);
    return DateTime.utc(year, month, day, 9, 0);
  }

  /// Returns [d] advanced by exactly one calendar month, clamping the day.
  static DateTime _addOneMonth(DateTime d) {
    final nextMonth = d.month == 12 ? 1 : d.month + 1;
    final nextYear = d.month == 12 ? d.year + 1 : d.year;
    final daysInNext = DateTime.utc(nextYear, nextMonth + 1, 0).day;
    return DateTime.utc(nextYear, nextMonth, d.day.clamp(1, daysInNext), 9, 0);
  }
}
