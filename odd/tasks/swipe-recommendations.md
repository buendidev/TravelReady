# Swipe recommendations feed (Favorites / hidden Dislikes)

**Status: implemented on `feat/swipe-feed` as 11 work-unit commits plus this record; CI-equivalent
run green. Not verified on a device.** Specification: `docs/handoff/recommendations-feed.md`
(not edited: that directory is a spec, this file is the task record).

A traveller opens a trip, picks `Recomendaciones` and browses recommended places one card at
a time. Right swipe saves a favorite, left swipe hides the place for good, and four filters
narrow what is offered. Favorites open the existing details sheet, so the official site and
"Añadir al itinerario" work unchanged. It runs on the demo gateway and is labelled as such.

## Quick path to review

1. Read the **Decisions** table: five points where I made a call the spec left open or where
   it could not be followed to the letter. Disagree there first.
2. Walk the commits in order (table below); each one stands alone and carries its tests.
3. Check **Verification** and **Limits**.

## Acceptance against the spec

| Spec rule | Enforced in | Proof |
| --- | --- | --- |
| §2.1 right = like, left = dislike | `SwipeCardDeck._onPanEnd`, `ReactToPlaceUseCase` | deck tests for drag, fling, buttons; mutation "inverted direction" is caught |
| §2.2 a dislike is invisible, with a reachable reset | `confirmAndResetFeed`, overflow menu, exhausted state | page tests: reset needs confirmation, clears dislikes only, revives an exhausted feed |
| §2.3 like and dislike are exclusive | one SQLite transaction per write in `FavoritesLocalDataSource` | datasource test over any sequence of reactions; mutation "drop the cross-delete" is caught by 3 tests |
| §2.4 never claim live data in demo | feed view: demo label, typed-city field hidden | page test: label shown, no `TextField`, no destination text |
| §2.5 no provider id or photo reference stored | `FavoritePlace` has no such fields; `place_dislikes` is `(place_key, created_at)` | schema asserted column by column on a real v2 to v3 upgrade |
| §2.6 no new network dependency, analytics or tracking | no dependency added (`pubspec.*` untouched) | `git diff main..HEAD -- pubspec.yaml pubspec.lock` is empty |
| §4 filters, hotel and other never shown | `RecommendationFilter`, `composeFeed` | filter and composer tests |
| §5 algorithm: exclusions, seeded order, refill, exhausted | `composeFeed`, `GetRecommendationFeedUseCase`, `RefillRecommendationFeedUseCase`, `RecommendationsBloc` | domain and bloc tests, including "a refill never resurrects a seen key" |
| §6 `place_key` = sha256 of normalised name and address or rounded coordinates | `placeKey` | 16 tests: case, accents, spacing, blank address, coordinate rounding, negative zero, collision |
| §7 accessible buttons, undo, states | deck buttons and semantic actions, undo snackbar | semantics tests; undo is single-step and short-lived |
| §8 Favorites tab and the itinerary path | `FavoritesView`, `showPlaceDetailsSheet` | persists an `ItineraryItem` for the right trip and day; failure leaves the sheet open |

## Commit record

Sizes are changed lines (additions + deletions), generated `app_localizations*.dart`
excluded. Across the branch 3296 are production lines and 3980 are test lines (about 55 % tests).

| # | Commit | Unit | Prod | Test |
| --- | --- | --- | --- | --- |
| 1 | `eb641e0` | refactor(discovery): share the place details and add-to-itinerary sheets | 545 | 129 |
| 2 | `262b38b` | feat(recommendations): place key and feed filters | 154 | 189 |
| 3 | `1c86624` | feat(recommendations): deterministic feed composition | 106 | 197 |
| 4 | `0a8dc07` | feat(database): reaction tables in the central schema (v3) | 38 | 131 |
| 5 | `2b1166d` | feat(recommendations): persist favorites and dislikes | 414 | 461 |
| 6 | `7eeb4e8` | feat(recommendations): feed, refill and reaction use cases | 209 | 643 |
| 7 | `4a135c5` | feat(recommendations): feed and favorites blocs | 510 | 609 |
| 8 | `463d9d7` | feat(recommendations): swipe card deck | 507 | 504 |
| 9 | `9b21250` | feat(recommendations): swipe feed screen | 452 | 620 |
| 10 | `f27d09d` | feat(recommendations): Favorites tab and its itinerary path | 333 | 445 |
| 11 | `358fe01` | feat(trips): trip detail entry points | 28 | 52 |

Full hashes: `eb641e02ccbfc991b3cff60a821a071b37ad1adb`, `262b38b921a7ba14f694469b7a5002bc3b7183ec`,
`1c86624432596b73f14af27065da0299457442fa`, `0a8dc074edd9e364c9d5fceca8d2b39f3a90d00c`,
`2b1166d38eb0d342250a7a448ce01d4d1c2c05ae`, `7eeb4e8ba5f8c91bc53505d4511703e6d994705e`,
`4a135c5893c6f1e772d25fb20f2be390132795d9`, `463d9d742c3129f22a585a1bad3a85e9037dd190`,
`9b212508d172f4d85a9513e5d974cbd3f3946e6e`, `f27d09d37a756d5d30c5f1243596ba3a87b3a5ee`,
`358fe01a7b821d47c68a0b9891db5c05428280a3`. The commit that adds this record is the branch tip
(`git log -1`); a commit cannot name its own hash.

Revert from the tip downward, because later units build on earlier ones (see the dependency
column of the slice table). Reverting 11 alone removes only the two entry points; reverting
11, 10 and 9 removes the screens and leaves the data, domain, blocs and deck inert.

## RED before GREEN

Every unit started with tests that failed for the right reason, then went green.

| Unit | RED observed | Notes |
| --- | --- | --- |
| 1 | `place_details_sheet_test` failed to compile: file and function missing | the 9 existing `DiscoveryPage` tests were the safety net and stayed green untouched |
| 2, 3, 5, 6, 7, 8, 9, 10 | compilation failed on the missing production files | then green on implementation |
| 4 | compilation failed on the missing `tablePlaceFavorites` and `tablePlaceDislikes` | two existing migration tests were rewritten and the fresh-schema inventory extended, see Decisions |
| 11 | 3 of 4 new tests failed (the missing actions); the 4th is a wording guard that already held | the guard fails if copy ever says "this trip" |

Two honest exceptions: the route tests of unit 9 and the `/favorites` route tests of unit 10 were
written after the route existed, so they were never red; the mutation table shows they bite
(renaming the path or ignoring the tab fails them).

Green on first run does not prove a test bites, so I mutated the implementation and required a
failure. Each mutation was reverted and the file re-verified.

| Area | Mutations caught |
| --- | --- |
| Datasource | removing the like-clears-dislike delete (3 tests) |
| Bloc | dropping the top-card key guard (2), forgetting an exhausted provider (1), skipping the revert on a failed write (1), refill ignoring seen keys (2) |
| Deck | threshold 35 % to 50 % (4), fling speed 800 to 5000 (2), no haptic (1), inverted direction (2), no keep-the-deck fallback (1), buttons live while committing (1, after I added the missing test) |
| Feed view | persistent snackbar (2), city field in demo (1), snackbar covering the buttons (1), reset without confirmation (1), demo label removed (2) |
| Favorites | sheet without a trip (4), removal turned into a dislike (1), reset on every tab (1), favorites route ignoring the tab (1), stacked subscriptions (1, after I added the missing test) |
| Route | renaming the path (2) |

## Decisions

These are the calls worth challenging.

| # | Decision | Why |
| --- | --- | --- |
| 1 | **Shuffle inside each category, then interleave** (spec §5.5 lists interleave, then shuffle) | A global shuffle after the interleave destroys the alternation the interleave exists for. The order of the categories is shuffled too, so "Todos" does not always open on the same one. Tests assert alternation for several seeds, same seed same order, other seed other order. |
| 2 | **Sibling routes and a new `RecommendationsPage`**, not tabs inside `DiscoveryPage` (§3 allows a sibling route) | Hosting the feed in `DiscoveryPage` would have meant rewriting its 9 verified tests and dropping the text-search list. It stays as is; the new page is reached from the trip detail. Routes: `/trips/:id/recommendations` and `/trips/:id/favorites`. |
| 3 | **Demo mode hides the typed-city field** | `DemoPlacesGateway` ignores the location, so a city field would imply city-specific results and break §2.4. The field appears only for `configured` providers. |
| 4 | **Schema v3 with an additive migration**; two existing migration tests rewritten and the fresh-schema inventory extended | §3 asks for the central registration this time. The old tests encoded "v3 creates nothing"; they now say v1 to v3 creates the cache plus the two tables, and the no-op cases moved to 3 to 3 and 3 to 4. DDL is one idempotent function shared by `createSchema`, `upgradeSchema` and the datasource's lazy path; a test asserts fresh and upgraded DDL are identical. |
| 5 | **Refill widens the request window on each attempt**, and a provider with nothing new is remembered | The gateway has no paging, so repeating the same call can never return anything new. Two attempts per action still bounds the load (§5.7). |

Smaller choices, all covered by tests:

- A reaction is applied to the deck first and persisted after, and put back on failure. The
  event carries the card key, so a double tap reacts once and a stale event is ignored.
- The undo snackbar sets `persist: false` and floats above the buttons. Flutter makes a
  SnackBar with an action persistent by default, and a fixed one covered the reaction
  buttons; both were real defects that tests caught.
- The four filters use a `Wrap`. In a horizontal list the fourth chip was off screen.
- Accent folding is an in-repo Latin table; `crypto` was already a dependency.
- `PlaceCard` gained an optional `trailing`, additive and defaulting to the chevron.
- Removing a favorite shows a confirmation snackbar without undo; it is easy to like again.
- A damaged favorites row is skipped instead of failing the whole list.

## Verification

Run on Windows against Flutter 3.44.0, the version CI pins. Counts are before to after.

| Check | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | passes; `pubspec.yaml` and `pubspec.lock` untouched |
| `dart run tool/release_config_validator.dart` | passes |
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | exit 0, **75 to 75** infos; same diagnostics per file and rule, none in files this feature created or edited |
| `flutter test` | exit 0, **437 to 702 tests**; test files 42 to 58 plus 1 support file |
| `python tool/check_landing.py` | OK, 13 pages (`python3` is not on this Windows machine; `python` is 3.14) |
| `python -m unittest discover -s tool -p "*_test.py"` | 103 tests OK |
| `python tool/check_tracked_inputs.py` | OK |
| `git diff --check main..HEAD` | clean |
| Forbidden surfaces (`website/`, `firestore.rules`, `storage.rules`, `firebase.json`, `.github/`, chat and assistant files, `pubspec.*`) | `git diff --name-only main..HEAD` over them is empty |
| Secrets | no key, token or credential in the added lines; commits carry no AI trailer |
| l10n | es and en have the same keys, 326 to 364 each; generated files regenerated with `flutter gen-l10n` and reproducible |

**Firestore rules emulator job: not run, and not part of this base.** `main` and `origin/main`
have no `rules_test/` and their `ci.yml` has no emulator job. That work lives on the unmerged
branch `ci/firestore-rules-emulator-suite`, which also carries a later `firestore.rules` change.
This branch does not touch the rules or the CI file. `AGENTS.md` ("Estado del repositorio")
says `main` already has that job; on this base it does not.

## Limits, stated up front

- **No device or emulator pass.** Gestures, haptics, spring feel and the snackbar position over
  the real bottom bar are covered by widget tests only. A phone pass is the next verification.
- **Demo feed is small.** The fixtures hold 7 feed-eligible places, so the feed exhausts after a
  handful of swipes. That is honest, and the exhausted state and reset are exactly for it. More
  fixtures would be a separate, labelled change to verified code.
- **Reactions are per device, as the spec decided.** The tables carry no user id, so on a shared
  device a second account sees the first one's favorites, and logging out does not clear them.
  Fixing that needs the user-scoped Firestore model and rules the spec defers.
- The location field and attribution are tested with a fake provider; no real provider exists yet.

## Deferred, from spec §10 and this work

- Cross-device favorites (user-scoped collection and rules, with the friends model).
- Real Google Places, a map view, sharing, bookings.
- Clearing reactions on sign-out, once the per-device decision is revisited.

## Delivery strategy: open, needs an owner decision

The branch is about 7.3k changed lines (generated l10n excluded), far over the 400-line review
budget, and 7 of the 11 commits are over it on their own, mostly because tests are about 55 % of
each. One honest slicing pass found no cohesive split that fits, so I recommend `size:exception`
per slice rather than cutting tests or code. I have not opened any PR.

| Slice | Commits | Changed lines | Depends on |
| --- | --- | --- | --- |
| A. Shared sheet | 1 | 674 | none |
| B. Domain core | 2, 3 | 646 | none |
| C. Persistence | 4, 5 | 1044 | B |
| D. Use cases and blocs | 6, 7 | 1971 | B, C |
| E. Swipe deck | 8 | 1011 | B, D (needs `PlaceReaction` from commit 6) |
| F. Screens, routes, entry points | 9, 10, 11 | 1930 | A, C, D, E |

Strategy to choose: stacked PRs to `main` (each slice lands alone, every slice keeps `main`
green) or a feature-branch chain with a draft tracker. Not decided here.

## Next step

Run it on a phone: swipe both ways, fling, drag short of the threshold, undo, reset, add a
favorite to the itinerary, then switch language and dark mode. Report anything that feels off in
the spring, the haptic tick or the snackbar position.
