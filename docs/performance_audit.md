# Paguei? — Performance Audit Checklist

> Run this audit before every release build and after any major feature addition.

---

## Startup Performance

| Metric | Target | Measurement method |
|---|---|---|
| Cold start (first install) | ≤ 2 000 ms | `flutter run --profile` + DevTools Timeline |
| Warm start (process alive) | ≤ 300 ms | DevTools → App startup |
| DB first query | ≤ 200 ms | Add stopwatch in `_bootstrap()` |

**Known startup costs:**
- `tz.initializeTimeZones()` adds ~50 ms — runs in `NotificationInitializer` (background)
- `buildDatabase()` opens SQLite on disk — uses `NativeDatabase.createInBackground`

---

## Database

| Operation | Target | Notes |
|---|---|---|
| 1 000 transactions select | ≤ 100 ms | Add index on `date DESC` |
| Monthly summary aggregate | ≤ 50 ms | Uses `getMonthlySummary()` DAO |
| Full DB export (backup) | ≤ 5 s | Uses wide date range query |
| Backup file size (1 000 tx) | ≤ 500 KB | GZip compression applied |
| Index coverage | All `WHERE` columns | Run `EXPLAIN QUERY PLAN` in DBeaver |

**Missing indexes to add for v1.1:**
- `transactions(date)`
- `transactions(account_id)`
- `bills(due_date)`
- `bills(status)`

---

## UI / Rendering

| Check | Target | Measurement |
|---|---|---|
| Bill list scroll (500 items) | 60 fps | DevTools → Performance overlay |
| Dashboard initial render | ≤ 16 ms | Flutter DevTools frame chart |
| Large CSV export (1 000 rows) | ≤ 3 s | Wall-clock test |
| Backup create (1 000 tx) | ≤ 5 s | `Stopwatch` in `BackupSettingsNotifier` |

**Heavy widgets to check:**
- `DashboardScreen` — multiple `StreamProvider`s; consider `SliverList` for bill tiles
- `ExportCenterScreen` — CSV runs on main isolate; move to isolate if > 500 rows (see `AppConstants.csvExportIsolateThreshold`)

---

## Memory

| Metric | Target | Measurement |
|---|---|---|
| Baseline RSS | ≤ 80 MB | Android Profiler |
| Peak during backup | ≤ 150 MB | Profile build, GZip buffer is in-memory |
| BufferedLogger ring buffer | ≤ 1 MB | 100 entries × ~100 bytes |

**Memory risks:**
- `InMemoryAnalyticsService.maxEvents = 200` — bounded
- GZip encoding of full DB holds the entire JSON in RAM before compression
  - Mitigation: add streaming encoder in v1.1 for very large DBs

---

## Network (future)

When analytics/sync backend is added:

- [ ] All requests use HTTPS (enforced by `network_security_config.xml`)
- [ ] Analytics events batched (max 50 per flush)
- [ ] Retry with exponential backoff on failure
- [ ] No requests on metered connections for large sync operations

---

## App Size

| Artefact | Target |
|---|---|
| Universal APK | ≤ 30 MB |
| `arm64-v8a` APK | ≤ 20 MB |
| AAB (download size) | ≤ 15 MB |

**Size reduction checklist:**
- [ ] `syncfusion_flutter_pdf` — largest dependency; evaluate lazy loading
- [ ] Lottie animation files ≤ 200 KB each
- [ ] Image assets compressed with `tinypng` / `cwebp`
- [ ] `--split-per-abi` used for APK builds
- [ ] `--tree-shake-icons` enabled (default in release)

---

## Profiling Commands

```bash
# Profile startup
flutter run --profile --target lib/main.dart

# Analyze size
flutter build apk --analyze-size --target lib/main.dart

# Dump render tree for specific screen
# In app: Cmd+P → "Dump render tree"
```
