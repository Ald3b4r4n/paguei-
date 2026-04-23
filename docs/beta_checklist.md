# Paguei? — Beta Checklist

> For internal testing (Google Play Internal Testing track) before open beta.

---

## Functionality

- [ ] Happy path: create account → add transaction → pay bill → create backup
- [ ] Restore backup on fresh install works (merge + replace modes)
- [ ] Notifications fire at correct times (advance + overdue + quiet hours)
- [ ] CSV export opens correctly in Google Sheets
- [ ] Dark mode: no invisible text, correct contrast
- [ ] Landscape orientation: no overflow on main screens
- [ ] Deep link `/boletos/:id` navigates correctly from notification

## Beta Diagnostics Screen

- [ ] Accessible via 10 taps on "Versão do App" in Ajustes
- [ ] Shows correct DB schema version
- [ ] Pending notification count matches reality
- [ ] Last backup timestamp accurate
- [ ] Log entries show sanitised messages (no `[REDACTED]` in normal flow)
- [ ] "Copiar diagnóstico" button produces shareable text

## Consent & Privacy

- [ ] Consent dialog appears on first launch only
- [ ] Declining consent → analytics events NOT sent
- [ ] Granting then revoking consent → events stop immediately
- [ ] Privacy settings accessible from Ajustes → Privacidade

## Crash Reporting

- [ ] Simulate crash → verify entry in Crashlytics / staging log
- [ ] FlutterError (e.g. overflow) → recorded without app crash
- [ ] Unhandled async error → `PlatformDispatcher.onError` fires

## Performance

- [ ] Cold start ≤ 2 s on mid-range device (Moto G7 class)
- [ ] Dashboard loads in ≤ 500 ms with 500 transactions in DB
- [ ] CSV export of 1 000 transactions ≤ 3 s
- [ ] Backup of full DB (1 000 transactions) ≤ 5 s
- [ ] Memory ≤ 120 MB during normal use (Android Profiler)
- [ ] No dropped frames during bill list scroll (60 fps target)

## Feedback Flow

- [ ] "Reportar Bug" → opens e-mail with pre-filled subject/body
- [ ] "Sugerir Funcionalidade" → opens e-mail
- [ ] "Avaliar o App" → opens Play Store listing
- [ ] When e-mail app not available → SnackBar shown

## Known Beta Limitations

- `package_info_plus` not yet added — version is hardcoded as `1.0.0+1`
- Firebase Analytics SDK not yet wired — events stored in-memory only
- iOS not supported in this release (Android only)
