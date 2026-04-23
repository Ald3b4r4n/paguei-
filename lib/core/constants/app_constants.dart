abstract final class AppConstants {
  static const String appName = 'Paguei?';
  static const String defaultLocale = 'pt_BR';
  static const String defaultCurrency = 'BRL';
  static const int maxNotificationsScheduled = 64;
  static const int defaultReminderDaysBefore = 3;
  static const double defaultBudgetAlertThreshold = 0.8;
  static const int databaseSchemaVersion = 1;
  static const String databaseName = 'paguei.db';

  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const double scanConfidenceThreshold = 0.85;

  static const int csvExportIsolateThreshold = 500;
}
