# Home contextual plan

## Goal
Make the Home screen visibly prioritize the user's active or next trip and provide one clear primary action to continue planning.

## Scope
- `lib/presentation/pages/home/home_page.dart`
- `test/presentation/pages/home/home_page_accessibility_test.dart`

## Constraints
- Preserve current routing, trip model, localization convention, and theme behavior.
- No backend, schema, dependency, Firebase, or environment changes.
- Keep the existing avatar accessibility behavior.
- Do not run whole-file formatting or modify unrelated code.
- No commit, push, or parent-worktree changes.

## Tasks
- [x] Add a focused widget test that demonstrates the new contextual Home action and its trip-detail navigation.
- [x] Implement the contextual primary action for the active trip, otherwise the next trip, with an empty-state-safe fallback.
- [x] Run focused and full Flutter checks; inspect the diff and prepare an APK retest handoff.

## Evidence
- `flutter test test/presentation/pages/home/home_page_accessibility_test.dart` (RED): failed as expected before implementation; the contextual `ElevatedButton` was not found.
- `flutter test test/presentation/pages/home/home_page_accessibility_test.dart` (GREEN): passed, 3 tests.
- `flutter test`: passed, 161 tests.
- `flutter analyze`: failed with 117 existing info-level issues; none are in the Home contextual-plan files.
- `git diff --check`: passed (no output).
- Independent verification: selection is active-first then earliest upcoming, null-safe for empty trips; localized navigation/action and avatar semantics were confirmed. Full suite passed 161 tests. The analyzer reports 117 pre-existing info-level diagnostics and none in this slice.
