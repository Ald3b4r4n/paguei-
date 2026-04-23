/// Recurrence engine for notification scheduling.
///
/// Entirely pure Dart — no Flutter, no platform channels, no timezone
/// package required. All times are handled as UTC [DateTime] so the engine
/// is fully unit-testable without a test device.
///
/// Callers (use cases, services) convert to [tz.TZDateTime] only at the
/// datasource boundary, just before handing off to flutter_local_notifications.
library;

// ---------------------------------------------------------------------------
// RecurrenceRule
// ---------------------------------------------------------------------------

/// Represents how often a notification should repeat.
sealed class RecurrenceRule {
  const RecurrenceRule();

  const factory RecurrenceRule.daily() = DailyRule;
  const factory RecurrenceRule.weekly() = WeeklyRule;
  const factory RecurrenceRule.monthly() = MonthlyRule;

  /// Repeat on a specific day of the month (1–31).
  /// If [day] exceeds the month length, it is clamped to the last day.
  const factory RecurrenceRule.customDayOfMonth(int day) = CustomDayOfMonthRule;
}

final class DailyRule extends RecurrenceRule {
  const DailyRule();
}

final class WeeklyRule extends RecurrenceRule {
  const WeeklyRule();
}

final class MonthlyRule extends RecurrenceRule {
  const MonthlyRule();
}

final class CustomDayOfMonthRule extends RecurrenceRule {
  const CustomDayOfMonthRule(this.day)
      : assert(day >= 1 && day <= 31, 'day must be 1–31');
  final int day;
}

// ---------------------------------------------------------------------------
// QuietHours
// ---------------------------------------------------------------------------

/// A window during which notifications should not be delivered.
///
/// Both [startHour] and [endHour] are expressed in UTC 24-hour format (0–23).
/// The window may wrap midnight: e.g. `startHour=22, endHour=8` means 22:00
/// to 08:00 the following day.
final class QuietHours {
  const QuietHours({required this.startHour, required this.endHour})
      : assert(startHour >= 0 && startHour <= 23),
        assert(endHour >= 0 && endHour <= 23);

  final int startHour;
  final int endHour;

  /// Returns true if [hour] falls within this quiet window.
  bool contains(int hour) {
    if (startHour < endHour) {
      // Non-wrapping window: e.g. 08–22
      return hour >= startHour && hour < endHour;
    } else {
      // Wrapping window: e.g. 22–08
      return hour >= startHour || hour < endHour;
    }
  }
}

// ---------------------------------------------------------------------------
// NotificationRecurrenceEngine
// ---------------------------------------------------------------------------

/// Static utility for computing notification schedule dates.
abstract final class NotificationRecurrenceEngine {
  // ── nextOccurrence ───────────────────────────────────────────────────────

  /// Returns the next occurrence after [from] according to [rule].
  ///
  /// The result preserves the hour/minute of [from] except when the
  /// [CustomDayOfMonthRule] selects a different day.
  static DateTime nextOccurrence({
    required DateTime from,
    required RecurrenceRule rule,
  }) =>
      switch (rule) {
        DailyRule() => from.add(const Duration(days: 1)),
        WeeklyRule() => from.add(const Duration(days: 7)),
        MonthlyRule() => _addMonth(from),
        CustomDayOfMonthRule(:final day) =>
          _nextCustomDay(from: from, targetDay: day),
      };

  // ── applyQuietHours ──────────────────────────────────────────────────────

  /// Pushes [scheduled] forward to the first allowed time when it falls
  /// inside [quietHours]. Returns [scheduled] unchanged if [quietHours] is
  /// null or if [scheduled] is already outside the window.
  static DateTime applyQuietHours({
    required DateTime scheduled,
    required QuietHours? quietHours,
  }) {
    if (quietHours == null) return scheduled;
    if (!quietHours.contains(scheduled.hour)) return scheduled;

    // Advance to the end of the quiet window.
    final endHour = quietHours.endHour;
    if (scheduled.hour < endHour) {
      // Quiet window extends past midnight and we're in the early-morning
      // portion → move to endHour of the same day.
      return DateTime.utc(
        scheduled.year,
        scheduled.month,
        scheduled.day,
        endHour,
        0,
      );
    } else {
      // We're in the evening portion → move to endHour of the next day.
      final next = DateTime.utc(
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        endHour,
        0,
      );
      return next;
    }
  }

  // ── scheduleDates ────────────────────────────────────────────────────────

  /// Generates up to [maxCount] scheduled dates starting at [first],
  /// stopping when a date would exceed [horizon] (exclusive).
  ///
  /// Each date is adjusted for [quietHours] if provided.
  static List<DateTime> scheduleDates({
    required DateTime first,
    required RecurrenceRule rule,
    required int maxCount,
    required DateTime horizon,
    QuietHours? quietHours,
  }) {
    final dates = <DateTime>[];
    var current = applyQuietHours(scheduled: first, quietHours: quietHours);

    while (dates.length < maxCount && current.isBefore(horizon)) {
      dates.add(current);
      final rawNext = nextOccurrence(from: current, rule: rule);
      current = applyQuietHours(scheduled: rawNext, quietHours: quietHours);
    }

    return dates;
  }

  // ── billReminderTime ─────────────────────────────────────────────────────

  /// Returns the exact UTC [DateTime] at which to send a bill reminder.
  ///
  /// [reminderHour] defaults to 09:00 UTC which is morning in all Brazilian
  /// time zones (UTC-3 to UTC-5).
  static DateTime billReminderTime({
    required DateTime dueDate,
    required int daysBefore,
    int reminderHour = 9,
  }) {
    final baseDate = dueDate.toUtc().subtract(Duration(days: daysBefore));
    return DateTime.utc(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      reminderHour,
      0,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Adds one calendar month, clamping the day to the last day of the target
  /// month to avoid overflow (e.g., Jan 31 → Feb 28).
  static DateTime _addMonth(DateTime from) {
    final month = from.month == 12 ? 1 : from.month + 1;
    final year = from.month == 12 ? from.year + 1 : from.year;
    final day = from.day.clamp(1, _daysInMonth(year, month));
    return DateTime.utc(year, month, day, from.hour, from.minute, from.second);
  }

  /// Returns the next occurrence of [targetDay] in the month, starting from
  /// the day after [from]. If the day has already passed this month, advances
  /// to the next month.
  static DateTime _nextCustomDay({
    required DateTime from,
    required int targetDay,
  }) {
    final clampedDay = targetDay.clamp(1, _daysInMonth(from.year, from.month));

    if (from.day < clampedDay) {
      // Target day is still ahead in the current month.
      return DateTime.utc(
          from.year, from.month, clampedDay, from.hour, from.minute);
    } else {
      // Target day has passed → go to next month.
      final nextMonth = from.month == 12 ? 1 : from.month + 1;
      final nextYear = from.month == 12 ? from.year + 1 : from.year;
      final clampedNextDay =
          targetDay.clamp(1, _daysInMonth(nextYear, nextMonth));
      return DateTime.utc(
          nextYear, nextMonth, clampedNextDay, from.hour, from.minute);
    }
  }

  /// Returns the number of days in a given [month] of [year].
  static int _daysInMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }
}
