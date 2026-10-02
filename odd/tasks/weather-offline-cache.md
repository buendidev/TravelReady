# Weather offline cache

## Objective
Keep SQLite as the single local database for TravelReady. Cache only recoverable OpenWeatherMap weather for a requested location; show the last cached reading when the network fails, with an explicit stale/age label. Do not replicate trips or packing in Hive.

## Current evidence and constraints
- `WeatherService` performs HTTP weather requests; `WeatherBloc` currently emits an error on failure, and Home owns the weather card.
- `DatabaseHelper` owns `travelready.db` schema v1; trips and packing use SQLite.
- `pubspec.yaml` contains recently added Hive declarations with no Hive implementation. Preserve pre-existing `.gga` and untracked `HANDOFF_TO_AGENT.md` changes; do not touch them.
- Firebase iOS is initialized using generated options in Dart; no native FirebaseApp.configure is needed for this cache.
- This feature does not certify Android/iOS production readiness.

## Acceptance
- Fresh requests for city and coordinates store weather with a retrieval timestamp and location-specific key.
- A failed request only falls back to the matching cached location, never silently to a different city; the UI labels stale data and its retrieval age. If no matching cache exists, show the existing error state.
- SQLite migration preserves existing v1 data, and caching does not modify trip/packing persistence.
- Existing and added focused tests pass, localization is updated, analyzer reports no new errors.

## Tasks
- [x] WOC-1: Implement a weather-only SQLite cache and safe v1-to-v2 migration, with persistence/migration tests. Route: delegated writer; multiple non-trivial files. Check: focused datasource/migration tests, including a real SQLite file reopening after upgrade. Evidence: RED/GREEN observed on mocked behavior tests; `flutter pub get` passed; `flutter test test/core/database/database_helper_test.dart` (4 pass), `flutter test test/data/datasources/local/weather_cache_datasource_test.dart` (5 pass). Real migration/reopen preserves existing trip and packing rows and cache. Commit: `cec7466` (`feat(weather): persist location-specific readings in SQLite`).
- [x] WOC-2: Wire weather Bloc and Home UI to matching cached fallback and explicit age label in supported locales; add focused Bloc/widget tests. Route: delegated writer; multiple non-trivial files. Evidence: RED observed because cache/state metadata APIs did not exist; `flutter gen-l10n` passed; `flutter test test/presentation/bloc/weather_bloc_test.dart test/presentation/pages/home/weather_data_card_test.dart` passed (17 tests). The implementation caches successful city/coordinate readings, falls back only for recoverable failures and matching keys, and preserves errors for invalid city/API-key failures or missing cache. Commit: pending WOC-3 closure.
- [x] WOC-3: Verify no unused Hive dependency remains, then run full `flutter test` and `flutter analyze` at closure. The dependency cleanup was a no-op: `pubspec.yaml` contains no `hive`, `hive_flutter`, or `hive_generator` reference. Independent closure checks: full `flutter test` passed (146 tests); `flutter analyze` has no errors and no weather-feature diagnostics after lint cleanup, but exits nonzero with 142 unrelated pre-existing baseline warnings/infos. `git diff --check` has no whitespace errors. Commit: pending final work-unit commit and native review.

## Verification and delivery
TDD mode: strict, explicitly selected by the user for WOC-1; behavior RED/GREEN and refactor observed, though the later real-file migration test first ran green because migration was already present. Runner: Flutter CLI (`flutter test`, `flutter analyze`), executable `/c/flutter/bin/flutter`. Focused WOC-1 checks passed; full suite and analyzer pending.
Branch: `feat/weather-offline-cache` created from `main`; user authorized local work-unit commits, not push/PR. WOC-1 commit: `cec7466` (331 added and 2 deleted authored lines, including tests). RDD: enabled; committed-only `assess` failed as unassessable due undeclared pre-existing untracked files; independent verifier reran both focused suites (4+5 passing). Native `inspect` with `untrackedScope: exclude` offered a workspace candidate containing only the pre-existing `.gga`, not commit `cec7466`, so no review was started for that unrelated target. Delivery strategy: ask-on-risk; user selected `stacked-to-main` for >400-line forecast. No push or PR authorized; first proposed review slice is WOC-1 (`cec7466`), second would contain WOC-2/3 once verified.

## Progress
Decision: SQLite is the source of truth; the user selected SQLite rather than Hive for the weather cache and approved a clearly marked stale reading offline.
Next: WOC-1 implementation and independent focused checks passed (4+5 tests), but native review is blocked. `inspect` offered only unrelated `.gga`. A single committed-only START with full `baseRef=f0abacf5ca24f33286af2db0698a480fcdf67db9` failed before lineage creation with `candidate-target-projection-drift`; no review verdict/receipt exists for `cec7466`. Do not retry without a freshly supported route or explicit resolution. WOC-2 and WOC-3 implementation/checks are complete; prepare their isolated work-unit commit and review it through a fresh supported route. `.gga` and HANDOFF are untouched; `sqflite_common_ffi` is dev-only.
