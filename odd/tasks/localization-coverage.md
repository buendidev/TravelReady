# Localization coverage

## Objective
Every user-visible string in the itinerary and discovery features follows the app language, instead of being Spanish whatever the language.

## Evidence
The user reported that with the app in English, creating a new plan in the itinerary still showed Spanish. Confirmed in code: both feature pages had their copy written by hand as Spanish literals, because the feature was built while `lib/l10n/**` was declared outside its allowed surfaces — a deviation recorded in `trip-discovery-itinerary.md`. The category names lived in a Spanish-only `const Map<Enum, String>` per enum.

The existing tests could not catch it: they pumped those pages with no locale and no localization delegates, so the default English locale was ignored and the Spanish assertions passed against hardcoded text. Once the strings moved to l10n, those same tests failed with `Found 0 widgets with text containing Datos de ejemplo` — the defect becoming visible.

## Scope
- `lib/l10n/app_es.arb` and `lib/l10n/app_en.arb` plus the regenerated `lib/l10n/app_localizations*.dart`: 47 new keys, reusing `retry`, `save`, `search`, `transport` and `catOther` where the Spanish text already existed.
- `lib/presentation/pages/itinerary/itinerary_page.dart`, `lib/presentation/pages/discovery/discovery_page.dart`, `lib/presentation/widgets/discovery/place_card.dart`.
- New `lib/presentation/widgets/discovery/place_category_labels.dart`. `lib/core/services/places/place_category.dart` keeps only the enum, because labels now depend on the language and belong to the presentation layer.
- Tests: `test/presentation/category_labels_test.dart` rewritten, new `test/presentation/itinerary/itinerary_localization_test.dart`, and locale delegates added to two existing harnesses.

## Tasks
- [x] LC-1: Replace the label maps with `switch` functions over the closed enums, so adding a category breaks the build instead of the screen.
- [x] LC-2: Move every hardcoded string in both features to l10n keys in both languages.
- [x] LC-3: Use locale-aware date skeletons (`DateFormat.MMMEd`, `DateFormat.yMMMd`) instead of hand-written patterns.
- [x] LC-4: Fix the harnesses that ignored the locale, and add a test that fails if Spanish leaks into the English editor.

## Acceptance
With the app in English, the itinerary editor shows English for its title, fields, hints, time buttons, confirm button and all six categories, and no Spanish remains on that screen. Spanish is unchanged. No category label is resolved through `!`, and no feature string is a literal in the widget tree.

## Evidence
- New test: `flutter test --no-pub --no-test-assets test/presentation/itinerary/itinerary_localization_test.dart` -> exit 0, 2 passed. The English case asserts every editor label and category in English and asserts that six Spanish strings are absent; the Spanish case asserts the previous text still renders.
- Guard: `test/presentation/category_labels_test.dart` -> every enum value has a non-empty label in both languages, and the labels genuinely differ between them.
- `flutter test --no-pub --no-test-assets` -> exit 0, **289 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **75 infos**, zero warnings, zero errors.

## Not verified here
- No device pass in English: the phone was disconnected mid-session, so the English UI is proven by widget tests rather than on screen.
- Demo fixture content (venue names, descriptions, opening hours) stays in Spanish on purpose: it is provider data, and a real provider returns its own localised content.
- Only the two features the user named were audited string by string; the rest of the app was not.

## Next step
The website work (animations, multi-page, performance) and consolidating the repository into a single folder and a single branch.
