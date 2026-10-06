# App: modals must cover the whole shell

## Objective
An open modal must block the entire shell, including the bottom navigation
bar, and that property must be enforced by a test instead of by habit.

## Evidence
A read-only audit of every tap-swallowing surface in the app (task APP-1)
found that all eight `showModalBottomSheet` call sites omit
`useRootNavigator`, whose default is `false`. Each sheet is therefore pushed
onto the **nearest** navigator, which under `StatefulShellRoute.indexedStack`
is the branch navigator. Its `Overlay` lives inside the shell body, while the
bar is drawn by the shell `Scaffold` as a separate `bottomNavigationBar`, so
the sheet's barrier covers the body and never the bar.

Two consequences, both real:

1. With a sheet open the user can still switch branches by tapping the bar.
2. Because the branch navigator survives a tab switch, the sheet route stays
   in that branch and is still there on return.

This is also the only mechanism in the app that can leave a branch body
untappable while the bar keeps working, which is the shape of the Home defect
the owner reported once and never reproduced. `showDialog` and the date and
time pickers are unaffected: their default is the root navigator, whose
barrier covers everything and would also have blocked the bar.

## Scope
The six page files that call `showModalBottomSheet`, plus test surfaces.
`lib/presentation/widgets/navigation/tr_bottom_nav.dart` is context, not a
target: the shell is already correct.

## Tasks
- [ ] APP2-1: A failing widget test that proves an open modal can be bypassed with the bottom bar.
- [ ] APP2-2: Make every sheet explicitly root-scoped at its call site.
- [ ] APP2-3: A guard test that fails if a future call site forgets the flag.
- [ ] APP2-4: Full suite and analyzer green, with the RED and GREEN outputs recorded.

## Acceptance
While a modal sheet is open, no interaction with the bottom bar changes the
branch. Every `showModalBottomSheet` call in `lib/` is explicitly
root-scoped, and a test fails if one is added without it. The existing suite
stays green and the analyzer adds no new findings.

## Limits, stated up front
This removes the only mechanism in the app that fits the reported symptom. It
is **not** proof that the reported Home freeze is fixed, because the incident
was never reproduced and, as the audit showed, the code as written could not
produce it persistently. Reproducing it needs the phone.

## Next step
A device pass with the audit's discriminating experiment: while the symptom
is live, press Android **Back** once and look at the scrim. If the body is
dimmed and the bar is not, the modal was branch-scoped; if the barrier covers
the bar too, it was a root dialog.
