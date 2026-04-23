import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/notifications/notification_recurrence_engine.dart';

void main() {
  group('NotificationRecurrenceEngine', () {
    // Reference: Monday, 2026-04-20 09:00 UTC
    final base = DateTime.utc(2026, 4, 20, 9, 0);
    const quietHours = QuietHours(startHour: 22, endHour: 8);

    // ── nextOccurrence ─────────────────────────────────────────────────────

    group('nextOccurrence — daily', () {
      test('adds exactly 1 day', () {
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: base,
          rule: const RecurrenceRule.daily(),
        );
        expect(next, DateTime.utc(2026, 4, 21, 9, 0));
      });
    });

    group('nextOccurrence — weekly', () {
      test('adds exactly 7 days', () {
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: base,
          rule: const RecurrenceRule.weekly(),
        );
        expect(next, DateTime.utc(2026, 4, 27, 9, 0));
      });
    });

    group('nextOccurrence — monthly', () {
      test('advances month by 1, same day', () {
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: DateTime.utc(2026, 1, 15, 9, 0),
          rule: const RecurrenceRule.monthly(),
        );
        expect(next, DateTime.utc(2026, 2, 15, 9, 0));
      });

      test('month edge: day 31 in February clamps to last day (28)', () {
        final from = DateTime.utc(2026, 1, 31, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.monthly(),
        );
        // Feb 2026 has 28 days
        expect(next.month, 2);
        expect(next.day, 28);
      });

      test('month edge: day 31 in April → clamps to 30', () {
        final from = DateTime.utc(2026, 3, 31, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.monthly(),
        );
        expect(next.month, 4);
        expect(next.day, 30);
      });

      test('Dec → Jan crosses year boundary', () {
        final from = DateTime.utc(2026, 12, 15, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.monthly(),
        );
        expect(next.year, 2027);
        expect(next.month, 1);
        expect(next.day, 15);
      });
    });

    group('nextOccurrence — customDayOfMonth', () {
      test('same month when target day is in the future', () {
        // from = April 5; target = day 10 → April 10
        final from = DateTime.utc(2026, 4, 5, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.customDayOfMonth(10),
        );
        expect(next, DateTime.utc(2026, 4, 10, 9, 0));
      });

      test('next month when target day already passed', () {
        // from = April 20; target = day 5 → May 5
        final from = DateTime.utc(2026, 4, 20, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.customDayOfMonth(5),
        );
        expect(next, DateTime.utc(2026, 5, 5, 9, 0));
      });

      test('day 31 in months with <31 days → last day of month', () {
        // from = April 5; target = day 31 → April 30 (max in April)
        final from = DateTime.utc(2026, 4, 5, 9, 0);
        final next = NotificationRecurrenceEngine.nextOccurrence(
          from: from,
          rule: const RecurrenceRule.customDayOfMonth(31),
        );
        expect(next.month, 4);
        expect(next.day, 30);
      });
    });

    // ── Quiet hours ────────────────────────────────────────────────────────

    group('applyQuietHours', () {
      test('time within quiet hours (23:00) advances to startHour next day',
          () {
        // QuietHours: 22–08. A scheduled time at 23:00 should move to 08:00
        // next day.
        final scheduled = DateTime.utc(2026, 4, 20, 23, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: quietHours,
        );
        expect(adjusted.hour, 8);
        expect(adjusted.day, 21);
      });

      test('time within quiet hours (03:00) advances to 08:00 same day', () {
        final scheduled = DateTime.utc(2026, 4, 20, 3, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: quietHours,
        );
        expect(adjusted.hour, 8);
        expect(adjusted.day, 20);
      });

      test('time outside quiet hours is unchanged', () {
        final scheduled = DateTime.utc(2026, 4, 20, 10, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: quietHours,
        );
        expect(adjusted, scheduled);
      });

      test('exact boundary (08:00) is considered outside quiet hours', () {
        final scheduled = DateTime.utc(2026, 4, 20, 8, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: quietHours,
        );
        expect(adjusted, scheduled);
      });

      test('exact boundary (22:00) is considered inside quiet hours', () {
        final scheduled = DateTime.utc(2026, 4, 20, 22, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: quietHours,
        );
        expect(adjusted.hour, 8);
        expect(adjusted.day, 21);
      });

      test('null quietHours returns unchanged time', () {
        final scheduled = DateTime.utc(2026, 4, 20, 23, 0);
        final adjusted = NotificationRecurrenceEngine.applyQuietHours(
          scheduled: scheduled,
          quietHours: null,
        );
        expect(adjusted, scheduled);
      });
    });

    // ── scheduleDates ──────────────────────────────────────────────────────

    group('scheduleDates', () {
      test('returns at most maxCount dates', () {
        final dates = NotificationRecurrenceEngine.scheduleDates(
          first: base,
          rule: const RecurrenceRule.daily(),
          maxCount: 5,
          horizon: base.add(const Duration(days: 365)),
        );
        expect(dates.length, 5);
      });

      test('stops at horizon', () {
        final horizon = base.add(const Duration(days: 3));
        final dates = NotificationRecurrenceEngine.scheduleDates(
          first: base,
          rule: const RecurrenceRule.daily(),
          maxCount: 100,
          horizon: horizon,
        );
        // base, +1d, +2d — +3d is excluded (horizon is exclusive)
        expect(dates.length, 3);
      });

      test('all dates after first are in ascending order', () {
        final dates = NotificationRecurrenceEngine.scheduleDates(
          first: base,
          rule: const RecurrenceRule.weekly(),
          maxCount: 4,
          horizon: base.add(const Duration(days: 365)),
        );
        for (var i = 1; i < dates.length; i++) {
          expect(dates[i].isAfter(dates[i - 1]), isTrue);
        }
      });

      test('respects quiet hours across all generated dates', () {
        // All times start at 23:00 — every date should be moved to 08:00
        final first = DateTime.utc(2026, 4, 20, 23, 0);
        final dates = NotificationRecurrenceEngine.scheduleDates(
          first: first,
          rule: const RecurrenceRule.daily(),
          maxCount: 3,
          horizon: first.add(const Duration(days: 10)),
          quietHours: quietHours,
        );
        for (final d in dates) {
          expect(d.hour, 8);
        }
      });
    });

    // ── billReminderTime ───────────────────────────────────────────────────

    group('billReminderTime', () {
      test('returns dueDate minus reminderDays at given hour', () {
        final due = DateTime.utc(2026, 5, 10, 15, 0);
        final reminder = NotificationRecurrenceEngine.billReminderTime(
          dueDate: due,
          daysBefore: 3,
          reminderHour: 9,
        );
        expect(reminder, DateTime.utc(2026, 5, 7, 9, 0));
      });

      test('0 days before = same day as due', () {
        final due = DateTime.utc(2026, 5, 10, 15, 0);
        final reminder = NotificationRecurrenceEngine.billReminderTime(
          dueDate: due,
          daysBefore: 0,
          reminderHour: 9,
        );
        expect(reminder, DateTime.utc(2026, 5, 10, 9, 0));
      });
    });
  });
}
