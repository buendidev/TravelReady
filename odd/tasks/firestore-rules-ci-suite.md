# Firestore rules emulator suite in CI

Branch: `ci/firestore-rules-emulator-suite` (off `main` `d9ab81d`)

## Why

`docs/production/threat-model.md` says the deployed rules are "unverified" and
requires "emulator tests for anonymous, owner, other user, former member and
unauthorized field/query access" before those rules are treated as deployed. It
also notes there is no version-controlled emulator suite. Until now every rules
claim in this repository rested on someone running the emulator by hand in a
throwaway directory, which leaves nothing behind and catches nothing on the next
change.

`firestore.rules` is the only enforcement for who reads and writes whose data,
and a rule edit is a one-line change with no compile error and no visible
failure until someone is reading someone else's data. That is exactly the shape
of defect a machine has to check.

## What this unit adds

- A committed Node harness under `rules_test/` that loads `firestore.rules` in
  the Firestore emulator and asserts the allow/deny matrix, using Node's
  built-in test runner so the only runtime dependencies are
  `@firebase/rules-unit-testing` and a pinned `firebase-tools`.
- A pinned lockfile, because a floating `firebase-tools` is a CI failure that
  happens on someone else's pull request.
- An `emulators` block in `firebase.json` so local runs and CI use the same
  configuration.
- A CI job that runs the suite on every pull request and every push to `main`.
- A short `rules_test/README.md` so the next person can run it locally without
  reading the CI file.

## Decisions

- **D1 — the suite asserts the matrix, not a happy path.** Every case that
  matters is a pair: the action that must be allowed and the near-identical
  action that must be denied. A suite that only checks that the app still works
  cannot catch a rules hole.
- **D2 — `node --test` and no test framework.** Node 24 is what the runner
  provides; adding jest or mocha would add dependencies without adding
  evidence.
- **D3 — `firebase-tools` is a pinned devDependency, not `npx firebase-tools`
  at a floating version.** Reproducibility beats a smaller `node_modules`.
- **D4 — this unit does not change any rule.** It only makes the existing
  rules checkable. The rules changed in `fix/firestore-rules-hardening`.
- **D5 — the suite must be able to fail.** The evidence includes a mutation
  check: weaken the `memberIds` condition in a copy of the rules and show the
  suite failing, so the suite is proven to detect the hole rather than merely
  to pass.

## Cases the suite must cover

`users`: own-uid create allowed; another uid's create denied; anonymous create
denied; own update allowed; another user's update denied; reading another user's
document allowed and listing the directory allowed (documented transitional
exposure — the assertions say so, so that the friends feature has something to
flip).

`chats`: member `unreadBy` update allowed; adding a uid to `memberIds` denied;
shrinking `memberIds` denied; an unrelated field update with `memberIds`
unchanged allowed; non-member read and update denied; chat delete denied.

`messages`: member send with `senderId` equal to the caller allowed; send with
someone else's `senderId` denied; member read allowed; non-member read denied;
update and delete denied.

Removed paths: `trips`, `trips/*/packingLists/*` and
`trips/*/packingLists/*/packingItems/*` denied for an authenticated owner and
for anonymous, because no client reaches them and Firestore denies by default.

## Verification

- `node --test` green against the current rules, in the same way CI runs it.
- The mutation check from D5, with its exact failure output.
- `flutter analyze`/`flutter test` unaffected (nothing Dart changed); CI's
  existing `validate` job must stay green with the new job alongside it.

### Evidence (observed 2026-10-08, Node v24.14.1, npm 11.12.1, Java 23.0.2, firebase-tools 15.15.0, @firebase/rules-unit-testing 6.0.0)

1. Local run, committed default (repository's own `firestore.rules`):
   `cd rules_test && npx firebase emulators:exec --only firestore --project demo-travelready "npm test"`
   → `rules under test: C:\Users\buendidev\Documents\GitHub\TravelReady\firestore.rules`;
   `tests 33 · suites 4 · pass 33 · fail 0 · cancelled 0 · skipped 0 · todo 0`.
2. Mutation check (D5): copy of `firestore.rules` weakened at line 43 to
   `allow update: if isMember(resource.data);` (the `memberIds` immutability
   condition removed), run with
   `RULES_FILE=<temp copy> npx firebase emulators:exec --only firestore --project demo-travelready "npm test"`
   → exactly the two tests that protect `memberIds` fail, everything else
   passes: `tests 33 · pass 31 · fail 2`, with
   `✖ DENY: member u1 adds u3 to memberIds` —
   `Error: Expected request to fail, but it succeeded.` (firestore.rules.test.js:159)
   and `✖ DENY: member u1 shrinks memberIds to ["u1"]` (firestore.rules.test.js:167).
   Re-run against the real rules immediately after: 33/33 pass. The
   repository's `firestore.rules` was never modified (`git diff` empty for it
   throughout); the mutated copy lives only in the OS temp directory.
3. Full case list as `node --test` reports it (33 tests, 4 suites):
   - users: ALLOW u1 creates users/u1; DENY u2 creates users/u1 (uid
     squatting); DENY anonymous creates users/u1; ALLOW u1 updates users/u1;
     DENY u2 updates users/u1; DENY-expected-ALLOW (documented transitional
     exposure) u1 reads users/u2; DENY-expected-ALLOW (documented
     transitional exposure) u1 lists users.
   - chats (memberIds ["u1","u2"]): ALLOW member u1 updates unreadBy.u1;
     DENY member u1 adds u3 to memberIds; DENY member u1 shrinks memberIds
     to ["u1"]; ALLOW member u1 updates another field with memberIds
     unchanged; DENY non-member u3 reads the chat; DENY non-member u3
     updates the chat; DENY member u1 deletes the chat; DENY anonymous
     deletes the chat.
   - messages: ALLOW member u1 sends with senderId == caller; DENY member u1
     sends with someone else senderId; ALLOW member u2 reads a message;
     DENY non-member u3 reads a message; DENY member u1 updates a message;
     DENY member u1 deletes a message.
   - removed paths (default deny): for `trips/t1`,
     `trips/t1/packingLists/l1` and
     `trips/t1/packingLists/l1/packingItems/i1` — DENY authenticated u1 read,
     DENY authenticated u1 write, DENY anonymous read, DENY anonymous write
     (12 tests).
4. `git status --short` at handoff: `M .github/workflows/ci.yml`,
   `M .gitignore`, `M firebase.json`, `?? odd/tasks/firestore-rules-ci-suite.md`,
   `?? rules_test/` — nothing else. `git diff --stat`: 31 insertions across
   the three tracked files. `git status --porcelain --untracked-files=all`
   shows 0 entries matching `node_modules` (`git check-ignore -v` confirms
   `rules_test/node_modules/` is ignored); untracked under `rules_test/` are
   exactly README.md, firestore.rules.test.js, package-lock.json,
   package.json.
5. Existing checks unaffected: `python -m unittest discover -s tool -p
   "*_test.py"` → `Ran 103 tests ... OK`. Workflow YAML parses (validated
   with js-yaml; PyYAML not installed on this machine),
   `firebase.json`/`package.json` parse as JSON. Nothing Dart changed, so
   `flutter analyze`/`flutter test` were not re-run; the `validate` job was
   not modified.

## Out of scope

- Deploying anything to the real Firebase project, and the "verify deployment
  matches the tested version" half of the threat model.
- The friends/directory feature.
