enum AppFlavor { development, staging, production }

final class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.databaseName,
    required this.enableAnalytics,
    required this.enableCrashReporting,
    required this.logLevel,
  });

  final AppFlavor flavor;
  final String databaseName;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final String logLevel;

  static const development = AppEnvironment(
    flavor: AppFlavor.development,
    databaseName: 'paguei_dev.db',
    enableAnalytics: false,
    enableCrashReporting: false,
    logLevel: 'debug',
  );

  static const staging = AppEnvironment(
    flavor: AppFlavor.staging,
    databaseName: 'paguei_staging.db',
    enableAnalytics: false,
    enableCrashReporting: true,
    logLevel: 'info',
  );

  static const production = AppEnvironment(
    flavor: AppFlavor.production,
    databaseName: 'paguei.db',
    enableAnalytics: true,
    enableCrashReporting: true,
    logLevel: 'warning',
  );

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isProduction => flavor == AppFlavor.production;
}
