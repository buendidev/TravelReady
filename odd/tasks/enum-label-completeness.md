# Enum label completeness

## Objective
Resolving the visible label of a category must not depend on a non-null assertion. Adding a value to either category enum must fail a test instead of crashing a screen.

## Evidence
Two lookups asserted on a const map:

| Site | Lookup |
| --- | --- |
| `itinerary_page.dart` item card | `_categoryLabels[dayItems[i].category]!` |
| `place_card.dart` discovery card | `placeCategoryLabels[place.category]!` |

Both maps cover every value of their enum today (`ItineraryCategory` has six, `PlaceCategory` has eight), so neither throws **right now**. The defect is conditional and cheap to reach: the assertion is a hard crash on a screen the traveller is looking at the moment somebody adds a category and forgets the label. Nothing failed at build time, and nothing failed at test time, because no test looked at the maps.

## Scope
`lib/core/services/places/place_category.dart`, `lib/presentation/widgets/discovery/place_card.dart`, `lib/presentation/pages/itinerary/itinerary_page.dart`, `test/presentation/category_labels_test.dart`. No visible text changes: every existing label keeps its exact string.

## Tasks
- [x] ELC-1: Add a total lookup with an explicit fallback label for both enums.
- [x] ELC-2: Move the itinerary labels out of the private class so they can be tested, and use the total lookup at both call sites.
- [x] ELC-3: Add a completeness guard covering every value of both enums, and prove with fault injection that it fails when a label is missing.
- [x] ELC-4: Verify with the full suite and the analyzer, then commit.

## Acceptance
No `!` remains on either label map. Every current enum value still resolves to its previous string. Removing a label from either map makes the guard fail with a message that names the missing category.

## Evidence
- Guard GREEN: `flutter test --no-pub --no-test-assets test/presentation/category_labels_test.dart` -> exit 0, 3 passed.
- Fault injection: removing `PlaceCategory.hotel` from the map -> exit 1 with `PlaceCategory.hotel se agregó al enum y le falta etiqueta`; restoring it -> exit 0, 3 passed.
- `flutter test --no-pub --no-test-assets` -> exit 0, **279 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, 75 infos, zero warnings, zero errors.
- `grep -rnE "CategoryLabels\[.*\]!" lib/` -> no matches.

## Not verified here
- No behavioural RED exists for this unit: no enum value is missing a label today, so the guard passes by design. Its failure mode was verified by fault injection instead.
- The labels remain hardcoded Spanish outside `l10n`, which is a known, recorded deviation of this feature rather than a defect introduced here.

## Next step
Nothing left on the hardening list. Remaining work for a complete release is owner-owned (signed APK, Google Cloud and Places configuration, Firebase rules, legal review) plus the pending browser and device verification.
