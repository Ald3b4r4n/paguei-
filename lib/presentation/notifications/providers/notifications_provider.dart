import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:paguei/application/notifications/schedule_bill_reminders_use_case.dart';
import 'package:paguei/application/notifications/schedule_debt_reminder_use_case.dart';
import 'package:paguei/application/notifications/schedule_fund_nudge_use_case.dart';
import 'package:paguei/data/datasources/notifications/notification_datasource.dart';
import 'package:paguei/data/repositories/notification_preferences_repository.dart';
import 'package:paguei/domain/entities/notification_preferences.dart';
import 'package:paguei/presentation/bills/providers/bills_provider.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final notificationDatasourceProvider = Provider<NotificationDatasource>((_) {
  return FlutterLocalNotificationsDatasource();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
  );
});

final notificationPrefsRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepository(ref.watch(secureStorageProvider));
});

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final scheduleBillRemindersProvider =
    Provider<ScheduleBillRemindersUseCase>((ref) {
  return ScheduleBillRemindersUseCase(
    ref.watch(notificationDatasourceProvider),
  );
});

final scheduleDebtReminderProvider =
    Provider<ScheduleDebtReminderUseCase>((ref) {
  return ScheduleDebtReminderUseCase(
    ref.watch(notificationDatasourceProvider),
  );
});

final scheduleFundNudgeProvider = Provider<ScheduleFundNudgeUseCase>((ref) {
  return ScheduleFundNudgeUseCase(
    ref.watch(notificationDatasourceProvider),
  );
});

// ---------------------------------------------------------------------------
// NotificationPreferences notifier
// ---------------------------------------------------------------------------

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final repo = ref.watch(notificationPrefsRepositoryProvider);
    return repo.load();
  }

  /// Updates preferences by applying [updater] to the current state and
  /// persisting the result.
  Future<void> updatePreferences(
    NotificationPreferences Function(NotificationPreferences current) updater,
  ) async {
    final current = state.asData?.value ?? const NotificationPreferences();
    final updated = updater(current);
    state = AsyncData(updated);
    await ref.read(notificationPrefsRepositoryProvider).save(updated);

    // Re-schedule all pending notifications with the updated quiet-hours /
    // enabled settings whenever preferences change.
    await _rescheduleAll(updated);
  }

  Future<void> _rescheduleAll(NotificationPreferences prefs) async {
    final billsAsync = ref.read(allBillsProvider);
    final bills = billsAsync.asData?.value ?? [];
    if (prefs.billRemindersEnabled && bills.isNotEmpty) {
      await ref.read(scheduleBillRemindersProvider).executeBatch(
            bills: bills,
            quietHours: prefs.quietHours,
          );
    } else if (!prefs.billRemindersEnabled) {
      // Cancel all bill reminders when feature is disabled.
      for (final bill in bills) {
        await ref
            .read(notificationDatasourceProvider)
            .cancel(notificationIdFor('${bill.id}_advance'));
        await ref
            .read(notificationDatasourceProvider)
            .cancel(notificationIdFor('${bill.id}_today'));
      }
    }
  }
}

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);
