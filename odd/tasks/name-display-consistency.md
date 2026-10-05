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

## Follow-up work unit: chats UI
Delivered as a second commit on the same branch.

- `_ChatTile` in `chats_page.dart` declared its chat as `dynamic` and then read `chat.name as String`, which disables static checking for a value that is always a `ChatSummary`. It is now typed `ChatSummary` and the redundant casts are gone.
- Four call sites used `name.isNotEmpty ? name[0].toUpperCase() : 'U'` (`chats_page.dart`, `chat_detail_page.dart`, `create_group_page.dart`, `users_page.dart`) and now use `nameInitials`.
- `create_group_page.dart` also cast a nullable selected-user name straight to `String` for both the chip avatar and its label; both are null-safe now.
- `grep -rnE "name\[0\]|chatName\[0\]" lib/` returns nothing: no ad-hoc character indexing on user names remains in `lib/`.
- The chats page had no test before. A new widget test covers six cases: repeated spaces, padding, whitespace only, tabs and newlines, an empty name, and a group chat that must show its icon instead of initials.
- RED before the change: 2 passed, 3 failed (`'Ana  Pérez'` rendered `A`, `'  Ana  '` rendered a space, `'	Ana	Pérez
'` rendered a tab).

### Evidence
- `flutter test --no-pub --no-test-assets test/presentation/pages/chats/chats_page_test.dart` -> RED exit 1 (2 passed, 3 failed), then GREEN exit 0 (6 passed).
- `flutter test --no-pub --no-test-assets` -> exit 0, **270 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, 116 infos, zero warnings, zero errors: the count returned to its baseline after the previous unit and did not move here.

## Not verified here
- No device or browser render; every assertion is widget-level.
- The group-name path in `chats_page.dart` and the AI/support tiles are rendered by the same page test only indirectly.
