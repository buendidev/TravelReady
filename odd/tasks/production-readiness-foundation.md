# Production readiness foundation

## Objective
Prepare TravelReady for a secure Spain/EU production path while implementing the remaining product roadmap in bounded, independently verifiable work units. Mobile binaries remain distributed through Google Play and the App Store; production infrastructure will host only the web, backend/API, database, background jobs, and operational tooling.

## Confirmed decisions
- Implement all remaining roadmap milestones incrementally; do not publish, purchase services, create external accounts, or release without explicit user action.
- Use a hosting provider with selectable EU region and an appropriate data-processing agreement (DPA); do not assume HostGator VPS is suitable.
- Implement privacy by design: data minimization, retention categories, user access/export/deletion, restricted blocking for claims/legal duties, then final erasure.
- Invitations are single-use and expire after 24 hours.
- Notifications cover chats/groups plus user-controlled reminders for activities, tasks, and expiring documents.
- Free/Premium limits will be proposed from current market/cost research and made remotely configurable.

## Constraints
- This is not legal advice. Privacy policy, terms, retention schedules, processor contracts, and international-transfer decisions require qualified legal review before production.
- Do not expose server secrets in Flutter assets or client code.
- Preserve the current Firebase authentication/chat and local SQLite trip/packing architecture until a migration/sync plan is proven.
- Preserve unrelated `HANDOFF_TO_AGENT.md` and `config/` worktree files.
- Keep each implementation work unit focused, testable, and below the normal review budget; external configuration remains user-owned.

## Tasks
- [x] PRF-1: Create the reviewed production architecture, data classification/retention matrix, privacy-policy and terms requirements, threat model, and EU-hosting/backup decision criteria. Route: delegated exploration plus documentation; no application behavior changes. Artifacts: [architecture/security and EU-hosting/backup baseline](../../docs/production/architecture-security-baseline.md), [data classification/retention and rights design](../../docs/legal/data-retention-rights.md), [non-publishable privacy/terms requirements](../../docs/legal/privacy-terms-requirements.md), and [scoped threat model](../../docs/production/threat-model.md). Evidence: repository architecture mapping, official GDPR/AEPD source review, and independent structural verification. No deployed controls or legal approval are asserted. The four draft artifacts are now committed as `35da5c2`.
- [ ] PRF-2: Establish version-controlled deployment/security foundations: environment templates, secret boundary rules, Firebase rules/indexes discovery, release validation, CI design, and operational runbooks. Route: delegated writer after PRF-1 scope is approved. **Partial evidence only:** Local Android family testing is blocked: `flutter doctor` reports a missing Android SDK and `ANDROID_HOME`/`ANDROID_SDK_ROOT` are empty, so no real-device APK build has been verified. See the [Android family-test runbook](../../docs/production/android-family-test.md) and the [owner-action register](../../docs/production/owner-action-register.md). `.env.example` documents the four extractable Flutter client values (`OPENWEATHER_API_KEY`, `GOOGLE_MAPS_API_KEY`, `REVENUECAT_API_KEY`, and `REVENUECAT_API_KEY_IOS`); client-configuration guidance, a dependency-free validator with focused tests, duplicate-template detection, and bounded production-root secret-pattern scanning provide local guards only; `pubspec.lock` is version controlled, and a real SQLite FFI regression proves fresh production schemas contain no hard-coded demo/test rows. Repository inspection also confirms Firebase Auth/Firestore for users/chats and ordinary unencrypted `sqflite` SQLite for trips/packing. No version-controlled Firebase project, rules, indexes, or emulator suite exists. Deployed Firebase rules/indexes, region, App Check, provider enablement/restrictions, entitlement authority, CI, release signing, historical/binary secret scanning, and server-side secret management remain external/unverified or pending. Client plan writes and directory reads remain security gaps; rules cannot be safely authored until schema/authority behaviour and emulator tests are fixed. Evidence: structural checks, no bundled-secret regression, focused schema/migration tests, and a version-controlled least-privilege CI workflow with local validator tests; this does not prove any external configuration. The CI workflow runs lockfile enforcement, release-config validation, non-fatal-warning/info analysis, and the full test suite, but has not verified any GitHub/Actions/provider setting and does not build, sign, release, or deploy.
- [ ] PRF-3: Design and build the minimal backend boundary needed for secure server-owned concerns (entitlements, API secrets, invitations, notifications, retention jobs), including local/emulator tests and an EU deployment template. Route: separate feature after architecture and provider selection; do not add a VPS/database ad hoc.
- [ ] PRF-4: Implement user data-rights flows: privacy controls, export, deletion request, restricted blocking, retention jobs, and audit evidence. Route: separate feature after backend and legal review; tests must prove ordinary data becomes inaccessible when blocked/deleted.
- [ ] PRF-5: Implement the next product milestones in dependency order: reusable bags, shared-trip security, notifications, Apple/Crashlytics, premium lifecycle, web presence, and release readiness. Route: separate ODD features/work-unit commits; each requires repository mapping and tests.
- [ ] PRF-6: Complete user-owned external operations: EU provider contract/account, domain/DNS, Firebase/RevenueCat/Maps/OpenWeather configuration, backups/restores, Play/App Store accounts, signing, store submissions, and legal review. Route: user-led with exact runbooks; no agent-created accounts or purchases. Track the owner-only prerequisites and deferred decisions in the [production owner-action register](../../docs/production/owner-action-register.md).

## Initial evidence
- The repository is a Flutter mobile client, not a self-hosted backend: `pubspec.yaml`, `lib/main.dart`, and `lib/injection/injection.dart` wire Firebase Auth/Firestore, local SQLite, direct weather HTTP, and a partial RevenueCat wrapper.
- Current local SQLite is not encrypted despite a SQLCipher comment: `lib/core/database/database_helper.dart`.
- `.env` is ignored but bundled as a Flutter asset, so it is not a suitable location for backend-only secrets: `pubspec.yaml`, `lib/main.dart`, `lib/core/utils/app_env.dart`.
- No version-controlled `firebase.json`, Firestore rules, Firestore indexes, or emulator suite exists. Deployed access controls, Firebase region, App Check, provider enablement, and indexes are external/unverified; client code currently updates subscription fields and exposes directory reads, so schema/authority decisions and emulator tests must precede any rules work.
- HostGator's published VPS material indicates no selectable EU data-centre region and user responsibility for VPS backups; this is unsuitable as an assumed EU-data residency foundation without further contractual/legal assessment.

## PRF-1 structural verification
- `find` on `docs` with `**/*.md` confirmed all four linked draft artifact paths exist. Relative links between these artifacts and the task resolve to those paths by directory inspection.
- `grep` of Markdown headings and key markers confirmed the architecture/operations sections, 3-2-1 backup design, classification/rights/processor sections, non-publishable legal outline, GDPR/AEPD references and single-use/24h invitation requirement. The threat-model table includes all eight requested surfaces.
- Independent verification ran `git status --short`, confirming the new documentation surfaces alongside pre-existing unrelated `HANDOFF_TO_AGENT.md`/`config/` entries, and `git diff --check` for the intended documentation paths, which produced no output. Since the new artifacts are untracked, this does not independently validate their whitespace; no application, infrastructure, configuration, credentials or lockfiles were edited, and no commit was made.
- Passive documentation exception: behavior-level RED/GREEN tests are inapplicable. No exact validation runner was supplied; structural checks used file discovery and content inspection only. Official RGPD/AEPD sources were reviewed by the parent; deployed rules, vendor contracts and legal correctness remain unverified and require external review/setup.

## Delivery
- Branch: `feat/sqlite-trip-packing-integrity` (current); create focused feature branches before non-trivial implementation once this planning unit closes.
- No push, pull request, store release, infrastructure purchase, external account creation, credential change, or legal claim is included.

## Commit record
The locally verifiable part of this plan is now committed on `feat/sqlite-trip-packing-integrity`. PRF-1 is closed by those commits; **PRF-2 remains open** because its external items (deployed Firebase rules/indexes/region, App Check, provider restrictions, server-side secret management, release signing, emulator suite, historical/binary secret scanning) are still unverified and are not repository work.

| Commit | Content |
| --- | --- |
| `35da5c2` | PRF-1: architecture/security baseline, threat model, data retention/rights, privacy and terms requirements |
| `e8c034b` | PRF-2: `.env.example`, client-configuration and release-validation docs, release-config validator plus tests, CI workflow, owner-action register, Android family-test runbook |
| `8378553` | `pubspec.lock` tracked with the `.gitignore` change that unignores it |
| `7248691` | SQLite schema hardening: `createSchema` extracted, seeded demo users/trips/lists/items removed, tests moved onto an explicit fixture, regression added |
| `1e03400` | `SECURITY.md` and `DB_SETUP.md` rewritten around verified-versus-external status and release gates |
| `docs(odd)` record | This document plus `odd/tasks/production-readiness-commits.md` |

Verification for the sequence: 178 suite tests passed and `flutter analyze` exited 0 with 119 infos, zero warnings and zero errors, both before and after the commits; all 25 changed paths were hashed before staging and matched `git rev-parse HEAD:<path>` afterwards. The default FFI database directory was backed up before the runs and restored after them. Nothing was pushed, published or provisioned.
