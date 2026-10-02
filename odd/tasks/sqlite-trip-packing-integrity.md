# SQLite trip and packing integrity

## Objective
Harden the existing SQLite source of truth for trips and packing before adding new product surfaces. Preserve migration safety, relational integrity, and stream behavior without touching remote collaboration, auth, routing, or external-console integrations.

## Constraints
- `PackingItem.tripId` is mandatory.
- `PackingBloc` must not call `add()` from `_onItemAdded`; it performs an optimistic local update and lets the stream react.
- SQLite remains the source of truth for trips and packing; no Hive duplication.
- Preserve unrelated `.gga`, `HANDOFF_TO_AGENT.md`, and `config/` changes.
- This is Android-first local production hardening, not shared-trip synchronization or a schema redesign.

## Acceptance
- Existing v1-to-v2 weather-cache migration remains additive and existing trips/packing rows survive supported upgrades.
- Trip and packing CRUD preserve required relational identifiers and expected deletion behavior.
- Local watcher streams emit initial and post-write states predictably.
- Focused DB/datasource tests, full Flutter tests, and analyzer are run; pre-existing analyzer baseline is distinguished from feature-local issues.

## Tasks
- [x] STI-1: Map and encode existing SQLite trip/packing relational and stream contracts in focused regression tests. Route: delegated exploration and writer; multiple non-trivial test/data files. Evidence: a new SQLite FFI watcher test observed RED by timing out after one second waiting for the post-toggle snapshot; the missing notification was a real contract gap.
- [x] STI-2: Implement the smallest data-layer correction required by STI-1, keeping schema migrations additive and preserving PackingItem trip IDs. Route: delegated writer. Evidence: `toggleItemPacked` resolves the persisted item trip ID and notifies only that packing watcher after the write. Focused watcher test turned GREEN; database migration tests (4) and weather-cache tests (5) passed. Independent closure: full `flutter test` passed (147 tests); `flutter analyze` has no feature-local diagnostics but exits nonzero with 142 unrelated baseline warnings/infos; `git diff --check` has no whitespace errors. Commit: `3f35d62` (`fix(packing): notify watchers after item toggle`). Native review is unavailable for this candidate: a fresh `inspect` projects only pre-existing `.gga` and requires unrelated untracked-file selection. Independent verification is the record for this work unit.
- [ ] STI-3: Run independent full-suite/analyzer verification, record baseline distinctions, native review when the candidate can be projected, and commit each coherent work unit. Route: delegated verifier and parent commit. Check: `flutter test`, `flutter analyze`, `git diff --check`.

## Delivery
Branch: `feat/sqlite-trip-packing-integrity`, created from the completed weather-cache work on 2026-10-02. No push, PR, store release, credential change, or unrelated cleanup is included.
