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
- [ ] OFF-1: A provisional restore at a short, injectable deadline, keeping the listener subscribed.
- [ ] OFF-2: A verified emission replaces the provisional state; a null emission still signs out and clears the snapshot.
- [ ] OFF-3: Nothing is restored when the verified answer arrives first.
- [ ] OFF-4: Tests for each behaviour above, with the RED observed before the change.

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

## Next step
Re-measure on the device: force-stop, airplane mode, and time how long it takes to
reach Home. The claim to beat is roughly 40 seconds.
