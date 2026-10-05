# Name display consistency

## Objective
Render user names safely and identically everywhere they appear as an avatar or greeting, starting with the Profile crash and removing the duplicated ad-hoc name parsing that let the same defect be fixed in one page and stay broken in another.

## Evidence
`_ProfileContent._initials` in `lib/presentation/pages/profile/profile_page.dart` is a copy of the pre-fix Home implementation:

```dart
final parts = name.trim().split(' ');
return parts.length >= 2
    ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
    : name.isNotEmpty ? name[0].toUpperCase() : 'U';
```

Observed failures against the shipped code (widget test, 3 passed / 5 failed):

| Case | Result |
| --- | --- |
| `'Ana  Pérez'` | `RangeError (index): Invalid value: Valid value range is empty: 0` — the Profile page crashes |
| `'  Ana  '` | renders a space instead of `A`, because `name.isNotEmpty` is evaluated on the untrimmed string |
| `'   '` | renders a space instead of `U` |
| `'\t\n '` | renders a tab instead of `U` |
| `'\tAna\tPérez\nLópez\n'` | renders an invisible tab instead of `AP`, because tabs and newlines are not separators for this implementation, so it falls back to the raw first character |

Home was fixed for exactly this defect class in `b41305c`; Profile kept the broken copy. Five further sites in the chats UI (`chats_page.dart`, `chat_detail_page.dart`, `create_group_page.dart` twice, `users_page.dart`) use `name.isNotEmpty ? name[0].toUpperCase() : 'U'` and mis-render whitespace for the same reason, but do not crash.

## Scope
Selected discovery worktree, branch `agent/windsurf-discovery-itinerary`, now carrying the merged production-readiness line.

Allowed authored surfaces:
- `lib/core/utils/name_display.dart` (new)
- `lib/presentation/pages/profile/profile_page.dart`
- `lib/presentation/pages/home/home_page.dart`
- `test/core/utils/name_display_test.dart` (new)
- `test/presentation/pages/profile/profile_page_test.dart` (new)
- `odd/tasks/name-display-consistency.md` (this file)

Out of scope for this unit: the five chats-UI initial sites (they mis-render but do not throw), photo-only user equality, localization of names, and any change to how names are stored or fetched.

## Tasks
- [x] NDC-1: RED observed against the shipped code: 3 passed, 5 failed, including `RangeError (index): Invalid value: Valid value range is empty: 0` for `'Ana  Pérez'`.
- [x] NDC-2: `lib/core/utils/name_display.dart` exposes `nameTokens` and `nameInitials`; 4 focused unit tests pass.
- [x] NDC-3: Profile resolves initials through the helper (the broken private copy is deleted) and Home uses `nameTokens`/`nameInitials`, so no page keeps its own parsing.
- [x] NDC-4: GREEN on the same nine Profile assertions, Home's fifteen cases unchanged, full suite 264 passed, analyzer exit 0 with 116 infos, zero warnings and zero errors.

## Acceptance
All whitespace forms are separators: repeated, leading, trailing, tabs and newlines. Initials use the first character of up to the first two tokens, uppercased. Empty or whitespace-only names use `U` for initials and `viajero` for the Home greeting. No name may throw. Profile and Home resolve initials through the same helper, so a future fix cannot land in only one of them.

## Checks
Test-first with observed RED (recorded above), then GREEN on the same assertions. `flutter test --no-pub --no-test-assets test/presentation/pages/profile/profile_page_test.dart`, then the Home test, then the full suite; `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings`. No device, network, secret or external action.

## Progress
Widget harness created for `ProfilePage`, which had no test at all: it needs a mocked `AuthBloc`, `TripsRepository`, `PackingRepository`, `TripsLocalDataSource`, plus `ThemeCubit` and `LanguageCubit` built with an in-memory `SharedPreferences`. `get_it` in this version has no `unregister(type:)`, so registrations are removed with explicit generics.

## Evidence
- `flutter test --no-pub --no-test-assets test/presentation/pages/profile/profile_page_test.dart` -> RED exit 1 (3 passed, 5 failed) before the change; GREEN exit 0 (9 passed) after it.
- `flutter test --no-pub --no-test-assets test/core/utils/name_display_test.dart test/presentation/pages/profile/profile_page_test.dart test/presentation/pages/home/home_page_accessibility_test.dart` -> exit 0, 28 passed.
- `flutter test --no-pub --no-test-assets` -> exit 0, **264 passed** (251 before this unit).
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **116 infos**, zero warnings, zero errors; the only new diagnostic this unit introduced was a dangling library doc comment, which was fixed, so the count returned to its baseline. The `curly_braces_in_flow_control_structures` info at `profile_page.dart:140` is pre-existing and just shifted by the deleted method.
- `ProfilePage` had no test file at all before this unit; the new widget test is the first coverage of that page.

## Not verified here
- No device or browser render; the assertions are widget-level.
- The five chats-UI initial sites still use `name.isNotEmpty ? name[0].toUpperCase() : 'U'` and remain unfixed by design (they mis-render whitespace but do not throw).

## Next step
Follow-up work unit: replace the five chats-UI initial sites with `nameInitials` so no ad-hoc name indexing remains in `lib/`, and add the missing widget coverage for those avatars.
