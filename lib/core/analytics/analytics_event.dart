/// Sealed class hierarchy of all privacy-safe analytics events.
///
/// ## Privacy rules (LGPD / GDPR compliance)
///
/// - No PII: names, CPFs, e-mails, phone numbers are **never** included.
/// - No financial amounts or account balances.
/// - No free-text fields that could contain user data.
/// - Only structural/categorical metadata (counts, boolean flags, enum values).
///
/// ## Adding a new event
///
/// 1. Add a new `final class` inside this file that extends [AnalyticsEvent].
/// 2. Override [name] with a snake_case string.
/// 3. Override [parameters] with only the allowed non-PII fields.
/// 4. Call `analyticsService.track(YourNewEvent(...))` at the call site.
sealed class AnalyticsEvent {
  const AnalyticsEvent();

  /// Snake_case event name sent to the analytics backend.
  String get name;

  /// Non-PII parameters attached to the event.
  Map<String, Object?> get parameters => const {};
}

// ---------------------------------------------------------------------------
// Account events
// ---------------------------------------------------------------------------

/// Fired when the user creates their first account (or any subsequent one).
final class AccountCreatedEvent extends AnalyticsEvent {
  const AccountCreatedEvent({required this.accountType, required this.isFirst});

  /// The account type enum name (e.g. `'checking'`, `'savings'`).
  final String accountType;

  /// Whether this is the user's very first account.
  final bool isFirst;

  @override
  String get name => 'account_created';

  @override
  Map<String, Object?> get parameters => {
        'account_type': accountType,
        'is_first_account': isFirst,
      };
}

// ---------------------------------------------------------------------------
// Bill events
// ---------------------------------------------------------------------------

/// Fired when a bill is marked as paid.
final class BillPaidEvent extends AnalyticsEvent {
  const BillPaidEvent({required this.daysBeforeDue});

  /// Negative = paid after due date. Coerced to [-30, 30] for anonymisation.
  final int daysBeforeDue;

  @override
  String get name => 'bill_paid';

  @override
  Map<String, Object?> get parameters => {
        'days_before_due': daysBeforeDue.clamp(-30, 30),
      };
}

// ---------------------------------------------------------------------------
// Backup events
// ---------------------------------------------------------------------------

/// Fired when the user creates a backup.
final class BackupCreatedEvent extends AnalyticsEvent {
  const BackupCreatedEvent({required this.isEncrypted});

  final bool isEncrypted;

  @override
  String get name => 'backup_created';

  @override
  Map<String, Object?> get parameters => {'is_encrypted': isEncrypted};
}

/// Fired when the user restores from a backup.
final class BackupRestoredEvent extends AnalyticsEvent {
  const BackupRestoredEvent({required this.mode, required this.success});

  /// `'merge'` or `'replace'`
  final String mode;
  final bool success;

  @override
  String get name => 'backup_restored';

  @override
  Map<String, Object?> get parameters => {
        'restore_mode': mode,
        'success': success,
      };
}

// ---------------------------------------------------------------------------
// Export events
// ---------------------------------------------------------------------------

/// Fired when the user exports data to CSV.
final class ExportCsvEvent extends AnalyticsEvent {
  const ExportCsvEvent({required this.exportType});

  /// `'transactions'`, `'bills'`, `'debts'`, `'monthly_report'`
  final String exportType;

  @override
  String get name => 'export_csv';

  @override
  Map<String, Object?> get parameters => {'export_type': exportType};
}

// ---------------------------------------------------------------------------
// Debt events
// ---------------------------------------------------------------------------

/// Fired when a debt payment is registered.
final class DebtPaidEvent extends AnalyticsEvent {
  const DebtPaidEvent({required this.isFullyPaid});

  final bool isFullyPaid;

  @override
  String get name => 'debt_paid';

  @override
  Map<String, Object?> get parameters => {'fully_paid': isFullyPaid};
}

// ---------------------------------------------------------------------------
// Fund events
// ---------------------------------------------------------------------------

/// Fired when a fund reaches its target amount.
final class FundGoalCompletedEvent extends AnalyticsEvent {
  const FundGoalCompletedEvent({required this.fundType});

  /// `'emergency'`, `'goal'`, `'savings'`
  final String fundType;

  @override
  String get name => 'fund_goal_completed';

  @override
  Map<String, Object?> get parameters => {'fund_type': fundType};
}

// ---------------------------------------------------------------------------
// Notification events
// ---------------------------------------------------------------------------

/// Fired when the user taps a local notification and the app opens.
final class NotificationOpenedEvent extends AnalyticsEvent {
  const NotificationOpenedEvent({required this.notificationType});

  /// Matches [NotificationType.name].
  final String notificationType;

  @override
  String get name => 'notification_opened';

  @override
  Map<String, Object?> get parameters => {
        'notification_type': notificationType,
      };
}

// ---------------------------------------------------------------------------
// Retention events
// ---------------------------------------------------------------------------

/// Fired on Day 1 / Day 7 / Day 30 after first launch to measure retention.
final class RetentionDayEvent extends AnalyticsEvent {
  const RetentionDayEvent({required this.day});

  /// Must be 1, 7, or 30.
  final int day;

  @override
  String get name => 'retention_day_$day';
}

// ---------------------------------------------------------------------------
// Onboarding / screen events
// ---------------------------------------------------------------------------

/// Fired when the user completes the onboarding flow.
final class OnboardingCompletedEvent extends AnalyticsEvent {
  const OnboardingCompletedEvent();

  @override
  String get name => 'onboarding_completed';
}

/// Fired when a screen is viewed (only for core financial flows).
final class ScreenViewedEvent extends AnalyticsEvent {
  const ScreenViewedEvent({required this.screenName});

  /// Predefined screen name — never derived from dynamic data.
  final String screenName;

  @override
  String get name => 'screen_viewed';

  @override
  Map<String, Object?> get parameters => {'screen_name': screenName};
}

// ---------------------------------------------------------------------------
// Feedback events
// ---------------------------------------------------------------------------

/// Fired when a user submits feedback (type only — no content).
final class FeedbackSubmittedEvent extends AnalyticsEvent {
  const FeedbackSubmittedEvent({required this.feedbackType});

  /// `'bug_report'`, `'feature_request'`, `'rating'`
  final String feedbackType;

  @override
  String get name => 'feedback_submitted';

  @override
  Map<String, Object?> get parameters => {'feedback_type': feedbackType};
}
