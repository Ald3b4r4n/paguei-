import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// ---------------------------------------------------------------------------
// Notification type enum
// ---------------------------------------------------------------------------

/// All notification categories recognised by the app.
///
/// Each type maps to a dedicated Android notification channel and an iOS
/// category, giving the user fine-grained control in system settings.
enum NotificationType {
  billDueTomorrow,
  billDueToday,
  billOverdue,
  debtInstallmentReminder,
  fundContributionNudge,
  salaryExpected,
  smartNudge,
  grouped,
}

// ---------------------------------------------------------------------------
// Notification payload
// ---------------------------------------------------------------------------

/// A single notification to be shown or scheduled.
final class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.scheduledAt,
    this.referenceId,
    this.groupKey,
    this.channelId,
    this.payload,
  });

  /// Unique integer ID within the app (0–2^31). Callers derive this from
  /// a hash of [referenceId] to enable stable updates/cancellation.
  final int id;
  final String title;
  final String body;
  final NotificationType type;

  /// When null the notification is shown immediately.
  final DateTime? scheduledAt;

  /// The entity ID this notification is about (bill id, debt id, etc.).
  final String? referenceId;

  /// Android notification group key for inbox-style grouping.
  final String? groupKey;

  /// Override the default channel. Defaults to [type.channelId].
  final String? channelId;

  /// Opaque string passed back when the notification is tapped.
  final String? payload;
}

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

abstract interface class NotificationDatasource {
  /// Initialise the plugin. Call once from `main()` before any scheduling.
  Future<void> initialise();

  /// Request OS-level notification permission (Android 13+, iOS).
  /// Returns `true` if permission is granted.
  Future<bool> requestPermission();

  /// Show or schedule [notification].
  /// If [notification.scheduledAt] is null it is shown immediately.
  Future<void> schedule(NotificationPayload notification);

  /// Cancel a previously scheduled notification by [id].
  Future<void> cancel(int id);

  /// Cancel all scheduled notifications.
  Future<void> cancelAll();

  /// Return all pending (not-yet-shown) notification IDs.
  Future<List<int>> pendingIds();
}

// ---------------------------------------------------------------------------
// Channel constants
// ---------------------------------------------------------------------------

abstract final class NotificationChannels {
  static const billsDueId = 'bills_due';
  static const billsDueName = 'Boletos a vencer';

  static const billsOverdueId = 'bills_overdue';
  static const billsOverdueName = 'Boletos vencidos';

  static const debtId = 'debts';
  static const debtName = 'Parcelas de dívidas';

  static const fundsId = 'funds';
  static const fundsName = 'Metas de reservas';

  static const salaryId = 'salary';
  static const salaryName = 'Salário esperado';

  static const nudgesId = 'nudges';
  static const nudgesName = 'Lembretes inteligentes';

  /// Returns the channel id for a given [NotificationType].
  static String forType(NotificationType type) => switch (type) {
        NotificationType.billDueTomorrow ||
        NotificationType.billDueToday =>
          billsDueId,
        NotificationType.billOverdue => billsOverdueId,
        NotificationType.debtInstallmentReminder => debtId,
        NotificationType.fundContributionNudge => fundsId,
        NotificationType.salaryExpected => salaryId,
        NotificationType.smartNudge || NotificationType.grouped => nudgesId,
      };
}

// ---------------------------------------------------------------------------
// Production implementation
// ---------------------------------------------------------------------------

/// Production implementation using [FlutterLocalNotificationsPlugin].
///
/// All scheduled times are expressed in [tz.TZDateTime] to ensure timezone
/// safety across DST transitions and app-timezone changes.
final class FlutterLocalNotificationsDatasource
    implements NotificationDatasource {
  FlutterLocalNotificationsDatasource()
      : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  Future<void> initialise() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we ask explicitly via requestPermission
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Create Android channels (no-op on iOS).
    if (Platform.isAndroid) {
      await _createChannels();
    }
  }

  Future<void> _createChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final channels = [
      const AndroidNotificationChannel(
        NotificationChannels.billsDueId,
        NotificationChannels.billsDueName,
        description: 'Lembretes de boletos próximos ao vencimento.',
        importance: Importance.high,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        NotificationChannels.billsOverdueId,
        NotificationChannels.billsOverdueName,
        description: 'Alertas de boletos vencidos.',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
      const AndroidNotificationChannel(
        NotificationChannels.debtId,
        NotificationChannels.debtName,
        description: 'Lembretes de parcelas de dívidas.',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        NotificationChannels.fundsId,
        NotificationChannels.fundsName,
        description: 'Lembretes de contribuições em metas.',
        importance: Importance.low,
      ),
      const AndroidNotificationChannel(
        NotificationChannels.salaryId,
        NotificationChannels.salaryName,
        description: 'Alertas de dia de salário esperado.',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        NotificationChannels.nudgesId,
        NotificationChannels.nudgesName,
        description: 'Dicas financeiras inteligentes.',
        importance: Importance.low,
      ),
    ];

    for (final ch in channels) {
      await androidPlugin.createNotificationChannel(ch);
    }
  }

  // ── Permission ────────────────────────────────────────────────────────────

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted;
    }
    if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    return true; // Desktop / other platforms — permission not required.
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  @override
  Future<void> schedule(NotificationPayload notification) async {
    final channelId = notification.channelId ??
        NotificationChannels.forType(notification.type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      NotificationChannels.billsDueName,
      groupKey: notification.groupKey,
      importance: _importanceFor(notification.type),
      priority: _priorityFor(notification.type),
      styleInformation: const DefaultStyleInformation(true, true),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (notification.scheduledAt == null) {
      // Immediate
      await _plugin.show(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        notificationDetails: details,
        payload: notification.payload,
      );
    } else {
      final scheduledTz = tz.TZDateTime.from(
        notification.scheduledAt!.toUtc(),
        tz.UTC,
      );

      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: scheduledTz,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: notification.payload,
      );
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.map((r) => r.id).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Importance _importanceFor(NotificationType type) => switch (type) {
        NotificationType.billOverdue => Importance.max,
        NotificationType.billDueToday => Importance.high,
        NotificationType.billDueTomorrow ||
        NotificationType.debtInstallmentReminder ||
        NotificationType.salaryExpected =>
          Importance.defaultImportance,
        _ => Importance.low,
      };

  Priority _priorityFor(NotificationType type) => switch (type) {
        NotificationType.billOverdue => Priority.max,
        NotificationType.billDueToday => Priority.high,
        _ => Priority.defaultPriority,
      };
}

// ---------------------------------------------------------------------------
// Notification ID helpers
// ---------------------------------------------------------------------------

/// Derive a stable 31-bit notification ID from a string [key].
///
/// The same [key] always maps to the same ID, enabling idempotent
/// re-scheduling (updating a scheduled notification without duplicates).
int notificationIdFor(String key) => key.hashCode.abs() % 0x7FFFFFFF;
