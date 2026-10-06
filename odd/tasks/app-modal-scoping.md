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
- [x] APP2-1: A failing widget test that proves an open modal can be bypassed with the bottom bar.
- [x] APP2-2: Make every sheet explicitly root-scoped at its call site.
- [x] APP2-3: A guard test that fails if a future call site forgets the flag.
- [x] APP2-4: Full suite and analyzer green, with the RED and GREEN outputs recorded.

## Evidence (`7ba171a`)

The eight call sites were confirmed by grep before and after: discovery twice,
itinerary once, packing detail twice, packing lists once, profile once, trips
once. The diff adds `useRootNavigator: true` and a two-line comment at each, and
nothing else.

- **The RED was reproduced by the parent, not taken on trust.** All six page
files were reverted to the previous commit, the new widget test was run against
that code, and it failed with `an open modal sheet cannot be bypassed with the
bottom bar`; the fix was then reapplied and the test passed. A test that has not
been shown to fail against the broken code proves nothing.
- The widget test boots the real `buildAppRouter` with a mocked authenticated
`AuthBloc`, navigates to `/profile` inside the real shell, opens the profile edit
sheet through its real trigger, and then taps another branch on the bar,
asserting the location did not change. The tap is dispatched with
`warnIfMissed: false` because the root barrier absorbing it **is** the fixed
behaviour.
- The guard is a scanner over every `.dart` under `lib/`: it masks comments and
string literals (raw, triple-quoted and interpolation content), matches the call
by whole identifier, skips type arguments and walks the argument list by balanced
parens. Its robustness cases initially failed on the type-argument and
interpolation corners; both were fixed. It deliberately avoids
`package:analyzer`, which is only a transitive dependency and would have added an
dependency-lint finding.
- `flutter test --no-pub`: **432 passing**, up from 289. `flutter analyze
--no-pub --no-fatal-infos --no-fatal-warnings`: exit 0 with the baseline **75
infos**.
- Coverage limit, stated: only the profile sheet is exercised end to end. The
other seven call sites are identical in shape and are covered by the guard and by
review, not each by a bar-tap test.

## Acceptance met

With a modal sheet open, tapping the bottom bar leaves the app on the same
branch. Every `showModalBottomSheet` call under `lib/` is explicitly root-scoped,
and a test fails if one is added without it. The suite and the analyzer are at
their baseline or better.

## Limits, stated up front
This removes the only mechanism in the app that fits the reported symptom. It
is **not** proof that the reported Home freeze is fixed, because the incident
was never reproduced and, as the audit showed, the code as written could not
produce it persistently. Reproducing it needs the phone.

## Next step
A device pass with the audit's discriminating experiment: while the symptom
is live, press Android **Back** once and look at the scrim. If the body is
dimmed and the bar is not, the modal was branch-scoped; if the barrier covers
the bar too, it was a root dialog. This needs the phone connected; nothing in
this unit substitutes for it.
