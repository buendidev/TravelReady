# Offline session restore

## Objective
Open the app with no network and still reach the data that lives on the device, instead of being sent to a login screen that itself needs the network.

## Evidence
Reproduced on a vivo V2440 (Android 16): with airplane mode on and the app force-stopped, the startup waited 30 seconds on the splash and then rendered **Iniciar sesión**, even though the session was stored and the trips, packing lists and itinerary live in local SQLite. Logging in requires the network, so an offline user had no route back to their own data. This is the ordinary "flaky wifi at the airport" case, not an exotic one.

Cause, in `AuthBloc._onStarted`:

```dart
.timeout(const Duration(seconds: 30), onTimeout: (sink) {
  // Solo cerrar sesión por timeout si actualmente NO estamos autenticados
  if (state is! AuthAuthenticated) sink.add(null);
})
```

On a cold start the state is never `AuthAuthenticated` at that point, so the timeout emitted `null` and the router redirected to login. The same happened on any stream error. The session itself was never destroyed: with the network restored the app returned to Home as the same user.

## Decision
Option (a), chosen by the owner: restore the stored local session on timeout and re-verify when the network returns.

## Scope
`lib/data/datasources/local/session_snapshot_store.dart` (new), `lib/presentation/bloc/auth/auth_bloc.dart`, `test/presentation/bloc/auth_offline_session_test.dart` (new).

## Tasks
- [x] OSR-1: Capture the RED: a bloc test with a stream that never emits, a stored session and a short grace. It failed with `AuthUnauthenticated` — the device defect reproduced deterministically.
- [x] OSR-2: Keep a snapshot of the last confirmed user, rewritten on every authenticated emission and cleared when the session ends.
- [x] OSR-3: Restore the snapshot when the stream neither emits nor errors within the grace, keeping the subscription open so the verified session replaces it as soon as Firebase answers.
- [x] OSR-4: Verify with the focused tests, the full suite, the analyzer and the device.

## Acceptance
A cold start with no network reaches the app with the stored session; without a stored session it goes to unauthenticated exactly as before. A later real emission replaces the restored session and refreshes the snapshot; a null emission clears it; a stream error falls back to the snapshot instead of signing the user out. An unreadable snapshot is discarded rather than crashing the start.

## Evidence
- RED: `flutter test --no-pub --no-test-assets test/presentation/bloc/auth_offline_session_test.dart` -> exit 1, 3 passed / 4 failed, the first with `Expected: <Instance of 'AuthAuthenticated'> Actual: AuthUnauthenticated`.
- GREEN: same command -> exit 0, **7 passed** (restore on timeout, no snapshot means unauthenticated, a real emission replaces and refreshes, a null emission clears, a stream error falls back, plus the store round-trip and its tolerance to garbage).
- `flutter test --no-pub --no-test-assets` -> exit 0, **287 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **75 infos**, zero warnings, zero errors.
- Device, vivo V2440 (Android 16): the snapshot appears in `FlutterSharedPreferences.xml` as `flutter.auth_session_snapshot`; with airplane mode on and the app force-stopped, the app now opens on **Home** as the same user, **Mis maletas** renders, and the itinerary still lists the plan created earlier from the device, with **zero** `E/flutter` entries.

## Not verified here
- The restored session is the last confirmed one: offline, the subscription plan may be stale until the stream answers. No device test covers a plan change made on another device while this one was offline.
- The snapshot stores name, email, plan and photo URL unencrypted in SharedPreferences. That matches the existing local-data posture (the SQLite database is unencrypted) and is recorded here rather than changed.
- No test covers a snapshot written by an older app version with a different shape; `read()` treats any unreadable value as absent.

## Next step
Nothing outstanding for this unit. The remaining offline gap worth considering later is that a first-ever install has no snapshot, so its very first launch still needs a network.
