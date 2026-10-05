# Debug logging hygiene

## Objective
Diagnostics must be useful while developing and silent in published builds, and must never carry user data.

## Evidence
`grep -rn "print(" lib/` found 45 call sites across eight files. Six interpolated the user's email address into the message and five more wrote raw error text (including Firestore exception messages) to stdout:

| Site | Leaked |
| --- | --- |
| `firebase_auth_datasource.dart:29` | `fbUser?.email` on every authentication state change |
| `firebase_auth_datasource.dart:146`, `:159` | Google account email, Firebase user email |
| `auth_bloc.dart:58`, `:73`, `:169` | `user?.email` on state changes, user changes and Google sign-in success |
| `firestore_chats_datasource.dart:257`, `users_page.dart:84` | raw exception text |

`print` writes to stdout in release builds too, so all of it is visible in a production console or `logcat`. That contradicts the data-minimization posture recorded for PRF-1.

## Scope
New `lib/core/utils/app_log.dart`; eight migrated files (`core/security/env_validator.dart`, `core/utils/env_validator.dart`, `data/datasources/remote/firebase_auth_datasource.dart`, `data/datasources/remote/firestore_chats_datasource.dart`, `main.dart`, `presentation/bloc/auth/auth_bloc.dart`, `presentation/bloc/premium/premium_bloc.dart`, `presentation/pages/chats/users_page.dart`). `security_log.dart`, `security_logger.dart` and `app_log.dart` keep their own prints, which are already inside an `assert` or behind a verbose flag.

## Tasks
- [x] DLH-1: Add a debug-only log entry point.
- [x] DLH-2: Migrate the 45 call sites to it.
- [x] DLH-3: Replace every logged email address with the internal user id.
- [x] DLH-4: Verify with the full suite and the analyzer, then commit.

## Acceptance
No `print` outside a debug-only helper remains in `lib/`. No log statement interpolates an email address. Messages keep their previous text, tags and other interpolated fields except for the identifier swap. Startup configuration warnings still appear while developing.

## Evidence
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **75 infos**, down from 115. The 40 fewer are the `avoid_print` reports for the migrated call sites, minus one `dangling_library_doc_comments` that the migration introduced and this unit then fixed.
- `flutter test --no-pub --no-test-assets` -> exit 0, **276 passed**.
- `grep -rn "print(" lib/` -> only `core/utils/app_log.dart`, `core/utils/security_log.dart` and `core/security/security_logger.dart`, each inside `assert` or behind a flag.
- `grep -rnE "AppLog\.debug\(.*email" lib/` -> no matches.

## Not verified here
- The release guarantee is structural: asserts are removed in release, so `AppLog.debug` emits nothing there. It is not verified by running a release binary.
- No behavioural test asserts "nothing is printed"; the analyzer's `avoid_print` rule plus the source greps are the guards.
- `SecurityLog` and `SecurityLogger` remain two separate security loggers. Consolidating them is a follow-up, not part of this unit.

## Next step
Remaining hardening candidate from the original scan: the `!` lookups on label maps that will crash as soon as an enum value is added (`itinerary_page.dart:178`, `place_card.dart:77`). After that, the website.
