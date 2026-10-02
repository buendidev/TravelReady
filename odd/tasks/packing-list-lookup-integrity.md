# Packing list lookup integrity

## Objective
Correct and cover the local repository contract for looking up a packing list by its ID. The lookup must not depend on an empty or caller-unknown trip ID.

## Evidence
`TripsRepositoryImpl.getListById` delegates through `getPackingLists('')`, which filters by `trip_id = ''` and cannot return ordinary lists. This is a local persistence/repository defect identified during the SQLite integrity mapping.

## Acceptance
- A persisted packing list is retrievable by ID through the repository regardless of its trip ID.
- Unknown IDs retain the established absence/failure behavior.
- The correction does not alter list creation, streams, schema, or remote paths.
- Focused tests, full suite, analyzer, and diff whitespace checks are recorded; baseline analyzer findings remain distinguished.

## Tasks
- [x] PLI-1: Add repository-level regression coverage that observes the current lookup failure and specifies successful/unknown-ID behavior. Route: delegated writer; test-first. Evidence: the repository test RED failed because `getPackingLists('')` could not find `list-001`; unknown IDs are specified to retain `ServerFailure` behavior.
- [x] PLI-2: Implement the smallest repository/datasource correction and verify focused behavior. Route: delegated writer. Evidence: datasource direct ID query plus repository delegation turned focused repository/datasource tests GREEN. Independent closure: full `flutter test` passed (149 tests); `flutter analyze` has no candidate diagnostics but exits nonzero with 142 unrelated baseline warnings/infos; `git diff --check` has no whitespace errors. Commit: `7def219` (`fix(packing): resolve lists by identifier`). Native review is unavailable for this candidate: fresh `inspect` projects only pre-existing `.gga` and requires unrelated untracked-file selection. Independent verification is the record for this work unit.
- [x] PLI-3: Independently verify and commit the work unit; attempt native review only when a candidate can be projected. Route: delegated verifier and parent commit. Evidence: 149 tests passed; analyzer has no candidate diagnostics and 142 unrelated baseline warnings/infos; `git diff --check` passed. Native inspection cannot project this candidate because of unrelated `.gga`/untracked worktree state; independent verification is recorded. Work-unit commit: `7def219`.

## Constraints
- SQLite remains the source of truth.
- Do not redesign schema, change PackingBloc, alter remote/auth/routing, dependencies, `.gga`, `HANDOFF_TO_AGENT.md`, or `config/`.
- Branch: `feat/sqlite-trip-packing-integrity`.
