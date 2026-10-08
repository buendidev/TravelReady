# Tracked build inputs

Feature document. Owner-authorized work; every task closes with one work-unit
commit on `chore/tracked-build-inputs`.

## Why

Publishing the repository exposed a defect that predates the publication and
that no local run could catch: **`main` cannot be analyzed or built from a
clean clone, so CI has never been green on the remote.** `flutter analyze
--no-fatal-infos --no-fatal-warnings` exits 0 on the developer's machine and
exits 1 in CI, with the same command and the same commit:

```
error • Target of URI doesn't exist: 'firebase_options.dart' • lib/main.dart:10:8 • uri_does_not_exist
error • Undefined name 'DefaultFirebaseOptions' • lib/main.dart:40:14 • undefined_identifier
```

Local run: 75 issues, 0 errors. CI run: 80 issues, 2 errors + 3 warnings. Every
single difference is a file that exists on disk and is **not in version
control**: `lib/firebase_options.dart` accounts for the two errors, and the
declared but absent `assets/images/`, `assets/animations/` and `.env` account
for the three warnings.

Verified as pre-existing, not a regression: `git cat-file -e f0abacf5:<path>`
against the old pre-rewrite tip (kept locally as `refs/heads/legacy-backup`)
returns "missing" for every one of the files below. The old repository tracked
none of them, so this is not something the history rewrite lost.

## In scope

| Unit | Deliverable |
| --- | --- |
| TBI-1 | The Firebase config required to compile is tracked: `lib/firebase_options.dart`, `android/app/google-services.json` |
| TBI-2 | The Gradle wrapper is tracked: `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar` |
| TBI-3 | The Firebase deploy config and the security rules are tracked: `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` |
| TBI-4 | A gate that stops this class of bug from coming back, with its own tests, wired into CI |

## Out of scope (non-goals)

- **No rule is fixed here.** TBI-3 versions `firestore.rules` as it is today;
  the two findings it contains (below) are their own work unit with their own
  review, because changing access rules changes runtime behaviour.
- No secret is versioned. `android/key.properties`, `*.keystore`, `*.jks`,
  `.env*` and `android/local.properties` stay ignored, and the .gitignore
  change is written to keep them that way.
- No `.env`-as-a-Flutter-asset redesign, and no new asset directories. The
  three asset warnings are recorded, not fixed.
- `AGENTS.md` and the other AI-config entries stay ignored: that is a
  documentation decision, not a buildability one.
- No application code is touched.

## Constraints that are not negotiable

1. `.gitignore` must keep ignoring every real secret. A file that must be
   tracked is removed from the ignore list; nothing is force-added while a
   rule that also covers a secret is weakened.
2. `python3 tool/check_landing.py` stays green at every commit.
3. The wrapper jar must match the distribution declared in
   `android/gradle/wrapper/gradle-wrapper.properties`; a mismatched jar is a
   worse defect than a missing one.
4. Every claim in this document is a command that was run, never a memory of
   one.

## The two security findings this feature records and does not fix

Read while deciding whether the rules are config or code — they are code.

1. **Any authenticated user can read and list every user document.**
   `match /users/{userId}` grants `allow get: if isAuth()` and
   `allow list: if isAuth()`, and widens creation with
   `allow create: if isOwner(userId) || isAuth()`, where the `|| isAuth()`
   makes the ownership check decorative. The in-file comment says the widening
   was to let a user create their own document at registration; ownership
   alone already permits that.
2. **Any chat member can rewrite the chat document.** `allow update: if
   isMember(resource.data)` does not restrict which fields change, so a member
   can add an arbitrary uid to `memberIds` and read the conversation from then
   on.

Neither is caused or worsened by versioning the files: both already exist in
the deployed project's security model, and an attacker learns a rule set by
probing it, not by reading the repository.

## Tasks

### TBI-1 — Firebase config required to compile

- Remove `google-services.json`, `GoogleService-Info.plist` and
  `firebase_options.dart` from the two ignore blocks that carry them.
- Track `lib/firebase_options.dart` and `android/app/google-services.json`.

Evidence: a real clone of the branch, `flutter analyze
--no-fatal-infos --no-fatal-warnings` → 0 errors.

### TBI-2 — Gradle wrapper

- Remove `**/android/**/gradle-wrapper.jar`, `**/android/gradlew` and
  `**/android/gradlew.bat` from the Android block.
- Track those three files.

Evidence: in the clone, `android/gradlew --version` resolves the distribution
declared in `gradle-wrapper.properties`.

### TBI-3 — Deploy config and security rules

- Remove `firebase.json`, `firestore.rules`, `firestore.indexes.json` and
  `storage.rules` from the Firebase block.
- Track those four files.

Evidence: `git ls-files` lists them; the two findings above are recorded in the
feature log and in the PR body, unfixed on purpose.

### TBI-4 — The gate

- `tool/check_tracked_inputs.py`: assert that a declared list of required
  build inputs is tracked by git, and that a declared list of secrets stays
  ignored. Degrade to an `aviso:` outside a work tree, like the landing
  checker does.
- `tool/check_tracked_inputs_test.py`: `unittest`, one case per rule, with
  fixture trees in temporary directories — RED observed before GREEN.
- CI step in `.github/workflows/ci.yml`.

Evidence: the gate run against the pre-fix tree with the real missing files
(RED, recorded verbatim), then against the fixed tree (GREEN); its own suite
green; the real tree green.

## Log

- Opened after the owner chose to version everything missing rather than only
  the file that turns CI green.

- **TBI-1** — `.gitignore` and `android/.gitignore` corrected. Both nested rules
  that also covered the wrapper were found and fixed, not just the root one.
  After the edit, `git check-ignore` reports none of the ten required paths and
  still reports every secret: `.env`, `android/key.properties`,
  `android/local.properties`, `android/app/travelready-release.keystore`,
  `build/`, `.dart_tool/`. Commits `a878bde` (the ignore rules and the two
  Firebase config files).

- **TBI-2** — the wrapper is tracked, and it was run rather than trusted: from
  `android/`, `./gradlew --version` prints `Gradle 8.14` with revision
  `34c560e3be961658a6fbcd7170ec2443a228b109` and exits 0, resolving the
  `gradle-8.14-all.zip` that `gradle-wrapper.properties` already declared.
  `git update-index --chmod=+x` was needed: staged as `100644` the shell script
  would not be executable in a clone, which is a tracked-but-broken outcome.
  Commit `9abb1ba`.

- **TBI-3** — `firebase.json`, `firestore.rules`, `firestore.indexes.json` and
  `storage.rules` are tracked. The two security findings are recorded in the
  commit message and in this document, unfixed on purpose. Commit `95b2776`.

- Checked before writing anything: every other build input was already tracked
  (`pubspec.yaml`, `pubspec.lock` — which CI's `--enforce-lockfile` requires —,
  `gradle-wrapper.properties`, the three Gradle build scripts, `MainActivity.kt`
  and `analysis_options.yaml`). The nine files above were the whole gap.

- **Independent clean-clone verification** (delegated, not self-reported; a real
  `git clone --branch chore/tracked-build-inputs` into a temporary directory,
  `git status --porcelain` empty, source repository untouched):
  - `flutter pub get --enforce-lockfile` → exit 0, `Got dependencies!`.
  - `flutter analyze --no-fatal-infos --no-fatal-warnings` → exit 0, `78 issues
    found`. **Zero errors**, and specifically zero matches for `error` and no
    occurrence of `main.dart` anywhere in the output: both
    `uri_does_not_exist` and `undefined_identifier` are gone.
  - The 78-versus-75 difference against the developer's machine is exactly the
    three asset warnings below — which, as CI then proved, are **not** warnings
    in practice.
  - `./gradlew --version` in the clone → exit 0, `Gradle 8.14` really printed,
    and the file mode after cloning is `-rwxr-xr-x`: the executable bit
    survived, which is the half of TBI-2 that a mode-blind check would miss.
  - `git check-ignore -v` still reports `.env`, `android/key.properties`,
    `android/local.properties` and `android/app/travelready-release.keystore`
    as ignored, from the rules it names; `git ls-files` lists all nine required
    inputs.

- **Recorded follow-up this verification exposed, wrongly called benign at the
  time, and promoted to its own work unit by CI**: `pubspec.yaml` declares
  `assets/images/`, `assets/animations/` and `.env`, and none of the three exists
  in a clone. The analyzer reports them as warnings, but `flutter test` builds an
  asset bundle and **fails**: `unable to find directory entry in pubspec.yaml`
  twice, then `No file or variants found for asset: .env.` and `Failed to build
  asset bundle`. An earlier claim in this document that they do not fail CI was
  wrong and is corrected here.

  `assets/images/` and `assets/animations/` are empty directories on the
  developer's machine, which git cannot track, so the fix is a placeholder file.
  `.env` is the harder half and the reason this is its own unit: it holds real
  `OPENWEATHER_API_KEY` and `GOOGLE_MAPS_API_KEY` values, it is loaded through
  `dotenv.load(fileName: '.env')` in `lib/main.dart`, and declaring it as an asset
  ships those values inside the app bundle. Stopping that means compile-time
  `--dart-define`, or generating the file in CI from repository secrets — an
  application change with runtime consequences, not a buildability patch.

- **Review scope, decided and recorded because it was not obvious.** The
  receipt-driven-development reminder fired twice during this branch, offering
  `review.start` on a `current-changes`/`workspace` projection each time. Both
  inspections returned `paths: ["odd/tasks/tracked-build-inputs.md"]` with the
  same `paths_digest` and a `base_tree` equal to `HEAD^{tree}` (`4599a6aa`):
  the candidate was this documentation file, uncommitted, with a changed
  content digest because the log entry was being written. The branch's four
  commits never appear in that projection, because it is the working tree
  against `HEAD`. START was therefore **not** invoked, twice, with the entry
  rule's own words as the reason — a trivial passive documentation-only edit is
  an explicit ground for omission — and because the candidate is neither a
  work-unit commit nor a PR slice. No lineage was created and no authority was
  consumed. The review is deferred to the committed range
  (`42b113e..HEAD`, `committedOnly`), which is where this branch's actual work
  lives: the ignore-rule correction, the nine tracked inputs and the gate.

- **TBI-4** — `tool/check_tracked_inputs.py` and its 12-test suite are in, with the
  CI steps in `.github/workflows/ci.yml`. The rules live as data (`REQUIRED_TRACKED`
  nine paths, `REQUIRED_IGNORED` four secrets) and git is asked exactly twice per
  run: one `git ls-files -z`, then one `git check-ignore -z --no-index --stdin`
  carrying all thirteen candidates at once. Outside a work tree it degrades to
  `aviso:` and exit 0, like the landing checker.

- **The gate's RED was re-derived by hand, because the writer's own "RED" was not
  behavioural.** Its recorded RED was `ModuleNotFoundError: No module named
  'check_tracked_inputs'`, which proves the module did not exist, not that a rule
  fails. The real RED came from building a throwaway git repository out of
  `git archive main` — the pre-fix tree — and committing it with `git add -A`,
  which respects the old rules and therefore leaves all nine inputs untracked,
  exactly as this repository was. The gate reported **18 violations and exit 1**,
  naming each of the nine paths twice: once as untracked and once as
  ignore-matched. The mirror rule was exercised the same way: after a deliberate
  `git add -f .env`, the gate reported `.env: es un secreto y esta rastreado por
  git` and exited 1.

- **Two details worth not rediscovering.** `git check-ignore --stdin` refuses
  pathspec arguments (`fatal: cannot specify pathnames with --stdin`), so the
  candidates must go in on stdin; and without `--no-index` it consults the index
  and skips tracked files, which would make the "a rule still covers this tracked
  file" half of the rule undetectable.

- **Incident worth recording**: `tool/check_landing_test.py` does **not** exist on
  this branch — it belongs to `feat/website-professional` — so the writer took its
  style reference from a leftover native-review candidate view under
  `.git/gentle-ai/candidate-views/003123ba-…/`, which holds that branch's reviewed
  files. The reference file was the right one, but a stale review scratch directory
  silently served as a source, and nothing in this branch declared it. That
  directory tree is 3.1 MB of leftovers and is safe to delete; grepping it for the
  academic markers returns no text hit, so nothing academic survives there.

- **CI interaction with the open website PR**: both branches edit
  `.github/workflows/ci.yml`, and both need a `unittest discover -s tool` step.
  This branch appends both of its steps at the end of the file precisely so the
  hunks do not overlap, but whichever of the two merges second must keep **one**
  discover step, not two. Order matters for another reason: PR #1
  (`feat/website-professional`) cannot go green until this branch lands on `main`,
  because its `Analyze` step fails for exactly the missing file this branch tracks.
