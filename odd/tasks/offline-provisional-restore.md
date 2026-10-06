# App: show the local session in seconds, verify it in the background

## Objective
With no network, a force-stopped app must reach the reader's own data in a few
seconds instead of waiting out the full Firebase grace, without ever presenting
an unverified session as if it were confirmed.

## Evidence
Measured on the device (vivo V2440, Android 16) during the 2026-10-06 pass:

- Warm, in airplane mode: Home renders from local data, and the weather card is
  honest about the age of its reading ("Stale data · 9 min ago").
- Cold, in airplane mode: the app was force-stopped and relaunched. The stored
  session **is** restored and the app does land on Home, but only after roughly
  **40 seconds** of splash, because `AuthBloc._onStarted` waits out the whole
  30 s `startupGrace` before restoring the snapshot.

So the restore works and is not protecting anything the snapshot does not already
cover; the cost is forty seconds of splash screen to reach data that is already
on the phone.

## Decision (owner, 2026-10-06)
Restore the stored session provisionally at a short deadline while the listener
stays subscribed, and let the verified answer replace it. The owner accepted the
consequence: for a few seconds a session that Firebase later revokes may be
visible.

## Scope
`lib/presentation/bloc/auth/auth_bloc.dart` and its tests. The snapshot store,
the router and the UI are context, not targets.

## Tasks
- [x] OFF-1: A provisional restore at a short, injectable deadline, keeping the listener subscribed.
- [x] OFF-2: A verified emission replaces the provisional state; a null emission still signs out and clears the snapshot.
- [x] OFF-3: Nothing is restored when the verified answer arrives first.
- [x] OFF-4: Tests for each behaviour above, with the RED observed before the change.

## Acceptance
With no emission and the provisional deadline elapsed, the state is authenticated
from the snapshot without waiting for the outer grace. A later verified user
replaces it, a later null signs out and clears the snapshot, and an answer that
arrives before the deadline means no provisional state is ever emitted. The
existing offline tests keep passing, the whole suite stays green and the analyzer
adds no findings.

## Limits
The provisional window is a deliberate trade, not a free win: it can show data
belonging to a session Firebase is about to revoke. It does not weaken the
verified path, which still wins whenever it answers.

## Evidence (`758e61d`)

`AuthBloc` gained `Duration provisionalGrace = const Duration(seconds: 5)`,
injectable like `startupGrace`, and a `_provisionalTimer` that calls
`_restoreProvisional()`: it reads the snapshot once, emits nothing when there is
none, and **re-checks the state after the await** so a verified answer that
arrives mid-read is never overwritten. Both timers are cancelled in the stream
listener and in `close()`.

- **Test-first, with the RED observed twice**: first a compile failure
(`No named parameter with the name 'provisionalGrace'`), then, with the parameter
added but inert, the key test failed with `AuthLoading` instead of
`AuthAuthenticated` while the two guard tests passed throughout.
- `flutter test --no-pub test/presentation/bloc/auth_offline_session_test.dart`: 12
passing. `flutter test --no-pub`: **437 passing**, up from 432. `flutter analyze`:
exit 0 with the baseline 75 infos.
- **Measured on the device**, airplane mode, force-stopped app: **13.9 s** and
**11.9 s** to Home in two runs, against at least 18 s (and at most 40) for the
previous build, whose lower bound the new numbers already beat. With network:
**9.0 s**.
- The log shows `[AuthBloc] Sesión guardada restaurada (provisional)` once per
offline start and **not at all** in the run with network, so the provisional path
is confirmed to run when it should and to stay out of the way when Firebase
answers first.
- The remaining ~12 s offline is five seconds of deliberate grace plus the cold
start of a debug build; a release measurement needs a keystore.

## Acceptance met

The stored session is shown at the provisional deadline without waiting for the
outer grace; a verified user replaces it; a verified null signs out and clears the
snapshot; an answer that arrives first means no provisional state is ever shown.
The snapshot store, the router and the UI are untouched, and no dependency was
added.

## Limits
The provisional window is a deliberate trade: it can present data belonging to a
session Firebase is about to revoke, and a network-bound action taken inside it
can fail with an auth error once the verified answer lands. It does not weaken the
verified path, which still wins whenever it answers.

## Next step
Nothing here is outstanding. A release-build measurement, and the same check on a
low-end device, remain out of reach until the owner provides a signing
configuration.
