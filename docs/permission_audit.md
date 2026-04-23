# Paguei? — Permission Audit

> Last audited: 2026-04-20

---

## Required Permissions

| Permission | API Level | Why needed | Declared in Manifest |
|---|---|---|---|
| `RECEIVE_BOOT_COMPLETED` | All | Re-schedule notifications after device reboot | ✅ |
| `POST_NOTIFICATIONS` | 33+ | Show local bill/debt reminders | ✅ |
| `SCHEDULE_EXACT_ALARM` | 31+ | Exact-time bill due notifications | ✅ |
| `USE_EXACT_ALARM` | 33+ | Alternative for exact alarms (no user grant needed) | ✅ |
| `VIBRATE` | All | Haptic feedback on notification | ✅ |
| `CAMERA` | All | Scan bill barcodes (QR/barcode scanner) | ✅ |
| `READ_EXTERNAL_STORAGE` | ≤ 32 | File picker for backup restore | ✅ |
| `READ_MEDIA_IMAGES` | 33+ | Camera roll access for bill photo (future) | ❌ (add when needed) |
| `USE_BIOMETRIC` | 23+ | Biometric unlock (local_auth) | ✅ |
| `USE_FINGERPRINT` | 23-28 | Fallback for older devices | ✅ |
| `INTERNET` | All | Future: sync / analytics backend | ❌ (add when needed) |

## Permissions NOT Required

| Permission | Reason for exclusion |
|---|---|
| `ACCESS_FINE_LOCATION` | App has no location features |
| `READ_CONTACTS` | No contact integration |
| `SEND_SMS` | No SMS features |
| `READ_CALL_LOG` | Not needed |
| `RECORD_AUDIO` | Not needed |

## Runtime Permission Handling

### `POST_NOTIFICATIONS` (Android 13+)
- Requested in `NotificationInitializer.run()` on first launch
- Rationale shown: "Para receber lembretes de boletos"
- If denied: notifications disabled, user can re-enable in Settings

### `SCHEDULE_EXACT_ALARM` (Android 12+)
- Deep-link user to `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` if needed
- Graceful fallback to `inexact` alarms if permission denied

### `CAMERA`
- Requested just-in-time when user opens barcode scanner
- Rationale shown before request

## Privacy-By-Design Notes

1. **No network permission** until analytics/sync backend is added — zero data exfiltration risk in current build
2. **Camera frames** never stored to disk — processed in-memory by ML Kit
3. **Biometric data** never extracted — local_auth uses OS-level check only
4. **Backup files** stored in `getApplicationDocumentsDirectory()` — not accessible by other apps
5. **Encrypted backups** use XOR + GZip; upgrade to AES-256 before v1.1

## Play Console Data Safety Declaration

| Data type | Collected | Shared | Encrypted | Required |
|---|---|---|---|---|
| Financial info (transactions) | No (local only) | No | Yes (SQLite) | No |
| App activity (analytics events) | Yes (if consent given) | No | N/A | No |
| Device/app IDs | No | No | — | No |
| Crash logs | Yes (if enabled) | No | Yes (TLS) | No |
| User content (backup files) | Device-only | No | Yes (optional) | No |
