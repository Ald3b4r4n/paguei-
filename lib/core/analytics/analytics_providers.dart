import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/core/analytics/analytics_consent.dart';
import 'package:paguei/core/analytics/analytics_consent_repository.dart';
import 'package:paguei/core/analytics/analytics_event.dart';
import 'package:paguei/core/analytics/analytics_service.dart';
import 'package:paguei/core/di/providers.dart';
import 'package:paguei/presentation/notifications/providers/notifications_provider.dart';

// ---------------------------------------------------------------------------
// Consent repository
// ---------------------------------------------------------------------------

final analyticsConsentRepositoryProvider =
    Provider<AnalyticsConsentRepository>((ref) {
  return AnalyticsConsentRepository(ref.watch(secureStorageProvider));
});

// ---------------------------------------------------------------------------
// Consent notifier
// ---------------------------------------------------------------------------

final analyticsConsentProvider =
    AsyncNotifierProvider<AnalyticsConsentNotifier, AnalyticsConsent>(
  AnalyticsConsentNotifier.new,
);

final class AnalyticsConsentNotifier extends AsyncNotifier<AnalyticsConsent> {
  AnalyticsConsentRepository get _repo =>
      ref.watch(analyticsConsentRepositoryProvider);

  @override
  Future<AnalyticsConsent> build() => _repo.load();

  /// Called when the user explicitly grants consent.
  Future<void> grant() async {
    final consent = AnalyticsConsent(
      hasBeenAsked: true,
      isGranted: true,
      grantedAt: DateTime.now().toUtc(),
    );
    await _repo.save(consent);
    state = AsyncValue.data(consent);
  }

  /// Called when the user explicitly denies or revokes consent.
  Future<void> deny() async {
    final consent = AnalyticsConsent(
      hasBeenAsked: true,
      isGranted: false,
      grantedAt: DateTime.now().toUtc(),
    );
    await _repo.save(consent);
    state = AsyncValue.data(consent);
  }

  /// Resets consent (e.g. "delete my data" flow).
  Future<void> reset() async {
    await _repo.reset();
    state = const AsyncValue.data(AnalyticsConsent.initial());
  }
}

// ---------------------------------------------------------------------------
// Analytics service
// ---------------------------------------------------------------------------

/// The app-wide analytics service.
///
/// Uses [ConsentAwareAnalyticsService] so the user's consent choice takes
/// effect immediately without restarting the app.
///
/// Backend selection:
/// - development → [InMemoryAnalyticsService] (events logged to console)
/// - staging / production → [InMemoryAnalyticsService] with offline queue
///   (replace delegate with `FirebaseAnalyticsService` when package added)
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  final consentAsync = ref.watch(analyticsConsentProvider);

  // Consent defaults to denied when not yet loaded.
  final _ = consentAsync.asData?.value ?? const AnalyticsConsent.initial();

  // In development, always use in-memory (helpful for debugging).
  if (!env.enableAnalytics) {
    return const NoopAnalyticsService();
  }

  // Swap this delegate for FirebaseAnalyticsService once the package is added.
  final delegate = InMemoryAnalyticsService();

  return ConsentAwareAnalyticsService(
    delegate: delegate,
    isEnabled: () {
      // Re-read live consent at each track() call.
      final live = ref.read(analyticsConsentProvider).asData?.value;
      return live?.isGranted ?? false;
    },
  );
});

// ---------------------------------------------------------------------------
// Convenience tracker helper
// ---------------------------------------------------------------------------

/// Extension on [Ref] for one-liner event tracking.
extension AnalyticsRefX on Ref {
  /// Tracks [event] via the current [analyticsServiceProvider].
  void trackEvent(AnalyticsEvent event) {
    read(analyticsServiceProvider).track(event).ignore();
  }
}

/// Extension on [WidgetRef] for one-liner event tracking in widgets.
extension AnalyticsWidgetRefX on WidgetRef {
  /// Tracks [event] via the current [analyticsServiceProvider].
  void trackEvent(AnalyticsEvent event) {
    read(analyticsServiceProvider).track(event).ignore();
  }
}

/// Standalone tracker usable outside Riverpod widgets.
final class AppAnalytics {
  AppAnalytics._();

  static AnalyticsService? _service;

  /// Call once in `_bootstrap()` to bind the service.
  static set instance(AnalyticsService service) => _service = service;

  /// Tracks [event] if the service has been initialised.
  static void track(AnalyticsEvent event) {
    _service?.track(event).ignore();
  }
}
