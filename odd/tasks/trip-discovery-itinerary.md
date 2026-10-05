# Trip discovery and itinerary

## Goal
Provide visual destination discovery with Google Maps and Places data, then let the traveller add a selected place to a dated, timed itinerary entry and open the venue's official website for booking.

## Product boundaries
- Google Places price level is a broad affordability indicator, not a guaranteed admission or menu price.
- Opening hours and place information are provider-sourced and may be incomplete or change; official venue links remain the booking source.
- TravelReady opens the official venue URL externally; it does not make reservations.

## Mandatory owner prerequisites
- Enable billing and budget alerts in the chosen Google Cloud project.
- Enable Maps SDK for Android and Places API (New).
- Create and restrict appropriate API keys; do not place server secrets in Flutter `.env`, assets, source, or Git.
- Confirm the supported data-access architecture and Places attribution/caching policy before provider data is persisted.

## Tasks
- [x] Repair the local itinerary foundation: prohibit persisted provider identifiers/photo references, fix reorder bounds, surface write failures, and add regression coverage.
- [x] Add trip-detail entry points and resilient route behavior for discovery and itinerary.
- [ ] Complete Google Maps Platform owner configuration and record only non-secret identifiers/restriction evidence.
- [ ] Design and approve the supported real Places access architecture, attribution, caching, and retention boundaries before provider integration.
- [ ] Implement a safe Places gateway and map/search integration with loading, empty, error, attribution, and quota-safe behavior.
- [ ] Add deterministic tests, run Android/device verification, review a small commit-ready slice, and build a debug APK.

## Constraints
- No scraping or parsing Google Maps pages.
- No API secrets in Flutter assets, `.env`, repository files, tests, logs, or screenshots.
- Use existing `url_launcher` for official-site handoff.
- Keep worktree changes isolated; no commit, push, parent-worktree modification, or external provisioning without explicit owner action.

## Evidence
- Google Maps + Places and visual discovery + itinerary were selected by the user.
- Repository currently has `url_launcher`, SQLite-based trip persistence, and no maps/Places dependency.
- Phase 1 (itinerary foundation) implemented test-first: `ItineraryItem` (tripId, day, start/end minutes-since-midnight, title, category, notes, orderIndex) + provider-neutral `PlaceSnapshot`; self-migrating `itinerary_items` table in `ItineraryLocalDataSource` (lazy `CREATE TABLE IF NOT EXISTS` — avoids editing `lib/core/database/database_helper.dart`, outside the allowed surface; central migration remains a 1-line follow-up); `ItineraryRepository`+impl, 5 use cases, `ItineraryBloc` (stream-driven, like PackingBloc), `ItineraryPage` (day-grouped, reorder, add/edit sheet, empty/loading/error states), route `/trips/:id/itinerary` in `app_router.dart`, injection registered.
- Phase 1 checks: `flutter test` 181/181 green (20 new itinerary tests); `flutter analyze` 119 info-level issues, 0 in new files; `git diff --check` clean.
- Surface deviations to report: (a) `database_helper.dart` actually lives at `lib/core/database/` (handoff listed `lib/data/datasources/local/`) — left untouched via lazy table creation; (b) visible entry point on `trip_detail_page.dart` is outside allowed surfaces — routes exist at `/trips/:id/itinerary` and `/trips/:id/discovery`, need owner-approved CTAs or explicit surface widening; (c) `lib/l10n/**` is outside allowed surfaces so itinerary/discovery UI strings are hardcoded Spanish literals.
- Phase 2 (discovery UI): `PlacesGateway` boundary (`availability` + `attributionText`) in `lib/core/services/places/`; `DemoPlacesGateway` = 8 deterministic local fixtures (real Spanish venues, official URLs), labelled "Datos de ejemplo" in UI; `DiscoveryPage` (search field, category `ChoiceChip`s, loading/empty/error/unavailable states, `PlaceCard` with icon-fallback, details bottom sheet with indicative hours/price + "Sitio web oficial" via `url_launcher` + "Añadir al itinerario" day/time sheet dispatching `ItineraryItemAdded`); route `/trips/:id/discovery`; `PlacesGateway` registered in injection as demo impl.
- Phase 2 checks: 9 focused tests green (gateway determinism + snapshot retention boundary + all page states + add-to-itinerary persistence through repository); `flutter analyze` +0 new issues.
- Phase 3 (readiness): `MapAdapter` boundary (no impl — needs owner keys); `PlacesConfigFailure`/`PlacesQuotaFailure`/`PlacesParseFailure` under `services/places/` (kept out of `core/errors` — outside surface); `docs/places-integration.md` documents billing/budget-alerts, Maps SDK + Places API (New), Android-restricted keys, proxy architecture (no key in `.env`/APK), attribution/caching/retention policy.
- Phase 4 (landing): `website/index.html` + `styles.css` + `README.md` — static, ES-first, responsive, skip-link/aria/reduced-motion/dark-scheme, disabled APK CTA placeholder, contact/privacy marked `TODO(owner)`, zero JS/trackers. HTML parses clean (html.parser).
- Phase 2 bug found & fixed by tests: pop+push of stacked bottom sheets raced in hit-testing — solved by stacking the add-sheet over details (no pop).
- Independent audit found blockers before APK: provider ID/photo-reference persistence contradicts the stated policy; reorder can use an invalid index; writes do not fold failures; the feature lacks trip-detail entry points; and this fresh worktree lacks the ignored Firebase generated file used for analyzer checks. No live Maps/Places integration exists, by design, until owner configuration and policy approval.
- Repair verification: ignored Firebase options restored locally; focused repair tests passed 36/36, full suite passed 197/197, `git diff --check` passed. Analyzer has 117 pre-existing info-level diagnostics and no errors or repair diagnostics.
- Trip-detail entry verification: localized accessible discovery/itinerary CTAs pass the same Trip through nested routes; focused tests passed 3/3 and full suite passed 200/200. `git diff --check` passed. One non-blocking `prefer_const_constructors` info remains in the new TripDetail UI; the feature worktree is intentionally broader than this subtask.
- Demo APK verification: `.env`, ignored Firebase options, and ignored `android/app/google-services.json` were restored locally. `flutter build apk --debug` succeeded; artifact: `build/app/outputs/flutter-apk/app-debug.apk` (178,311,398 bytes).
- Local-foundation audit repair verification (isolated worktree): stored place maps contain only provider-neutral itinerary fields; `PlaceResult.toSnapshot()` drops provider IDs/photo references; demo fixture provider IDs remain transient. `reorderItineraryIds` adjusts downward indices and clamps bounds (first→end and upward regression coverage). All itinerary mutation `Either`s fold to `ItineraryError`; discovery confirms add only after `ItineraryMutationSucceeded` and leaves the add sheet open on failure. Existing regression tests and implementation were already present in the isolated dirty feature slice and were preserved rather than reset to manufacture a RED state.
- Audit repair checks: `flutter test test/data/itinerary test/presentation/itinerary test/presentation/discovery` — 36/36 passed; `flutter test` — 197/197 passed; `flutter analyze` — exit 1 with 119 pre-existing issues, including the known missing ignored `lib/firebase_options.dart` (and resulting `DefaultFirebaseOptions`) errors in `lib/main.dart`; no diagnostics in the audited allowed repair files; `git diff --check` — clean.
- Trip-detail entry-point slice: RED — `flutter test test/presentation/trips/trip_detail_page_navigation_test.dart` failed because neither "Planifica tu viaje" nor the itinerary/discovery CTA semantics existed; GREEN — the same focused test passed 3/3 after adding localized, semantic itinerary/discovery cards that push the existing nested route with the current `Trip` as `extra`. Full `flutter test` passed 200/200. `flutter analyze` reported only the existing 117 info-level diagnostics (exit 1), with none in the changed slice; `git diff --check` was clean. Manual Android retest: open a saved trip detail, verify both planning cards are visible and announceable, open each, confirm the itinerary/discovery receives the selected trip, use Back to return, and open each URL directly to confirm the existing missing-trip fallback remains unchanged.

## Commit record
Delivered as five work-unit commits on `agent/windsurf-discovery-itinerary`:
- `0b4d858 feat(itinerary): add trip itinerary persistence and use cases`
- `ac9ea15 feat(itinerary): add the day-grouped itinerary screen`
- `1402d55 feat(discovery): add a provider-neutral places gateway and discovery UI`
- `c58934e feat(trips): add itinerary and discovery planning entry points`
- `11440b3 feat(web): add the static public landing page`
- Authorized by the user in a later session ("protect discovery: commit by work unit"); earlier sessions withheld commit authorization while quota was nearly exhausted. Push, PR, merge and any store or infrastructure action remain unauthorized.
- Content preservation: all 55 pre-existing paths in this worktree were hashed before the sequence and matched `git rev-parse HEAD:<path>` afterwards.
- Verified in this session: full `flutter test --no-pub --no-test-assets` exited 0 with 231 tests passing both before and after the commit sequence; `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` exited 0 with 116 infos and zero warnings or errors.
- Still open, unchanged: task 3 (Google Cloud billing, Maps SDK and Places API (New) enablement, restricted keys), task 4 (approved real Places access, attribution, caching and retention architecture), task 5 (real gateway and map/search integration) and task 6 (connected-device verification and an owner-reviewed APK slice). The committed application therefore still runs the labelled demo gateway with local fixtures and no live provider call.
