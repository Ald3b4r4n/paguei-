import 'package:paguei/application/notifications/notification_recurrence_engine.dart';
import 'package:paguei/core/constants/app_constants.dart';
import 'package:paguei/data/datasources/notifications/notification_datasource.dart';
import 'package:paguei/domain/entities/bill.dart';

/// Cancels any existing reminders for [bill] and schedules new ones based on
/// [bill.reminderDaysBefore] and the bill's due date.
///
/// Two notifications are scheduled per bill:
/// - N days before due date ("Boleto X vence em N dias")
/// - On the due date itself ("Boleto X vence hoje!")
///
/// Overdue alerts are handled separately by [ScheduleOverdueAlertsUseCase]
/// which runs on app-foreground.
final class ScheduleBillRemindersUseCase {
  const ScheduleBillRemindersUseCase(this._notifications);

  final NotificationDatasource _notifications;

  Future<void> execute({
    required Bill bill,
    QuietHours? quietHours,
  }) async {
    if (bill.isPaid || bill.isCancelled) {
      // Nothing to schedule for settled bills.
      await _cancelExisting(bill.id);
      return;
    }

    final now = DateTime.now().toUtc();

    // ── N days before reminder ─────────────────────────────────────────────
    if (bill.reminderDaysBefore > 0) {
      final advanceTime = NotificationRecurrenceEngine.billReminderTime(
        dueDate: bill.dueDate,
        daysBefore: bill.reminderDaysBefore,
        reminderHour: 9,
      );
      final adjusted = NotificationRecurrenceEngine.applyQuietHours(
        scheduled: advanceTime,
        quietHours: quietHours,
      );

      if (adjusted.isAfter(now)) {
        await _notifications.schedule(
          NotificationPayload(
            id: notificationIdFor('${bill.id}_advance'),
            title: '📋 Boleto vencendo em breve',
            body: '${bill.title} vence em ${bill.reminderDaysBefore} '
                '${bill.reminderDaysBefore == 1 ? 'dia' : 'dias'}.',
            type: NotificationType.billDueTomorrow,
            scheduledAt: adjusted,
            referenceId: bill.id,
            groupKey: 'bills_due',
            payload: 'bill:${bill.id}',
          ),
        );
      }
    }

    // ── Due-today reminder ─────────────────────────────────────────────────
    final dueTodayTime = NotificationRecurrenceEngine.billReminderTime(
      dueDate: bill.dueDate,
      daysBefore: 0,
      reminderHour: 9,
    );
    final dueTodayAdjusted = NotificationRecurrenceEngine.applyQuietHours(
      scheduled: dueTodayTime,
      quietHours: quietHours,
    );

    if (dueTodayAdjusted.isAfter(now)) {
      await _notifications.schedule(
        NotificationPayload(
          id: notificationIdFor('${bill.id}_today'),
          title: '⚠️ Boleto vence hoje!',
          body: '${bill.title} — '
              'R\$ ${bill.amount.amount.toStringAsFixed(2).replaceAll('.', ',')}.',
          type: NotificationType.billDueToday,
          scheduledAt: dueTodayAdjusted,
          referenceId: bill.id,
          groupKey: 'bills_due',
          payload: 'bill:${bill.id}',
        ),
      );
    }
  }

  /// Schedule reminders for a batch of bills, respecting [AppConstants.maxNotificationsScheduled].
  Future<void> executeBatch({
    required List<Bill> bills,
    QuietHours? quietHours,
  }) async {
    // Sort pending bills by due date ascending to prioritise nearest first.
    final pending = bills.where((b) => !b.isPaid && !b.isCancelled).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Cancel all existing bill reminders before rescheduling.
    for (final bill in bills) {
      await _cancelExisting(bill.id);
    }

    // Each bill takes up to 2 notification slots.
    final maxBills = AppConstants.maxNotificationsScheduled ~/ 2;
    final toSchedule = pending.take(maxBills);

    for (final bill in toSchedule) {
      await execute(bill: bill, quietHours: quietHours);
    }
  }

  Future<void> _cancelExisting(String billId) async {
    await _notifications.cancel(notificationIdFor('${billId}_advance'));
    await _notifications.cancel(notificationIdFor('${billId}_today'));
  }
}
