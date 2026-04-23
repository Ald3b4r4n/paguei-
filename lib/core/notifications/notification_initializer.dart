import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/core/logging/app_logger.dart';
import 'package:paguei/domain/entities/notification_preferences.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';
import 'package:paguei/presentation/notifications/providers/notifications_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Bootstraps the notification subsystem.
///
/// Call [NotificationInitializer.run] once from `main()` after
/// [WidgetsFlutterBinding.ensureInitialized].
///
/// Responsibilities:
/// 1. Initialise the timezone database (required by `timezone` package).
/// 2. Initialise flutter_local_notifications (create Android channels, etc.).
/// 3. Request OS permission if not yet granted.
/// 4. Re-schedule all pending notifications based on persisted preferences.
abstract final class NotificationInitializer {
  static Future<void> run(ProviderContainer container) async {
    final AppLogger logger = container.read(appLoggerProvider);

    try {
      // ── 1. Timezone database ─────────────────────────────────────────────
      tz.initializeTimeZones();
      // Default to Brasília time (UTC-3) — matches the majority of users.
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

      // ── 2. Plugin initialisation ─────────────────────────────────────────
      final datasource = container.read(notificationDatasourceProvider);
      await datasource.initialise();

      // ── 3. Permission ────────────────────────────────────────────────────
      final granted = await datasource.requestPermission();
      if (!granted) {
        logger.warning('[NotificationInitializer] Permission denied by user.');
        return; // Don't schedule if the user denied.
      }

      // ── 4. Re-schedule from persisted prefs ──────────────────────────────
      final prefs =
          await container.read(notificationPreferencesProvider.future);

      await _scheduleAll(container, prefs, logger);
    } catch (e, st) {
      logger.error('[NotificationInitializer] Init failed.',
          error: e, stackTrace: st);
    }
  }

  static Future<void> _scheduleAll(
    ProviderContainer container,
    NotificationPreferences prefs,
    AppLogger logger,
  ) async {
    final quietHours = prefs.quietHours;

    // ── Bills ────────────────────────────────────────────────────────────────
    if (prefs.billRemindersEnabled) {
      try {
        final bills = await container.read(allBillsProvider.future);
        await container.read(scheduleBillRemindersProvider).executeBatch(
              bills: bills,
              quietHours: quietHours,
            );
        logger.info(
            '[NotificationInitializer] Scheduled reminders for ${bills.length} bills.');
      } catch (e) {
        logger.warning('[NotificationInitializer] Bill scheduling failed: $e');
      }
    }

    // Debt and fund scheduling is triggered individually from the respective
    // feature screens (e.g., after creating/updating a debt or fund).
    // This keeps startup fast and avoids loading all entities at boot.
  }
}
