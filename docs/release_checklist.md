# Paguei? — Release Checklist

> Last updated: 2026-04-20  
> Use this list before every production release (GitHub tag + Play Store submission).

---

## 🔐 Security

- [ ] All debug logs removed from release build (`kReleaseMode` guards in place)
- [ ] `flutter_secure_storage` used for all sensitive data (passwords, tokens, consent)
- [ ] No raw financial amounts or PII in analytics events
- [ ] `AppEnvironment.production` sets `enableAnalytics: true`, `logLevel: 'warning'`
- [ ] Crash reporter fires on both `FlutterError.onError` and `PlatformDispatcher.onError`
- [ ] `CrashReporter.setUserIdentifier` uses anonymous device ID only — no user email/CPF
- [ ] ProGuard / R8 rules verified for `drift`, `flutter_secure_storage`, `go_router`
- [ ] Network security config present (`res/xml/network_security_config.xml`) — cleartext disabled
- [ ] `backup_rules.xml` excludes database file from auto-backup (prevents data leaks)

## 📊 Analytics & Privacy

- [ ] `AnalyticsConsentDialog` shown on first launch before any event is tracked
- [ ] Consent stored in secure storage, survives app update
- [ ] "Delete my data" flow calls `AnalyticsConsentRepository.reset()`
- [ ] LGPD privacy policy URL in Play Store listing
- [ ] Privacy policy URL in app (Settings → Privacidade)
- [ ] Data Safety form completed in Play Console (no sensitive data collected)
- [ ] `firebase_analytics` or alternative SDK wired when package added

## 🔔 Notifications

- [ ] `SCHEDULE_EXACT_ALARM` permission handled gracefully on Android 12+
- [ ] `POST_NOTIFICATIONS` runtime request with rationale on Android 13+
- [ ] Notification channels created on first launch
- [ ] Quiet hours respected in all scheduled notifications
- [ ] Notification icons use monochrome `@drawable/ic_notification` (Android requirement)

## 💾 Data

- [ ] Database migration tested: v1 → v2 roundtrip with seed data
- [ ] Backup restore tested on fresh install
- [ ] Backup file extension `.paguei.backup` registered in `AndroidManifest.xml`
- [ ] Large database (>10 000 rows) export tested for performance
- [ ] Temp CSV files deleted after share sheet dismissal

## 🧪 Testing

- [ ] `flutter test` passes with 0 failures
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] Integration test: account create → bill pay → backup → restore roundtrip
- [ ] Dark mode visual review
- [ ] Font scale 200% review (accessibility)
- [ ] Tested on Android 8, 10, 13, 14 (API 26, 29, 33, 34)

## 🏪 Play Store

- [ ] `versionCode` incremented in `pubspec.yaml`
- [ ] `versionName` matches the tag (e.g. `1.0.0`)
- [ ] Release notes written in pt-BR (max 500 chars)
- [ ] Screenshots updated (phone + 7-inch tablet)
- [ ] Feature graphic updated if UI changed
- [ ] Content rating questionnaire reviewed
- [ ] Target API level ≥ 34 (required for 2025 submissions)
- [ ] `minSdkVersion` = 21 (Android 5.0)
- [ ] App signing key backed up in 2+ secure locations
- [ ] `--split-debug-info` flag used in release build to reduce binary size

## 🚀 Build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release --split-per-abi \
  --split-debug-info=build/symbols \
  --obfuscate
flutter build appbundle --release \
  --split-debug-info=build/symbols \
  --obfuscate
```

- [ ] APK size ≤ 30 MB (target; AAB size varies)
- [ ] `symbols/` directory uploaded to Play Console (crash deobfuscation)
- [ ] SHA-256 fingerprint of release key recorded in `docs/signing.md` (gitignored)

---

## Post-Release

- [ ] Monitor Crashlytics for new crash clusters (first 48 hours)
- [ ] Check Play Store rating (target: ≥ 4.0 after 50 reviews)
- [ ] Verify Day-1 retention event fires in analytics
- [ ] Check FCM notification delivery rate ≥ 95%
