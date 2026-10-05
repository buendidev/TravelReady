# Trip detail responsive layout

## Goal
Remove the device-reproduced bottom overflow in TripDetailPage while preserving trip-planning entry cards and packing-list empty state behavior.

## Device evidence
On a 1080x2392 Android device, opening a trip with no packing lists renders `BOTTOM OVERFLOWED BY 117 PIXELS` below the empty packing state while the persistent bottom navigation is visible.

## Scope
- `lib/presentation/pages/trips/trip_detail_page.dart`
- `test/presentation/trips/trip_detail_page_navigation_test.dart`

## Tasks
- [x] Add a deterministic constrained-height regression test for the no-packing-lists detail state. (Committed as `de4245c`; the evidence section below already recorded the RED/GREEN result.)
- [ ] Fix the Sliver/empty-state layout without hiding content behind navigation or regressing planning CTAs.
- [x] Run focused/full checks and repeat the connected-device smoke test.

## Constraints
- No backend, Firebase, itinerary persistence, dependency, route, or global theme changes.
- Do not format unrelated code, stage, commit, or touch other worktrees.

## Evidence
- ADB screenshot captured the exact overflow after opening the trip-detail page from Home.
- Focused test passed 4/4, full suite passed 202/202, analyzer has only 117 existing infos, and diff-check passed.
- Device smoke: installed fresh debug APK over USB, opened the same zero-list trip from Home, and confirmed the empty packing state renders without an overflow banner or Flutter exception.
- Regression: `flutter test test/presentation/trips/trip_detail_page_navigation_test.dart` reproduces a `RenderFlex overflowed by 1.00 pixels on the bottom` at a deterministic 360×600 constrained viewport after scrolling to the zero-packing-lists state before the layout fix; it passes after using a non-scroll-body remaining sliver.
- Connected-device retest: launch the app on the 1080×2392 Android device, navigate Home → a trip with zero packing lists, scroll through the planning cards to the empty packing state, and confirm no `BOTTOM OVERFLOWED` banner appears and the New list action remains reachable.

## Commit record
- Work-unit commit: `de4245c fix(trips): keep the empty packing state inside the viewport` on `agent/windsurf-discovery-itinerary`.
- Authorized by the user in a later session ("protect discovery: commit by work unit"). Earlier sessions had withheld commit authorization while model quota was nearly exhausted; that hold was lifted for this worktree and branch only. Push, PR and merge remain unauthorized.
- Content preservation: every path committed here was hashed with `git hash-object` before the commit sequence and re-read with `git rev-parse HEAD:<path>` after it. All 55 pre-existing paths matched exactly, so the committed bytes are the bytes that were independently verified below.
- The commit contains only the two `hasScrollBody: false` changes and the single overflow regression; the trip-planning cards of the same file were split into `c58934e`. The regression test helper no longer carries the unused nested-route scaffolding.
- Focused check on the isolated commit content: `flutter test --no-pub --no-test-assets test/presentation/trips/trip_detail_page_navigation_test.dart` exited 0 with the single constrained-viewport regression passing.
- Not verified in this session: no connected device or emulator run; the historical device smoke recorded above was not repeated.
