# Database and Firebase setup reference

## Read this first

This is a current-state reference and setup plan, **not** proof of deployed Firebase configuration.

### Status legend

- **Verified in repository** — supported by version-controlled client code or files.
- **Proposed** — a future design or operator step.
- **External/unverified** — a provider-console, deployed, or emulator state not proven by this repository.

For extractable Flutter configuration, read [client-visible configuration](docs/production/client-configuration.md). Security risks and required test cases are in the [threat model](docs/production/threat-model.md); owner-only console work is tracked in the [owner-action register](docs/production/owner-action-register.md).

## Current data placement

### Verified in repository

| Data | Current runtime location | Notes |
| --- | --- | --- |
| Identity | Firebase Authentication | Provider enablement is external/unverified. |
| User records | Firestore | Deployed rules and document state are external/unverified. |
| Chats and messages | Firestore | See the field/query contract below. |
| Trips and packing | Local `sqflite` SQLite | Not Firestore; ordinary SQLite is not encrypted at rest. |

Do not create Firestore `trips`, `packingLists`, or `packingItems` collections from earlier documentation. Standalone-list routing based on a user ID used as a trip ID is not implemented.

## Firestore chat field and query contract

### Verified in repository

The current Firestore chat client uses:

- Chat-list query: `where('memberIds', arrayContains: userId)` plus `orderBy('updatedAt', descending: true)`.
- Chat fields: `memberIds`, `createdAt`, `updatedAt`, `unreadBy`, and `lastMessage`.
- Message query: ordered by `createdAt` ascending.
- Message fields: `createdAt` and `isRead` (alongside message identity/content fields).

`lastMessageAt`, message `timestamp`, and `readBy` are not the current Firestore contract. Application-facing names such as `lastMessageAt` do not change the stored Firestore field `updatedAt`.

### External/unverified

There is no version-controlled Firestore index configuration or emulator suite. The chat-list query may require a composite index in a real Firebase project; capture the exact provider requirement, version-control the resulting configuration, and prove it with emulator/query tests before treating it as deployed. Do not invent or deploy rules from this document.

## Setup plan — proposed/operator work

Complete these steps only after the data schema and authority model are approved:

1. Define which operations are client-owned and which require a trusted backend. Client plan writes and directory reads are known gaps; rules cannot safely encode the current behaviour without that decision.
2. Add version-controlled Firebase project, rules, indexes, and emulator configuration.
3. Write emulator tests for unauthenticated, owner/member, other-user, former-member, privileged-field, directory, and query/index cases.
4. Have the owner apply provider-console settings and deploy only the tested configuration.
5. Retain the tested configuration, emulator output, and deployed-state comparison as release evidence.

The following are **External/unverified** until the owner supplies evidence: Firebase project ID/plan/region, Auth providers, deployed rules/indexes, App Check, Storage configuration, and emulator availability.

## Client-visible environment values

`.env.example` currently documents these extractable client configuration names:

```env
OPENWEATHER_API_KEY=
GOOGLE_MAPS_API_KEY=
REVENUECAT_API_KEY=
REVENUECAT_API_KEY_IOS=
```

They are not backend secrets. Supply only provider-restricted client values locally; never add service accounts, private keys, database credentials, or webhook secrets. See [client-visible configuration](docs/production/client-configuration.md) for restrictions, rotation, and the local validator.

## Historical material quarantined

The former Firestore trips/packing schema, standalone-list routing rule, `lastMessageAt` chat index, Storage rules, and Firebase deployment/emulator commands described an unverified or mismatched target state. They are intentionally not deployment instructions. Reintroduce a specific item only through an approved schema/authority design, version-controlled configuration, and emulator evidence.
