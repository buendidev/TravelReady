# SQLite test isolation

## Objective
Unblock safe full-suite verification without deleting or opening the default SQLite FFI database. Production database behavior is out of scope.

## Evidence and rationale
Two trips test fixtures delete the same cwd-relative .dart_tool/sqflite_common_ffi/databases/travelready.db and do not restore the global factory. Migration tests use relative build paths that FFI rebases under its database directory and do not guarantee cleanup. Separate test isolates do not isolate filesystem paths.

## Scope
Selected discovery worktree only. Allowed authored surfaces:
- test/support/database_isolation.dart
- test/support/database_isolation_test.dart
- test/core/database/database_helper_test.dart
- test/data/datasources/local/trips_local_datasource_test.dart
- test/data/repositories/trips_repository_impl_test.dart
Preserve all unrelated dirty changes. No production edits, dependency changes, secret reads, network, accounts, staging, commits or publishing. Commit authorization absent. Existing sibling worktrees remain untouched.

## Tasks
- [x] DBI-1: Implemented owned temporary-directory fixture, six lifecycle regressions and isolated trips/migration fixtures; 13 focused tests passed.
- [x] DBI-2: Independent verification passed: 13 focused tests, all 220 suite tests, analyzer exit 0 with 116 infos and zero warnings/errors.

## Acceptance
Each fixture uses an absolute uniquely owned temporary directory, preferably a fresh FFI factory with a local database path. Close singleton handles before restoring the captured nullable global factory. Register cleanup immediately; dispose datasources, close handles, restore factory, and remove only owned temporary directories even on exceptions. Never open/delete/seed the default database, including sentinel checks. Migration test must retain its reopen/persistence assertions with absolute paths and failure-safe cleanup. Existing behavior assertions remain unchanged.

## Test-first and checks
Write fixture regressions first for owned database path, independent instances, factory restoration, directory cleanup and callback failure. Observe meaningful RED if possible without unsafe default access; missing helper compilation is setup evidence, not a behavioral RED. If no safe behavioral RED is available, report the exception and run structural plus focused functional checks. Run flutter test --no-pub --no-test-assets test/support/database_isolation_test.dart, then the three affected database test files. Full suite only after independent safety preflight. Ordinary Flutter caches and owned temporary test directories are permitted; no deletion outside captured owned directories.

## Progress
DBI-1 writer verification: safe Flutter command flags --no-pub --no-test-assets; isolation tests 6 passed, migration tests 4 passed, datasource tests 2 passed, repository test 1 passed. git diff --check passed. Tests authored first; no behavioral RED claimed because no safe helper existed and the unsafe default fixtures were not executed. Coverage includes independent marker data, nullable/existing factory restoration, callback/disposer failures, closed handles and removed directories. Initialization-failure cleanup is structurally implemented but not fault-injected. Fixture requires serial ownership within an isolate. Default database was not opened/deleted/seeded/inspected; production files untouched.

Post-writer ASSESS returned unassessable due to undeclared untracked paths; independent verification required. Native review still lacks an isolated candidate amid pre-existing changes; no approval claimed. Commits remain unauthorized.

## Next step
Independent verification completed using --no-pub --no-test-assets: four affected test files passed 13 tests; full suite passed 220 without exclusions, including 12 subscription regressions. Analyzer --no-pub --no-fatal-infos --no-fatal-warnings exited 0 with 116 infos, zero warnings/errors, no candidate-local diagnostics. No clean baseline run; count reduction is not attributed to this candidate. Tracked whitespace check exited 0; untracked no-index checks exited 1 for nonidentical files, no whitespace errors, LF-to-CRLF warnings only. Git status inventory unchanged before/after.

Safety preflight and structural review confirmed only owned temporary/in-memory databases, mocked services and in-memory environment configuration. Default database not accessed. Six fixture regressions exercise factory restoration, independent data, callback/disposer failures and cleanup. Initialization failure remains structurally reviewed, not injected; nested ownership unsupported; underlying I/O cleanup failures can still prevent successful removal despite guaranteed attempts.

Functional verification complete. Native approval and work-unit commits remain pending due to mixed pre-existing candidate scope and absent commit authorization. Continue bounded Home stability/UX exploration; do not claim billing or release readiness.
