import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/core/analytics/analytics_event.dart';
import 'package:paguei/core/analytics/analytics_service.dart';

void main() {
  // ── NoopAnalyticsService ─────────────────────────────────────────────────

  group('NoopAnalyticsService', () {
    test('track() is a no-op — does not throw', () async {
      const service = NoopAnalyticsService();
      await expectLater(
        service.track(const BackupCreatedEvent(isEncrypted: true)),
        completes,
      );
    });

    test('flush() is a no-op — does not throw', () async {
      const service = NoopAnalyticsService();
      await expectLater(service.flush(), completes);
    });
  });

  // ── InMemoryAnalyticsService ─────────────────────────────────────────────

  group('InMemoryAnalyticsService', () {
    late InMemoryAnalyticsService service;

    setUp(() => service = InMemoryAnalyticsService());

    test('starts empty', () {
      expect(service.events, isEmpty);
    });

    test('track() stores event', () async {
      await service.track(const AccountCreatedEvent(
        accountType: 'checking',
        isFirst: true,
      ));
      expect(service.events, hasLength(1));
      expect(service.events.first, isA<AccountCreatedEvent>());
    });

    test('tracks multiple events in order', () async {
      await service.track(const BillPaidEvent(daysBeforeDue: 3));
      await service.track(const DebtPaidEvent(isFullyPaid: false));
      await service.track(const ExportCsvEvent(exportType: 'transactions'));

      expect(service.events, hasLength(3));
      expect(service.events[0], isA<BillPaidEvent>());
      expect(service.events[1], isA<DebtPaidEvent>());
      expect(service.events[2], isA<ExportCsvEvent>());
    });

    test('clear() removes all events', () async {
      await service.track(const BackupCreatedEvent(isEncrypted: false));
      service.clear();
      expect(service.events, isEmpty);
    });

    test('evicts oldest event when maxEvents is reached', () async {
      final small = InMemoryAnalyticsService(maxEvents: 3);
      await small.track(const BackupCreatedEvent(isEncrypted: false));
      await small.track(const BackupCreatedEvent(isEncrypted: true));
      await small.track(const DebtPaidEvent(isFullyPaid: false));
      await small.track(const BillPaidEvent(daysBeforeDue: 0));

      expect(small.events, hasLength(3));
      // First event (isEncrypted: false) was evicted
      expect(small.events.whereType<BackupCreatedEvent>().first.isEncrypted,
          isTrue);
    });

    test('events list is unmodifiable', () async {
      await service.track(const OnboardingCompletedEvent());
      expect(
        () => service.events.add(const OnboardingCompletedEvent()),
        throwsUnsupportedError,
      );
    });
  });

  // ── ConsentAwareAnalyticsService ─────────────────────────────────────────

  group('ConsentAwareAnalyticsService — analytics disabled sends nothing', () {
    test('does not forward when isEnabled returns false', () async {
      final delegate = InMemoryAnalyticsService();
      final wrapper = ConsentAwareAnalyticsService(
        delegate: delegate,
        isEnabled: () => false,
      );

      await wrapper.track(const BackupCreatedEvent(isEncrypted: false));
      await wrapper.track(const BillPaidEvent(daysBeforeDue: 2));

      expect(delegate.events, isEmpty);
    });

    test('forwards when isEnabled returns true', () async {
      final delegate = InMemoryAnalyticsService();
      final wrapper = ConsentAwareAnalyticsService(
        delegate: delegate,
        isEnabled: () => true,
      );

      await wrapper.track(const BackupCreatedEvent(isEncrypted: true));
      expect(delegate.events, hasLength(1));
    });

    test('respects consent toggle mid-session', () async {
      final delegate = InMemoryAnalyticsService();
      bool consentGranted = true;

      final wrapper = ConsentAwareAnalyticsService(
        delegate: delegate,
        isEnabled: () => consentGranted,
      );

      await wrapper.track(const OnboardingCompletedEvent());
      expect(delegate.events, hasLength(1));

      // User revokes consent
      consentGranted = false;
      await wrapper.track(const BackupCreatedEvent(isEncrypted: false));
      expect(delegate.events, hasLength(1)); // still 1, not 2
    });

    test('flush() skipped when disabled', () async {
      final delegate = InMemoryAnalyticsService();
      final wrapper = ConsentAwareAnalyticsService(
        delegate: delegate,
        isEnabled: () => false,
      );
      await expectLater(wrapper.flush(), completes);
    });
  });

  // ── AnalyticsEvent parameters ────────────────────────────────────────────

  group('AnalyticsEvent parameters — no PII', () {
    test('BillPaidEvent clamps days to [-30, 30]', () {
      const event = BillPaidEvent(daysBeforeDue: 99);
      expect(event.parameters['days_before_due'], 30);

      const early = BillPaidEvent(daysBeforeDue: -99);
      expect(early.parameters['days_before_due'], -30);
    });

    test('AccountCreatedEvent includes accountType and isFirst', () {
      const e = AccountCreatedEvent(accountType: 'savings', isFirst: false);
      expect(e.parameters['account_type'], 'savings');
      expect(e.parameters['is_first_account'], false);
      expect(e.name, 'account_created');
    });

    test('RetentionDayEvent name encodes day number', () {
      expect(const RetentionDayEvent(day: 1).name, 'retention_day_1');
      expect(const RetentionDayEvent(day: 7).name, 'retention_day_7');
      expect(const RetentionDayEvent(day: 30).name, 'retention_day_30');
    });

    test('ExportCsvEvent carries exportType', () {
      const e = ExportCsvEvent(exportType: 'bills');
      expect(e.name, 'export_csv');
      expect(e.parameters['export_type'], 'bills');
    });

    test('FeedbackSubmittedEvent carries feedbackType', () {
      const e = FeedbackSubmittedEvent(feedbackType: 'bug_report');
      expect(e.name, 'feedback_submitted');
      expect(e.parameters['feedback_type'], 'bug_report');
    });
  });
}
