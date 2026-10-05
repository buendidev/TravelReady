# Home profile display stability

## Objective
Render real user names safely and refresh Home after emitted profile name/plan changes while preserving existing trip navigation and accessibility work.

## Evidence
Home trims then splits names on literal spaces and indexes the second token; repeated spaces can throw. Greeting separately uses untrimmed splitting. A runtimeType-only AuthBloc buildWhen suppresses authenticated-to-authenticated updates. Existing user equality includes name/plan but not photoUrl; photo-only emission is outside this slice.

## Scope and constraints
Selected discovery worktree only. Allowed authored implementation files:
- lib/presentation/pages/home/home_page.dart
- test/presentation/pages/home/home_page_accessibility_test.dart
Preserve existing dirty Home changes, List<Trip>.from normalization, active-first/earliest-upcoming behavior, all four existing tests, localized profile semantics and navigation. No AuthBloc/entity, dependencies, routing, global theme, localization or unrelated card changes. No secrets, accounts, network, devices, staging, commits or publishing. Commit authorization absent. Parent owns task record. Prior Home task evidence is historical and inconsistent; do not rewrite or claim new evidence for it.

## Tasks
- [x] HPD-1: Observed RED (7 passed, 8 failed), implemented local name normalization and auth rebuild correction; all 15 focused tests pass.
- [x] HPD-2: Independent verification passed: 15 focused Home tests, 231 full-suite tests, analyzer 116 infos and zero warnings/errors; scoped whitespace checks clean. Native review and device/browser visual approval remain excluded.

## Acceptance
Normalize whitespace once for initials and greeting. Repeated, leading/trailing, tabs and newlines are valid separators; preserve first-two-token initials. Empty/whitespace-only names use existing U and viajero fallbacks. Emitted authenticated name and plan changes update mounted Home without remounting. Photo-only equality changes are explicitly excluded. Existing four trip/accessibility/navigation tests remain passing.

At 320 logical pixels and 2x text scaling, probe a long name, no Flutter exceptions, avatar/initial containment and usable profile navigation. A responsive change is permitted only for an observed header-local failure; otherwise preserve layout. Widget geometry tests do not establish visual approval on a real device/browser.

## Checks
Test-first: observe meaningful RED for name crash and stale update before production edits, then unchanged assertions GREEN. Safe command: flutter test --no-pub --no-test-assets test/presentation/pages/home/home_page_accessibility_test.dart. Use mocked services/in-memory dotenv, no real .env. Ordinary Flutter-generated caches permitted. Independent verifier later runs full safe suite and analyzer; latest baseline 220 passing tests and 116 infos, zero warnings/errors. Record actual results, do not attribute baseline changes without evidence.

## Progress
HPD-1 writer ran `/c/flutter/bin/flutter test --no-pub --no-test-assets test/presentation/pages/home/home_page_accessibility_test.dart`: RED exit 1 with 7 passes/8 failures (repeated-space RangeError and suppressed update observed), GREEN exit 0 with 15 passes and unchanged assertions. Added nine name cases, mounted name/plan stream regression, responsive probe. Scoped git diff --check passed. Earlier dirty TripModel/trip/accessibility work preserved.

320px/2x long-name widget probe passed: no Flutter errors, initials/avatar containment, semantics and profile navigation verified, viewport restored. No layout change was needed or made. Widget geometry is not device/browser visual approval. Photo-only user equality remains excluded. Full suite/analyzer pending.

Post-writer ASSESS returned unassessable because untracked declaration is required; independent verification mandatory. Native candidate remains mixed with pre-existing dirty changes; no approval claimed.

## Next step
Independent verifier completed focused tests (15 passed), full safe suite (231 passed), analyzer (116 infos, zero warnings/errors, no HPD-local diagnostics) and scoped diff check, all exit 0. Before/after git status inventory identical. Name/plan updates, nine name cases, 320px/2x probe and preserved trip/accessibility behavior verified. No correctness blockers found. No native review approval or device/browser visual approval. No commits authorized.

Stop here per user request to conserve remaining quota. Website improvements and further product work deferred; do not launch additional tasks.

## Commit record
- Work-unit commit: `b41305c fix(home): normalize profile names and refresh on emitted updates` on `agent/windsurf-discovery-itinerary`.
- Authorized by the user in a later session ("protect discovery: commit by work unit"). Earlier sessions had withheld commit authorization while model quota was nearly exhausted; that hold was lifted for this worktree and branch only. Push, PR and merge remain unauthorized.
- Content preservation: every path committed here was hashed with `git hash-object` before the commit sequence and re-read with `git rev-parse HEAD:<path>` after it. All 55 pre-existing paths matched exactly, so the committed bytes are the bytes that were independently verified below.
- The commit contains only the HPD hunks of `home_page.dart` and only the HPD cases of the Home test file; the trip-normalization change was split into `e819f29` so neither task hides inside the other.
- Focused check on the isolated commit content: `flutter test --no-pub --no-test-assets test/presentation/pages/home/home_page_accessibility_test.dart` exited 0 with 14 passing tests in the HPD-only intermediate state, then 15 passing with the runtime-stability regression restored.
- Not verified in this session: no device or browser visual approval, and the 320px/2x probe remains widget geometry only.
