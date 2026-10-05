# Release validation

## Continuous integration

`.github/workflows/ci.yml` runs for pull requests and pushes to `main`. It uses an Ubuntu runner with read-only repository contents permission, cancels superseded runs for the same workflow/ref, and times out after 15 minutes.

The workflow installs Flutter 3.44.0 on the stable channel with the action cache enabled, then runs these checks in order:

1. `flutter pub get --enforce-lockfile`
2. `dart run tool/release_config_validator.dart`
3. `flutter analyze --no-fatal-infos --no-fatal-warnings`
4. `flutter test`

All third-party actions are pinned to immutable 40-character commit SHAs. The release validator enforces the workflow's presence, `contents: read` permission, full-SHA action pins, and the four command labels.

## Current limits

Analyzer debt remains at 141 known non-fatal diagnostics. CI treats analyzer errors as fatal, but warnings and infos are intentionally non-fatal.

This CI validates source configuration and tests only. It does not build, sign, release, deploy, use secrets, or verify GitHub/Firebase/other provider settings. Provider configuration and repository Actions/branch-protection settings remain owner-managed external controls.
