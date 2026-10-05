# Production readiness commit reconciliation

## Objective
Protect the verified but uncommitted PRF-1 and PRF-2 work in the main checkout (`feat/sqlite-trip-packing-integrity`) with reviewable work-unit commits, so the production-readiness documentation, CI workflow, release-configuration validator, dependency lockfile and SQLite schema hardening cannot be lost by a single destructive command. No push, no pull request, no merge, no external account or provider action.

## Authorization
The user directed this session to continue with the next step after the discovery worktree was protected, and explicitly authorized committing this checkout's work units.

## Deliberately excluded paths (preserved, not committed)
These are unrelated to PRF and were left untouched in the worktree:
- `HANDOFF_TO_AGENT.md`, `WINDSURF_DEVIN_HANDOFF.md`, `WINDSURF_DEVIN_HANDOFF_BATCH_2.md`
- `config/nvidia_heavy_duty.yaml`, `config/openai_quality_moderated.yaml`
- `NUL` — a 51-byte Windows shell artifact from a mistaken `> NUL` redirect, not repository content. Reported to the owner; not committed and not deleted, because deleting a file is an irreversible action the owner should authorize.

Ignored local files used by tooling (`.env`, `lib/firebase_options.dart`, `android/app/google-services.json`) were never staged.

## Tooling incident
The shared `pre-commit` hook runs `gga run`, which is correctly configured in this checkout (`AGENTS.md` plus `.gga`, provider `claude`) but cannot execute: `Provider execution failed (exit code: 1)` → `Not logged in · Please run /login`. Any commit staging a non-test `.dart` file was therefore blocked. The user explicitly authorized `--no-verify` for these commits after being shown the failure; nothing about the GGA configuration was modified.

The same hook had already blocked the sibling discovery worktree for a different reason (missing `AGENTS.md`/`.gga`), and was authorized there in the same way.

## Local data safety
The trips and migration fixtures in this checkout still use the default cwd-relative FFI database rather than an owned temporary directory (that isolation exists only in the discovery worktree, commit `e0f1463`). `.dart_tool/sqflite_common_ffi` was copied aside before the first suite run and restored after the last one, so verification could not destroy local test data.

## Tasks
- [x] PC-1: Recorded the pre-commit verified state (178 tests, analyzer 119 infos / 0 warnings / 0 errors) with the FFI database directory backed up.
- [x] PC-2: Committed the PRF-1 baseline documents as one work unit.
- [x] PC-3: Committed the PRF-2 client-configuration boundary, release validator and CI workflow as one work unit.
- [x] PC-4: Committed the tracked dependency lockfile and its `.gitignore` change as one work unit.
- [x] PC-5: Committed the SQLite schema hardening, its regressions and the new test fixture as one work unit.
- [x] PC-6: Committed the rewritten `SECURITY.md` and `DB_SETUP.md` as one documentation work unit.
- [x] PC-7: Recorded the commit map, re-verified the committed tree and restored the backed-up database directory.

## Commit map
Branch `feat/sqlite-trip-packing-integrity` (base `8871476 fix(accessibility): label trip actions`), six commits:

| # | Commit | Unit |
| --- | --- | --- |
| 1 | `35da5c2` | `docs(production): add the PRF-1 architecture, threat and legal baselines` |
| 2 | `e8c034b` | `ci(release): enforce client-config and release validation checks` |
| 3 | `8378553` | `build: track pubspec.lock for reproducible dependency resolution` |
| 4 | `7248691` | `fix(db): stop seeding demo users and trips into fresh databases` |
| 5 | `1e03400` | `docs(security): state verified status instead of aspirational claims` |
| 6 | `docs(odd)`: this record and the PRF commit map | ODD evidence for the units above |

## Verification
- Content preservation: all 25 paths in the pre-commit manifest were hashed with `git hash-object` before any staging. After the commits, every path that HEAD now carries matched its recorded hash exactly, with **zero mismatches**. The only paths that differ from the manifest are the two ODD records in this final commit, which were edited after the manifest was taken, and the `config/*.yaml` files that are deliberately left uncommitted.
- Pre-commit: `flutter test --no-pub --no-test-assets` -> exit 0, **178 tests passed**. `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **119 infos**, zero warnings, zero errors.
- Post-commit on the committed tree: `flutter test --no-pub --no-test-assets` -> exit 0, **178 tests passed**; `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, **119 infos**, zero warnings, zero errors. Identical to the pre-commit state.
- The default FFI database directory was restored from the backup after the last run, returning it to its pre-verification state.
- Dependency direction was checked before slicing: the release-config validator tests depend only on the validator, and the schema-hardening commit carries both the `createSchema` extraction and the test fixture that replaces the removed seeded rows, so no intermediate commit references a later one.
- `git status --short` afterwards still lists only the deliberately excluded paths (`HANDOFF_TO_AGENT.md`, `WINDSURF_DEVIN_HANDOFF*.md`, `config/`, `NUL`) and ignored files.

## Limitations (recorded, not hidden)
- **The GGA pre-commit review did not run** for these commits; `--no-verify` was used under explicit user authorization because the provider is not authenticated in this environment.
- **No intermediate commit was executed individually.** The pre-commit and post-commit trees were run as a full suite; single-unit commits are index-only slices of the same verified bytes.
- **PRF-2 is still open.** Deployed Firebase rules, indexes and region, App Check, provider restrictions, server-side secret management, CI provider settings, release signing, the emulator suite and historical/binary secret scanning remain external and unverified. Nothing here proves an external configuration.
- **No native review was started.** RDD reports `on (decided by global)`; the review remains the owner's decision.
