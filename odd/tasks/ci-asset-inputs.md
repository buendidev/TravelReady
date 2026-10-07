# CI asset inputs

Feature document. Owner-authorized work; every task closes with one work-unit
commit on `fix/ci-asset-inputs`.

## Why

`CI` has never been green on this repository, and after the `firebase_options`
defect was fixed the next layer became visible: `flutter test` fails **while
building the asset bundle**, before any test runs.

```
Error: unable to find directory entry in pubspec.yaml: .../assets/images/
Error: unable to find directory entry in pubspec.yaml: .../assets/animations/
Error detected in pubspec.yaml:
No file or variants found for asset: .env.
Error: Failed to build asset bundle
```

None of it is visible on the developer's machine, because those files exist
there as untracked leftovers. It is reproducible only in a fresh checkout, which
is why this feature was developed in a linked worktree off `main`: with no
`.env` and no `assets/images|animations`, `flutter test` fails there exactly as
it fails in CI. That reproduction is the whole basis of this document.

## The decision this feature does NOT make

Two candidate fixes were considered and the cheap one was chosen **on evidence**:

- **Rejected: move the client configuration to compile-time `--dart-define`.**
  It buys nothing on exposure — `String.fromEnvironment` is compiled into the
  binary exactly as the bundled asset is, so the keys stay extractable either
  way — while it would reverse a decision this repository documents and
  *enforces*: `.env.example` is tracked and placeholder-only,
  `tool/release_config_validator.dart` runs in CI and fails on
  `missing_env_example`, enforces a variable allow-list and scans production
  roots for secrets, and `docs/production/client-configuration.md` states that
  `.env` is public client configuration rather than secret storage. It would
  also break key injection in five test files, including the RevenueCat test
  that exercises the configured path with `dotenv.loadFromString`.
- **Chosen: make CI do what the repository already tells a human to do.**
  `README.md` documents `cp .env.example .env`. CI never performed that step.

## In scope

| Unit | Deliverable |
| --- | --- |
| CIA-1 | Remove the two dead asset declarations from `pubspec.yaml` |
| CIA-2 | CI creates the client configuration from the tracked template before testing |
| CIA-3 | Local verification with the real suite, on a checkout that has neither file |

## Out of scope (non-goals)

- **No application code changes.** No Dart file is touched.
- **No `.env` redesign, no `--dart-define`, no dependency changes.** The
  documented client-configuration boundary stays exactly as it is.
- **No claim that the keys stop shipping inside the binary.** They do, by design
  and by documentation; restricting and rotating them at the provider is a
  separate, already-registered owner action.
- No `.gitkeep` placeholders: empty directories are tracked only when something
  references them, and nothing does.

## Constraints that are not negotiable

1. No secret enters the repository or CI. `.env.example` holds placeholder values
   only — `YOUR_OPENWEATHER_API_KEY` and friends — and it is already tracked and
   already validated by CI.
2. `tool/release_config_validator.dart` keeps passing; it is untouched.
3. The removal of the two declarations must be justified by evidence that nothing
   reads them, not by assumption.
4. Every claim here is a command that was run.

## Evidence that the two declarations are dead

- `grep -rn "assets/" lib/ --include="*.dart"` → no match.
- `grep -rniE "assetimage|images/|animations/|lottie|rive" lib/ --include="*.dart"`
  → no match.
- `assets/icons/` is consumed only by `flutter_launcher_icons` at build time
  through its `image_path` setting, which does not require a runtime asset
  declaration; it is kept, and so is its declaration.
- Both directories are empty on the developer's machine.

## Tasks

### CIA-1 — Remove the dead asset declarations

Drop `assets/images/` and `assets/animations/` from the `flutter: assets:` list in
`pubspec.yaml`, leaving `assets/icons/` and `.env`.

Evidence: the two `unable to find directory entry` errors disappear from a run
that still has no such directories; before the change they are present.

### CIA-2 — CI provides the client configuration template

Add one step before the tests that copies the tracked template:
`cp .env.example .env`. Placeholder values only; the tests use mocks and
`EnvValidator` only asserts in debug.

Evidence: the full suite passes in a clean clone of this branch, with no `.env`
present before the copy step.

### CIA-3 — Local verification on a real checkout

Run the real suite, not a single file, on a checkout that starts with neither
`.env` nor the two directories.

Evidence: `flutter test` from a clean clone of the branch, after the documented
copy step, with its pass count recorded; and `flutter analyze` reported honestly,
including the two `firebase_options.dart` errors that belong to the sibling
branch `chore/tracked-build-inputs` and are therefore expected to remain here.

## Log

- Opened after the owner approved the corrected plan and rejected the
  `--dart-define` refactor, on the strength of the three findings recorded above.

- **CIA-1 and CIA-2 applied; CIA-3 verified independently** in a clean checkout of
  this branch (delegated, `git clone --branch fix/ci-asset-inputs`, a clone that
  starts with no `.env`, no `assets/images/` and no `assets/animations/`, and
  nothing staged). Verbatim exit codes for CI's own sequence:
  `cp .env.example .env` 0, `flutter pub get --enforce-lockfile` 0,
  `dart run tool/release_config_validator.dart` **0** — the security validator
  still passes and was not touched — `python tool/check_landing.py` 0, and
  **`flutter test` 0 with `01:13 +436: All tests passed!`**, the full suite rather
  than a single file.

- `flutter analyze` exits 1 with **exactly two errors**, both the known
  `firebase_options.dart` pair (`uri_does_not_exist` at `lib/main.dart:10:8` and
  `undefined_identifier` at `lib/main.dart:40:14`) that belongs to the sibling
  branch `chore/tracked-build-inputs`. The report count fell from 80 to **77**:
  removing the two dead declarations removed exactly the three asset warnings and
  nothing else, which is the arithmetic confirming the change was bounded.

- `.env` produced by the copy step is ignored (`.gitignore:5`) and never staged:
  `git status --porcelain` empty, `git ls-files .env` empty.
