# Security logging safety

## Objective
Security logging and email redaction must never be able to break or block the operation they are recording.

## Evidence
Both helpers sit in the authentication path, so a crash there reaches the user:

| Site | Input | Observed failure |
| --- | --- | --- |
| `SecurityLog.sessionEvent` (`lib/core/utils/security_log.dart`) | a `userId` shorter than six characters, or empty | `RangeError (end): Invalid value: Not in inclusive range 0..2: 6` |
| `CryptoService.hashEmailForLog` (`lib/core/security/crypto_service.dart`) | an address with an empty local part, e.g. `@test.com` | `RangeError (index): Invalid value: Valid value range is empty: 0` |

`sessionEvent` builds the prefix as an argument expression, so the slice is evaluated before the debug-only `assert` inside `_log` and therefore also throws in release builds. `hashEmailForLog` is reached from `auth_local_datasource.dart:35`, which wraps the logging of login, register, logout and password reset.

## Scope
`lib/core/utils/security_log.dart`, `lib/core/security/crypto_service.dart`, `test/core/security/security_redaction_test.dart`.

Nothing about what is redacted changed: ordinary values keep their previous output byte for byte (`'pablo@test.com'` still maps to `'pa***lo@test.com'`, and a long id still logs its first six characters plus an ellipsis).

## Tasks
- [x] SLS-1: Capture the RED for both paths with a pure unit test.
- [x] SLS-2: Make the session prefix and the email masking safe for short or empty values.
- [x] SLS-3: Verify with the focused test, the full suite and the analyzer, then commit.

## Acceptance
A short or empty user id, and an empty or one-character email local part, must not throw. No change to the redaction shape for ordinary values.

## Evidence
- RED: `flutter test --no-pub --no-test-assets test/core/security/security_redaction_test.dart` -> exit 1, 2 passed / 2 failed, with the two RangeErrors quoted above.
- GREEN: same command -> exit 0, 4 passed.
- `flutter test --no-pub --no-test-assets` -> exit 0, **274 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **115 infos** (one fewer than before this unit), zero warnings, zero errors.

## Not verified here
- No end-to-end authentication run; the helpers are covered as pure functions.
- `SecurityLog._log` still writes through a debug-only `assert` and `print`. Replacing it with a real crash-reporting sink is production work for PRF-2/PRF-3, not for this unit.

## Next steps (remaining candidates from the same scan)
- `print` calls that emit raw error text in production paths: `firestore_chats_datasource.dart:257`, `users_page.dart:75` and `:84`.
- An unguarded `jsonDecode` and field casts when reading cached weather rows (`weather_cache_datasource.dart:85`).
- `!` assertions on label maps that will crash the moment an enum value is added: `itinerary_page.dart:178`, `place_card.dart:77`.
- `auth_local_datasource.dart:215` uses `results.first` after a lookup.
