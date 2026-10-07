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
