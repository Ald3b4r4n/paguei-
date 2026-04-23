import 'package:paguei/application/notifications/notification_recurrence_engine.dart';

/// User-configurable notification preferences.
///
/// Stored as a simple value object; persistence is handled by the repository.
/// All fields have safe defaults so the app works correctly without any
/// explicit user configuration.
final class NotificationPreferences {
  const NotificationPreferences({
    this.billRemindersEnabled = true,
    this.debtRemindersEnabled = true,
    this.fundNudgesEnabled = true,
    this.salaryReminderEnabled = false,
    this.smartNudgesEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.salaryDay,
    this.emailOptIn = false,
  });

  // ── Type toggles ──────────────────────────────────────────────────────────
  final bool billRemindersEnabled;
  final bool debtRemindersEnabled;
  final bool fundNudgesEnabled;
  final bool salaryReminderEnabled;
  final bool smartNudgesEnabled;

  // ── Output controls ───────────────────────────────────────────────────────
  final bool soundEnabled;
  final bool vibrationEnabled;

  // ── Quiet hours ───────────────────────────────────────────────────────────
  final bool quietHoursEnabled;

  /// Hour (0–23, UTC) at which quiet window begins.
  final int quietHoursStart;

  /// Hour (0–23, UTC) at which quiet window ends.
  final int quietHoursEnd;

  // ── Salary ────────────────────────────────────────────────────────────────
  /// Day of month (1–31) on which the user expects their salary.
  /// Null = feature disabled.
  final int? salaryDay;

  // ── Future-ready ─────────────────────────────────────────────────────────
  final bool emailOptIn;

  // ── Derived ──────────────────────────────────────────────────────────────

  /// Returns the [QuietHours] constraint, or null when quiet hours are off.
  QuietHours? get quietHours => quietHoursEnabled
      ? QuietHours(startHour: quietHoursStart, endHour: quietHoursEnd)
      : null;

  // ── copyWith ─────────────────────────────────────────────────────────────

  NotificationPreferences copyWith({
    bool? billRemindersEnabled,
    bool? debtRemindersEnabled,
    bool? fundNudgesEnabled,
    bool? salaryReminderEnabled,
    bool? smartNudgesEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    int? salaryDay,
    bool? emailOptIn,
  }) {
    return NotificationPreferences(
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
      debtRemindersEnabled: debtRemindersEnabled ?? this.debtRemindersEnabled,
      fundNudgesEnabled: fundNudgesEnabled ?? this.fundNudgesEnabled,
      salaryReminderEnabled:
          salaryReminderEnabled ?? this.salaryReminderEnabled,
      smartNudgesEnabled: smartNudgesEnabled ?? this.smartNudgesEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      salaryDay: salaryDay ?? this.salaryDay,
      emailOptIn: emailOptIn ?? this.emailOptIn,
    );
  }

  // ── Serialisation (JSON-compatible map for SharedPreferences) ────────────

  Map<String, dynamic> toMap() => {
        'billRemindersEnabled': billRemindersEnabled,
        'debtRemindersEnabled': debtRemindersEnabled,
        'fundNudgesEnabled': fundNudgesEnabled,
        'salaryReminderEnabled': salaryReminderEnabled,
        'smartNudgesEnabled': smartNudgesEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'salaryDay': salaryDay,
        'emailOptIn': emailOptIn,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      billRemindersEnabled: map['billRemindersEnabled'] as bool? ?? true,
      debtRemindersEnabled: map['debtRemindersEnabled'] as bool? ?? true,
      fundNudgesEnabled: map['fundNudgesEnabled'] as bool? ?? true,
      salaryReminderEnabled: map['salaryReminderEnabled'] as bool? ?? false,
      smartNudgesEnabled: map['smartNudgesEnabled'] as bool? ?? true,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      quietHoursEnabled: map['quietHoursEnabled'] as bool? ?? true,
      quietHoursStart: map['quietHoursStart'] as int? ?? 22,
      quietHoursEnd: map['quietHoursEnd'] as int? ?? 8,
      salaryDay: map['salaryDay'] as int?,
      emailOptIn: map['emailOptIn'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          billRemindersEnabled == other.billRemindersEnabled &&
          debtRemindersEnabled == other.debtRemindersEnabled &&
          fundNudgesEnabled == other.fundNudgesEnabled &&
          salaryReminderEnabled == other.salaryReminderEnabled &&
          smartNudgesEnabled == other.smartNudgesEnabled &&
          soundEnabled == other.soundEnabled &&
          vibrationEnabled == other.vibrationEnabled &&
          quietHoursEnabled == other.quietHoursEnabled &&
          quietHoursStart == other.quietHoursStart &&
          quietHoursEnd == other.quietHoursEnd &&
          salaryDay == other.salaryDay &&
          emailOptIn == other.emailOptIn;

  @override
  int get hashCode => Object.hash(
        billRemindersEnabled,
        debtRemindersEnabled,
        fundNudgesEnabled,
        salaryReminderEnabled,
        smartNudgesEnabled,
        soundEnabled,
        vibrationEnabled,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
        salaryDay,
        emailOptIn,
      );
}
