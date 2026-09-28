# Offline-first storage and split sync implementation map

## Existing application audit (2026-09-28)

The Flutter application uses Riverpod 2 ChangeNotifierProviders. `main.dart`
loads `GardenStore`, runs recurring catch-up, initializes reminders, overrides
the providers, and starts update checks after `runApp`. There is no backend in
this repository: `site/` is an Astro marketing/download site, not an API.

### Persistence and exact backup envelope

`LocalGardenRepository` in `lib/data/garden_store.dart` reads/writes the
SharedPreferencesAsync key `money_plant.garden.v1`. Despite its name, the current
JSON has `schemaVersion: 2`. `GardenData.decode` accepts versions 1 and 2,
supplies v2 defaults, and validates money, IDs, participants and relationships.
Money is integer minor units. Dates use ISO-8601 strings. `self` is the local user.

The top-level envelope is:

| Key | Model/content |
| --- | --- |
| entries | Entry: id, title, amount, date, createdAt, category, kind, notes, splitId, goalId, importRef, recurringId, paymentId |
| tasks | GardenTask: id, title, date, amount, direction, completed, notes, personId |
| goals | Goal: id, title, target, date, icon |
| contributions | Contribution: id, goalId, amount, date |
| people | Person: id, name; all existing people are local |
| splits | BillSplit: id, title, total, date, method, portions, payerId, groupId, items, notes |
| payments | Payment: id, splitId, personId, amount, date, note |
| groups | Group: id, name, emoji, memberIds, createdAt, archived |
| groupSettlements | GroupSettlement: id, groupId, fromId, toId, amount, date, note |
| recurring | RecurringRule: id, title, amount, category, kind, frequency, dayOfMonth, weekday, startDate, endDate, paused, lastGeneratedPeriod |
| budgets | category -> integer minor-unit limit |
| importMappings | bank key -> ColumnMapping (column indices and categoryRules) |
| activity | event key -> timestamp; also statement-import deduplication |
| profile | displayName, upiId, payeeName, includeQr, includeUpiLink (local payment profile) |
| theme, themePack, currency, appLock | local preferences |
| schemaVersion | backup format version, independent of SQLite schema version |

Nested SplitItem has name, amount, personIds and kind (item/tax/tip/discount).
Portions map person IDs to minor-unit amounts. Expenses, income, reimbursements
and settlements are kinds of Entry; separate expense/income tables would
duplicate the existing model. Categories are strings, not separate entities.

### Read/write paths and behavior

All financial persistence goes through `GardenStore.load/change/restore` and
`GardenRepository.read/write`. `change` clones and validates a snapshot, awaits
the write, then publishes it; failure preserves the previous visible state.
The repository abstraction already exists and should be extended, not replaced.

`garden_operations.dart` handles split edits/deletes, linked ledger entries,
payments, person rename/merge/delete, net balances, groups and settle-all.
`recurring_operations.dart` creates stable period IDs and runs on start/resume.
`core/import/matcher.dart` batches statement rows, mappings, people, splits and
payments in one `change`; activity/importRef prevent duplicates. Composer,
budgets, tasks, goals, themes, privacy and payment-profile settings also use
`change`. Reports/PDF/CSV and home/insights/ledger/people/split pages read the
store. None of these screens directly accesses SharedPreferences financial data.

Settings exports `store.data.encode()` as JSON file or clipboard; restore from
file or paste calls `store.restore`, replacing the local snapshot only after
validation. CSV and PDF are reports, not restorable backups. The real v1 fixture
is `test/fixtures/backup_v1.json`. Existing JSON backups include theme, currency,
app lock and UPI profile, but do not include reminder or app-update preferences.

`ReminderRepository` uses the same minimal string interface with a separate
`money_plant.reminders.v1` record containing preferences and delivered history.
`ReminderStore` subscribes to garden changes and schedules Android reminders,
with budget-warning deduplication. `AndroidReminderGateway` owns notifications,
permissions, timezone and tap routing. Other platforms remain unsupported for
scheduled notifications. `LocalUpdateStorage` uses `money_plant.updates.*` keys.
WorkManager currently has only the unique daily release-check job; it does not
read finances. One dispatcher must be extended if split background sync is added.

### UI, navigation, splash and tests

`MoneyPlantApp` selects one of five bundled theme packs (garden/sakura/neon/
mango/ocean), light/dark/system, then wraps the shell in launch, lock and notice
hosts. GardenShell selects five tabs by index: Overview, Insights, Tasks, Splits,
Ledger. Details use MaterialPageRoute and existing modal-sheet helpers.
Reuse theme tokens, Surface, DepthIcon, typography and spacing.

The 1,400 ms LaunchExperience paints a seed, plant, particles, scrambled title,
tagline and circular reveal. It starts only after all awaited initialization,
builds the child underneath, and any tap finishes it immediately. Reduced motion
also finishes immediately. The reveal begins at 89% while the tagline completes
at 1,250 ms; startup work is not coordinated with animation. Existing tests
assert child existence underneath the overlay, not completion of the drawing.

Tests cover schema v1/v2, failed writes/restores, split allocation and settlements,
recurring catch-up, statement matching, PDF content, UPI, themes/contrast,
reminders, release updates and widget screenshots. No SQLite or online identity
tests exist at baseline. Android device upgrades and QR scanning require device
integration checks beyond the host test suite.

## Ordered implementation map

1. Record audit and run baseline analyzer/tests.
2. Extract existing string repository interface/legacy adapter into its own file;
   retain exports for existing tests and ReminderRepository compatibility.
3. Add local SQLite behind GardenRepository, using a table per existing entity,
   atomic snapshot transactions and a separate versioned metadata table.
4. Migrate once inside a transaction: parse/validate legacy JSON, preserve IDs and
   ordering, read back and compare every field, then mark complete. Never delete
   or overwrite the legacy key. Database existence alone is not success.
5. Switch startup to the SQLite adapter; existing features retain their store API.
6. Exercise backup/restore against real SQLite, including rollback and reopening.
7. Coordinate startup and existing animation; do not add an arbitrary delay.
8. Add optional split profile and explicit username-sharing UI only alongside a
   real API client. No historical data or custom people enter a sync queue.
9. Keep backend separate; immutable users, unique usernames, hashed device
   credentials, one active device, idempotent splits and cursor feed.
10. Store explicit outgoing operations and incoming state transactionally;
    credentials must be separate from GardenData and normal exports.
11. Integrate incoming dues with existing balances and notification infrastructure;
    trigger sync at startup/resume/tab/manual/reconnection/background.
12. Add expiring one-use device transfer with QR, credential rotation and revoked
    old-device access; a local restore never authenticates a username.

Each milestone must pass analyzer and tests before the next. No commits or pushes
are authorized. Production backend hosting/configuration is not present.

## Validated storage implementation

SQLite schema v1 is declared in `lib/data/sqlite_schema.dart`. Ten entity tables
contain typed columns, stable primary IDs and explicit list positions. Nested
portions/items/group members have JSON columns; activity, budgets and import
mappings have key/value rows. Settings are separate key/value rows. There are
indexes for split-linked entries, split/person payments and group splits.
`storage_metadata` contains revision and one-time migration state, excluded from
portable backups. References retain the existing model validator, including
intentionally retained provenance to deleted goals/recurring rules.

The initial adapter preserves the store's atomic snapshot behavior, including
transactional replacement and read-back verification. It is not yet a paginated
query layer: large histories still load into memory and a write replaces the
snapshot's entity rows. A revision check rejects stale cross-session writes.

`initializeFromLegacy` performs the whole migration and completion marker in one
transaction, compares canonical v2 snapshots, preserves all model values and
retains the untouched legacy preference indefinitely. A failed migration can be
retried; corruption after a completed migration never silently loads stale JSON.
Future schemas must add explicit upgrade steps; unknown newer schemas fail
without deletion. Backup format remains v2 and continues to accept v1.

Mobile uses sqflite; desktop uses its FFI adapter; browser uses the persistent
IndexedDB-backed SQLite worker. The worker/WASM are bundled under `web/` so no
CDN is required at runtime. The web adapter is upstream experimental and browser
storage remains origin-specific. See [sqflite documentation](https://pub.dev/packages/sqflite)
and [web adapter setup/limitations](https://pub.dev/packages/sqflite_common_ffi_web).

Checks so far: baseline analyzer clean and 95 tests passed; extracted repository
analyzer clean and 36 focused tests passed; SQLite/migration analyzer clean and
6 real database tests passed; after switching startup, 101 tests passed.
