# Subscription package selection

## Objective
Prevent a requested monthly or yearly subscription from silently selecting a different available product. This is the first bounded production-quality improvement, not billing launch approval.

## Scope and constraints
- Selected checkout: ProyectoFinal_TravelReady_windsurf_discovery, branch agent/windsurf-discovery-itinerary.
- Preserve all existing app, itinerary, website and task changes; no integration of sibling worktrees.
- Allowed source surfaces: lib/core/services/revenuecat_service.dart and test/core/services/revenuecat_service_test.dart.
- Preserve existing matching conventions and getOfferings error behavior; unavailable requested period returns null rather than another package.
- No purchases, external accounts, secrets, entitlement redesign, dependencies, deployment or publishing.
- Commits require explicit user authorization; none requested. Work-unit commit pending.

## Tasks
- [x] SPS-1: Added 12 isolated regression tests; RED observed with 8 passes and 4 intended failures, followed by GREEN.
- [x] SPS-2: Removed arbitrary fallback while preserving first matches and exceptions; all 12 unchanged tests pass.
- [ ] SPS-3 (functional checks complete; native review pending): Independent full suite passed 220 tests, including 12 subscription regressions. Database safety blocker resolved. Native review remains blocked by mixed pre-existing candidate scope.

## Acceptance and checks
Monthly-only, yearly-only, unrelated products, empty offerings, and correct matches covered. No real SDK network/purchase calls. Empty offerings preserve the existing error contract. Run focused flutter tests, full flutter test, flutter analyze, and scoped diff whitespace checks. Record actual evidence and distinguish baseline failures.

## Progress
SPS-1: `flutter test --no-pub --no-test-assets test/core/services/revenuecat_service_test.dart` exited 1: 8 passed, 4 intended assertion failures, no tooling failures. Monthly returned yearly, yearly returned monthly, and both returned weekly for unrelated products. Production code is unchanged. Tests mock the purchases MethodChannel and configure dotenv in memory, without reading .env or making purchases/network calls. User explicitly approved this exact safe test command and ordinary generated Flutter test/build caches. Website and Home quality follow this bounded safety fix; external billing authority remains a release blocker.

## Next step
SPS-2 verification: `flutter test --no-pub --no-test-assets test/core/services/revenuecat_service_test.dart` exited 0, 12 passed. Only the selector bodies changed; no additional refactor.

Native ASSESS returned unassessable (untracked declaration required), so independent verification is mandatory. INSPECT projects existing router/itinerary/Home/localization changes alongside this service; no lineage started, no review approval claimed. Do not stage or commit unrelated changes to isolate the candidate.

Independent verification: focused command exited 0 with 12 passing tests. `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` exited 0: 117 infos, zero warnings/errors, no candidate-local findings; no clean baseline was run. Tracked service diff whitespace check exited 0. Untracked test no-index check exited 1 for nonidentical files, no whitespace-error diagnostics, LF-to-CRLF warning. Existing premium BLoC null guards return before purchases/account updates; structurally inspected, not directly tested.

Full suite NOT run: trips_local_datasource_test.dart and trips_repository_impl_test.dart delete/recreate the default database with no test-scoped path override. This may affect existing local data and is not an ordinary test cache. Missing configuration and SDK-error propagation were not directly tested; paths unchanged. No native approval, commits or publishing.

Follow-up DBI-2 resolved database isolation blocker: independent full `flutter test --no-pub --no-test-assets` exited 0, 220 passed without exclusions; all 12 subscription tests passed. Analyzer exited 0 with 116 infos, zero warnings/errors and no candidate-local diagnostics. No clean baseline run. Tracked whitespace checks passed; untracked no-index checks had no whitespace errors (exit 1 for nonidentical files, LF-to-CRLF warnings). Prior full-suite hold above is historical, now resolved.

SPS-3 remains open only for native-review isolation; no review approval or commit claimed. Functional correction is independently verified. Next product slice: scoped Home stability and UX exploration, preserving existing changes.

## Commit record
- Work-unit commit: `6c852bc fix(premium): stop substituting a different subscription package` on `agent/windsurf-discovery-itinerary`.
- Authorized by the user in a later session ("protect discovery: commit by work unit"). Earlier sessions had withheld commit authorization while model quota was nearly exhausted; that hold was lifted for this worktree and branch only. Push, PR and merge remain unauthorized.
- Content preservation: every path committed here was hashed with `git hash-object` before the commit sequence and re-read with `git rev-parse HEAD:<path>` after it. All 55 pre-existing paths matched exactly, so the committed bytes are the bytes that were independently verified below.
- The commit is the isolated candidate SPS-3 was waiting for: pre-existing router, itinerary, Home and localization changes are no longer mixed into this unit.
- Not verified in this session: no native review was started and no real RevenueCat offering or purchase was exercised.
