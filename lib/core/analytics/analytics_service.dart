import 'package:flutter/foundation.dart';
import 'analytics_event.dart';

/// Abstraction over any analytics backend.
///
/// ## Implementations
///
/// | Class | When used |
/// |---|---|
/// | [NoopAnalyticsService] | consent denied / analytics disabled |
/// | [InMemoryAnalyticsService] | development, unit tests |
/// | `FirebaseAnalyticsService` | production (add when firebase_analytics added) |
///
/// ## Adding Firebase Analytics
///
/// 1. Add to pubspec.yaml:
///    ```yaml
///    firebase_analytics: ^11.0.0
///    ```
///
/// 2. Create `lib/core/analytics/firebase_analytics_service.dart`:
///    ```dart
///    import 'package:firebase_analytics/firebase_analytics.dart';
///    import 'analytics_service.dart';
///    import 'analytics_event.dart';
///
///    final class FirebaseAnalyticsService implements AnalyticsService {
///      const FirebaseAnalyticsService(this._fa);
///      final FirebaseAnalytics _fa;
///
///      @override
///      Future<void> track(AnalyticsEvent event) =>
///          _fa.logEvent(name: event.name, parameters:
///              event.parameters.map((k, v) => MapEntry(k, v?.toString() ?? '')));
///
///      @override
///      Future<void> flush() async {}  // Firebase auto-batches
///    }
///    ```
///
/// ## Adding Mixpanel / Amplitude / PostHog
///
/// Follow the same pattern — implement [track] to call the SDK's `track()`
/// method. All event shaping is already done in [AnalyticsEvent.parameters].
abstract interface class AnalyticsService {
  /// Tracks [event] if analytics is enabled and the user has given consent.
  Future<void> track(AnalyticsEvent event);

  /// Flushes any queued events to the remote backend.
  ///
  /// Call before the app goes to background if using a batching strategy.
  Future<void> flush();
}

// ---------------------------------------------------------------------------
// NoopAnalyticsService
// ---------------------------------------------------------------------------

/// Does nothing. Used when the user opts out or analytics is disabled.
final class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> track(AnalyticsEvent event) async {}

  @override
  Future<void> flush() async {}
}

// ---------------------------------------------------------------------------
// InMemoryAnalyticsService
// ---------------------------------------------------------------------------

/// Stores events in an in-memory list.
///
/// Suitable for:
/// - Unit and widget tests (inspect [events] for assertions).
/// - Development builds (events show in [DebugAnalyticsObserver]).
final class InMemoryAnalyticsService implements AnalyticsService {
  InMemoryAnalyticsService({this.maxEvents = 200});

  final int maxEvents;

  final List<AnalyticsEvent> _events = [];

  /// All tracked events in chronological order.
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// Clears all stored events (useful between test cases).
  void clear() => _events.clear();

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (_events.length >= maxEvents) _events.removeAt(0);
    _events.add(event);
    debugPrint('[Analytics] ${event.name} ${event.parameters}');
  }

  @override
  Future<void> flush() async {}
}

// ---------------------------------------------------------------------------
// ConsentAwareAnalyticsService
// ---------------------------------------------------------------------------

/// Wraps another [AnalyticsService] and forwards events only when [isEnabled]
/// returns true at call time.
///
/// Used as the production-facing service so consent changes take effect
/// immediately without restarting the app.
final class ConsentAwareAnalyticsService implements AnalyticsService {
  const ConsentAwareAnalyticsService({
    required AnalyticsService delegate,
    required bool Function() isEnabled,
  })  : _delegate = delegate,
        _isEnabled = isEnabled;

  final AnalyticsService _delegate;
  final bool Function() _isEnabled;

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!_isEnabled()) return;
    return _delegate.track(event);
  }

  @override
  Future<void> flush() async {
    if (!_isEnabled()) return;
    return _delegate.flush();
  }
}
