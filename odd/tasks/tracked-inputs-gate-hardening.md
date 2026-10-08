# Tracked-inputs gate hardening

Branch: `fix/tracked-inputs-gate-hardening` (off `main` `08a353a`)

## Why

`tool/check_tracked_inputs.py` exists so that a clean clone cannot silently
lose a build input again. It is the only thing standing between this
repository and a second round of "`Analyze` fails on the remote and nowhere
else", and CI now runs it.

The native review of the candidate that introduced it (lineage
`review-7117cc28ee590a76`, four of four lenses, approved and acknowledged)
admitted seventeen findings. Six of them say the gate does not always do what
it claims, and the worst one says it fails **open**: every way `git ls-files`
can fail collapses into the same `return None` as "this is not a work tree",
which prints a `aviso:` line and exits 0. A degraded git in CI therefore
produces a green run that verified nothing.

## Findings in scope

| id | location | severity | what it says |
|----|----------|----------|--------------|
| `R4-1` | `tool/check_tracked_inputs.py:66-67` | WARNING | the gate fails open: every `git ls-files` failure maps to the same `None` as "not a work tree", so it exits 0 |
| `R3-cli-invalid-dir-exits-green` | `tool/check_tracked_inputs.py:124-136` | WARNING | a directory argument that is not a work tree also exits 0 |
| `R3-ok-verdict-on-skipped-check` | `tool/check_tracked_inputs.py:131-136` | SUGGESTION | after skipping, it still prints the `OK:` verdict it did not earn |
| `R3-subdir-invocation-false-violations` | `tool/check_tracked_inputs.py:64-66` | SUGGESTION | invoked from a subdirectory, `git ls-files -- .` answers in subdirectory-relative paths, so every required input looks missing |
| `R4-3` / `R3-check-ignore-oserror-unhandled` | `tool/check_tracked_inputs.py:74-79` | SUGGESTION | the `check-ignore` call catches `CalledProcessError` (exit 1 means "no match") but not `OSError` |
| `R2-004` | `tool/check_tracked_inputs.py:96-99` | SUGGESTION | the skip message asserts a cause it never checked |
| `R2-003` / `R3-test-fixture-precedence` | `tool/check_tracked_inputs_test.py:107-110` | SUGGESTION | `set(T) \| set(I) - {"x"}` parses as `set(T) \| (set(I) - {"x"})`, so the file is never removed and the "input absent" test silently duplicates the "present but untracked" one |
| `R2-001` / `R3-broken-repo-test-undercounts` | `tool/check_tracked_inputs_test.py:214-231` | WARNING / SUGGESTION | the comment claims three violations; the fixture produces six, and nothing pins the count |

## Decisions

- **D1 — one probe separates "no git" from "git failed".** A single
  `git rev-parse --show-toplevel` answers both questions at once: an `OSError`
  means git is not installed, a non-zero exit means the directory is not a work
  tree, and a returned path means git works. Only the first two degrade to a
  skip; after the probe succeeds, any failing git command is a **failure**.
- **D2 — a skip must be visible.** When nothing was verified, the gate prints
  no `OK:` verdict. Exit 0 is kept (a developer without git must not be
  blocked), but the output can no longer claim a check that did not run.
- **D3 — an explicitly named directory that cannot be checked is a failure.**
  The default `.` keeps the polite degrade, parity with `check_landing.py`; a
  path the operator typed is a claim about what to check, and a typo must not
  pass.
- **D4 — all git work happens at the resolved work-tree root.** The probe
  returns the root, and every later git call runs there with root-relative
  paths, so `cd website && python ../tool/check_tracked_inputs.py` checks
  exactly what the root invocation checks.
- **D5 — the tests must state true things.** The precedence bug gets
  parentheses, and the broken-repo test pins the exact number of violation
  lines instead of three `assertIn`s.

## Work units

- **W1 — the probe, and a hard failure after it.** RED: a repository whose
  index is corrupt makes `git ls-files` fail while `git rev-parse
  --show-toplevel` still answers, and today that exits 0 with a `aviso:`.
- **W2 — subdirectory invocation.** RED: `check_directory()` called with the
  repository root while `cwd` is a subdirectory reports required inputs as
  untracked.
- **W3 — the CLI contract.** RED: `main()` with an explicit directory that is
  not a work tree exits 1; `main()` that skipped prints no `OK:`.
- **W4 — test truth.** RED: the precedence fixture keeps `lib/firebase_options.dart`
  on disk; the broken-repo test's real violation count is six, not three.

## Verification

- Each work unit records its RED output before the change and its GREEN output
  after, in the evidence table below.
- `python -m unittest discover -s tool -p "*_test.py"` — the single CI step,
  95 tests before this branch.
- Real reproduction of the fail-open defect, not only a mock: corrupt
  `.git/index` in a throwaway clone of the fixture and run the gate.

## Out of scope

- The `firestore.rules` findings (`R1-001`, `R1-002`, `R2-002`,
  `R3-rules-recorded-unfixed`, `R4-2`) — separate unit, separate branch.
- `R1-003` (`lib/firebase_options.dart:44`, SUGGESTION).

## Evidence

_(filled in as work units close)_

- Baseline (before any change):
  `python -m unittest discover -s tool -p "*_test.py"` → `Ran 95 tests in 22.230s` / `OK`.
- **W1** — RED: suite `Ran 99 tests`, `FAILED (failures=4, errors=1)`;
  `test_corrupt_index_is_a_hard_failure_not_a_skip` → `AssertionError: 0 != 1 :
  ['aviso: ... tmp5z2golpk no es un arbol de trabajo de git']`; mock variants
  (`ls-files` CalledProcessError, `check-ignore` OSError) failed the same way or
  errored with the raw `OSError: sin espacio en disco`; R2-004 assertion
  `AssertionError: 'git no esta disponible' not found in 'aviso: ... no es un
  arbol de trabajo de git'`. GREEN: same command → `Ran 99 tests ... OK`.
- **W1 corrupted-index reproduction** (throwaway repo, valid fixture, then
  `.git/index` := `b"not an index"`): before the fix, `git rev-parse
  --show-toplevel` → exit 0 with the root, `git ls-files` → exit 128
  `fatal: .git/index: index file smaller than expected`, and the gate printed
  `aviso: ... no es un arbol de trabajo de git` plus `OK: entradas de
  construccion rastreadas y secretos ignorados.` and returned 0 (fail-open
  proven). After the fix, same repo: rev-parse exit 0, ls-files exit 128, gate
  returns 1 with `git se rompio durante la comprobacion: git ls-files fallo en
  ... returned non-zero exit status 128.` and `FALLO: 1 violacion(es) de
  entradas de git.`
- **W2** — RED: suite `Ran 101 tests`, `FAILED (failures=2)`. GREEN:
  `Ran 101 tests ... OK` after resolving the work-tree root and running both
  git calls there (`cwd=root`, no `-- .` pathspec).
- **W3** — RED: suite `Ran 103 tests`, `FAILED (failures=3)`;
  `test_default_directory_degrades_to_aviso_without_ok` → `'OK:' unexpectedly
  found in ...`; both explicit-directory tests → `AssertionError: 0 != 1`.
  GREEN: `Ran 103 tests ... OK`.
- **W4** — RED (truthful assertions added, old fixtures kept): suite
  `Ran 103 tests`, `FAILED (failures=2)`; broken-repo test →
  `AssertionError: 6 != 3` listing all six violation lines; fixture test →
  `AssertionError: True is not false : el fixture no quito la entrada:
  precedencia de | y -`. GREEN: `Ran 103 tests ... OK` after parenthesizing the
  fixture and rebuilding the broken-repo fixture to exactly three violations
  (`FALLO: 3 violacion(es)` pinned).
- Final: `python -m unittest discover -s tool -p "*_test.py"` →
  `Ran 103 tests in 33.646s` / `OK`. Both tool files verified ASCII-only.
- `git diff --stat`: `tool/check_tracked_inputs.py | 109 +++++++++++++++++++++++-----`,
  `tool/check_tracked_inputs_test.py | 153 +++++++++++++++++++++++++++++++++++---`,
  2 files changed, 234 insertions(+), 28 deletions(-). Nothing committed.
- All eight findings fixed; none deferred.

### Post-verification refinements

An independent read-only verification (temp directories only, no repository
mutation) exercised every claim above and held all eight. It also flagged two
cosmetic issues of the same class this branch fixes — a verdict asserting
something it had not checked:

- The CLI reported an explicitly named **nonexistent** directory as
  `FALLO: 1 violacion(es) de entradas de git.`, mislabelling a directory that
  could not be checked as a rule violation. RED: `assertNotIn("violacion(es)",
  output)` added to `test_explicit_missing_directory_exits_one` →
  `Ran 103 tests`, `FAILED (failures=1)`, `AssertionError: 'violacion(es)'
  unexpectedly found in '  - no se pudo comprobar el directorio ... \n
  FALLO: 1 violacion(es) de entradas de git.\n'`. GREEN: `Ran 103 tests ... OK`,
  and the real CLI prints `FALLO: no se pudo comprobar el directorio
  <path>.` for a path that does not exist.
- `_raiz_de_trabajo` reported **any** `OSError` as "git no esta disponible en
  esta maquina". Only `FileNotFoundError` degrades now; every other `OSError`
  is `GitRoto`, because a permissions failure is git breaking, not git absent.

### Independent verification

Delegated read-only verification of the eight claims, all **HELD**:

- `python -m unittest discover -s tool -p "*_test.py"` → `Ran 103 tests ... OK`.
- Corrupted-index reproduction reproduced from scratch: `git rev-parse
  --show-toplevel` exit 0 with the root, `git ls-files` exit 128, and the gate
  now exits 1 with `git se rompio durante la comprobacion`, no `aviso:`, no
  green run.
- A real subprocess invocation from a repository subdirectory exits 0 with the
  `OK:` verdict, and exits 1 with one message when a required input is removed
  from the index — the negative direction, not only the happy path.
- An explicit directory that is not a work tree exits 1; a path that does not
  exist exits 1; the no-argument invocation in the same non-work-tree directory
  still exits 0 with exactly one `aviso:` line.
- A skip prints no `OK:` verdict anywhere in its output.
- The parenthesized fixture really removes `lib/firebase_options.dart` from
  disk, and the unparenthesized form would have kept it; the broken-repo
  fixture yields exactly three violations, four if one more secret loses
  coverage and two if `.env` gains it, so the pinned count is load-bearing.
- Only the two tool files changed; no extra dependency; both files ASCII-only.

### Commit

`781b565` — `fix(tool): stop the tracked-inputs gate from failing open`
(103 tests, all green).
