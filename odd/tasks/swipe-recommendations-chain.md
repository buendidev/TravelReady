# Swipe recommendations delivery chain

Delivery record for the swipe recommendations feed. The feature is one chain of
review slices; nothing lands on the default branch until the chain is reviewed.

| Field | Value |
| --- | --- |
| Chain | swipe-recommendations |
| Strategy | `feature-branch-chain` (owner decision, 2026-10-09) |
| Base | `main` |
| Tracker | this branch, `feat/swipe-feed-chain`, draft/no-merge |
| Review budget | 400 changed lines per PR |

## Slices, in order

Sizes are changed lines with generated `app_localizations*.dart` excluded. Every
slice is the smallest cohesive unit the feature allows: a runtime layer plus the
tests that bite on it.

| # | Branch | Content | Changed lines | Base |
| --- | --- | --- | --- | --- |
| 1 | `feat/swipe-feed-01-shared-sheet` | one shared place details sheet and the add-to-itinerary path, reused by discovery | 674 | tracker |
| 2 | `feat/swipe-feed-02-domain-core` | provider-neutral place key and the feed filters; deterministic feed composition | 646 | 1 |
| 3 | `feat/swipe-feed-03-persistence` | reaction tables in the central schema (v3) and their local persistence | 1044 | 2 |
| 4 | `feat/swipe-feed-04-use-cases-blocs` | feed, refill and reaction use cases; feed and favorites blocs | 1971 | 3 |
| 5 | `feat/swipe-feed-05-swipe-deck` | the swipe card deck | 1011 | 4 |
| 6 | `feat/swipe-feed-06-screens-routes` | feed screen, Favorites tab, routes and the trip-detail entry points | 1930 | 5 |
| 7 | `feat/swipe-feed-07-account-reactions` | the feature record, and the owner's revision: reactions belong to the account | 1140 | 6 |

## What has to be true before the tracker merges

- All seven child PRs reviewed and merged into their parents, in order.
- Each slice keeps the default branch green on its own terms: `flutter analyze`,
  `flutter test`, the site checker, the tool tests and the release-config
  validator.
- No slice leaves more than one deliverable scope.

## Honest notes for the reviewer

- **The slices are over budget, and that is the finding of the one slicing pass
  allowed.** The feature is 3296 production lines and 3980 test lines; tests are
  about 55 % of every slice, and no cohesive split fits 400 lines. Cutting tests
  or code to fit the number is not allowed, so the slices stay as they are and
  the overage is reported instead of hidden.
- **Slices 1 to 6 carry the pre-revision signatures.** The owner revised the
  reaction scope after the feature was written: reactions belong to the signed-in
  account, not to the phone. That revision is applied in one piece in slice 7,
  because it crosses the datasource, the repository, the use cases, the blocs and
  the screens. Reviewing it as its own slice keeps the diff coherent instead of
  smearing it across five slices.
- **The `size:exception` label does not apply here.** It is policy for Gentle's
  own repositories, not a universal requirement, and this repository has no such
  policy. The destination policy is the owner's review, with the counts stated.
- Not verified anywhere in the chain: a real device pass. Gestures, haptics and
  the snackbar position over the bottom bar are covered by widget tests only.
  The script for when a device is available is
  `docs/production/android-family-test.md`.
