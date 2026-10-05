# Home runtime stability

## Goal
Eliminate the device-reproduced Home crash when authenticated trip data is backed by `TripModel` instances.

## Scope
- `lib/presentation/pages/home/home_page.dart`
- `test/presentation/pages/home/home_page_accessibility_test.dart`

## Root cause
The upcoming-trip reduction receives a runtime `List<TripModel>` but the callback is typed as `(Trip, Trip) => Trip`, causing a Flutter error screen after trip data loads.

## Tasks
- [x] Add a regression test using `TripModel` instances; the device-only generic callback failure could not be reproduced in widget-test runtime.
- [x] Normalize the Home trip collection to the base entity type before filtering/reducing; preserve active/next selection and navigation.
- [x] Run focused/full tests, analyzer, diff check, and a connected-device smoke retest.

## Constraints
- No backend, database, Firebase, dependency, environment, or global UI restyle changes.
- Do not format unrelated code, stage, commit, or touch other worktrees.

## Evidence
- Device screenshot captured the runtime type error on authenticated Home with trip data.
- Independent verification: Home normalizes with `List<Trip>.from` before filtering/reducing; focused Home tests passed 5, full suite passed 201, and diff-check passed. Analyzer has only 117 existing info diagnostics.
- Device smoke: installed a fresh debug APK over USB, authenticated with existing session, reproduced Home with a stored upcoming trip, and observed the normal rendered Home screen with no Flutter exception in logcat.
- Added `TripModel` upcoming-trip regression coverage: it selects the earliest trip and navigates to its detail.
- RED attempt: the focused widget test passed before the normalization on this host, so the device-only generic callback failure was not reproduced in the widget-test runtime.
- GREEN: focused test and full `flutter test` passed after normalization.
- `flutter analyze` reported 117 pre-existing info-level issues and exited 1; none are in the allowed Home files.
- Manual device smoke remains pending because device operations are out of scope: authenticate with stored `TripModel` records containing two future trips, open Home, confirm the earliest upcoming trip is shown, tap its preparation action, and confirm its detail route opens without a Flutter error.
