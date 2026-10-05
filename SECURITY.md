# Security status and release gates

## Read this first

TravelReady currently uses Firebase Authentication and Firestore for users and chats. Trips and packing data are stored locally with ordinary `sqflite` SQLite; they are **not** Firestore collections and are **not encrypted at rest**.

### Status legend

- **Verified in repository** — supported by version-controlled client code or files.
- **Proposed** — a design or next step; not implemented or proven.
- **External/unverified** — a provider-console, deployed, device, or release setting that this repository cannot prove.

Use the [client-visible configuration guide](docs/production/client-configuration.md) for extractable Flutter values, the [threat model](docs/production/threat-model.md) for risks and required tests, and the [owner-action register](docs/production/owner-action-register.md) for actions that only the project owner may perform.

## Current repository evidence

### Verified in repository

- Firebase Auth and Firestore-backed user/chat client code exist.
- Chat-list queries filter `memberIds` with `arrayContains` and order by `updatedAt` descending. Chat documents use `createdAt`, `updatedAt`, and `unreadBy`; message documents use `createdAt` and `isRead`.
- Trip and packing persistence uses `sqflite` SQLite. It has no at-rest encryption in the current implementation.
- `.env.example` defines `OPENWEATHER_API_KEY`, `GOOGLE_MAPS_API_KEY`, `REVENUECAT_API_KEY`, and `REVENUECAT_API_KEY_IOS`.

### External/unverified — do not infer completion

- No version-controlled `firebase.json`, Firestore rules, Firestore index configuration, or emulator suite exists.
- Deployed Firestore rules and indexes, Firebase project region, Authentication provider enablement, Firebase App Check, and provider key restrictions are unverified external state.
- Client-controlled plan writes and directory reads are known security gaps. Firestore rules must not be authored or deployed until schema/authority behaviour and emulator tests define and prove the required access model.

## Configuration boundary

Flutter bundles `.env` into the client artifact. Every value in it is extractable and therefore must be treated as client configuration, not a backend secret. Use only provider-restricted client keys, with package/bundle, signing, API, origin, quota, and environment restrictions where the provider supports them. Do not put service accounts, private keys, database credentials, webhook secrets, or administrator credentials in `.env`, `.env.example`, assets, or client code.

See [client-visible configuration](docs/production/client-configuration.md) for the supported names, local validation, and scan limits. Provider restriction and rotation are **External/unverified** owner actions.

## Release gates

All items remain unchecked until evidence is captured. This checklist is a release decision aid, not evidence that a setting exists.

### Repository and client gates

- [ ] Record the focused lint/static-analysis result; do not claim zero lints without its output.
- [ ] Confirm `.env` is ignored and `.env.example` contains only the four documented client-visible keys.
- [ ] Run and retain the result of `dart run tool/release_config_validator.dart .`.
- [ ] Review the shipped artifact for extractable configuration and confirm no backend secret is bundled.
- [ ] Decide and test protection for SQLite data at rest, backups, logout, deletion, and account switching; current SQLite is unencrypted.
- [ ] Resolve client plan writes and directory-read exposure with a defined authority model and tests.

### Firebase and external operator gates

- [ ] Define Firestore schema and authority behaviour, then write version-controlled rules and indexes.
- [ ] Add and run Firebase Emulator authorization/query tests for anonymous, owner/member, other user, former member, privileged-field, and directory cases.
- [ ] Capture and compare deployed Firestore rules/indexes with the tested version; deployment is currently unverified.
- [ ] Verify Firebase project region, enabled Auth providers, billing/quota controls, and App Check in the owner-controlled consoles.
- [ ] Apply and evidence provider restrictions and rotation procedures for every client-visible key.
- [ ] Verify Android/iOS release hardening, including any chosen code-obfuscation setting; ProGuard/R8 is not asserted here.
- [ ] Obtain owner release approval and record accepted residual risks.

## Proposed operator sequence

After the schema and authority model are approved, an operator may create Firebase CLI/emulator configuration and use the relevant Firebase commands in an owner-controlled environment. Do not run deployment commands merely because they appear in documentation: first version-control and test the rules/indexes, then capture deployment evidence. The owner-only prerequisites are tracked in the [owner-action register](docs/production/owner-action-register.md).
