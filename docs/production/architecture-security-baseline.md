# Production architecture and security baseline

Status: proposed baseline, not a deployed-control attestation. PRF-1 documentation only.

## Current boundary and target

Parent-verified repository observations: Flutter mobile uses Firebase Auth/Firestore and local SQLite; no self-hosted backend exists. Architecture anchors: `pubspec.yaml`, `lib/main.dart`, `lib/injection/injection.dart`, `lib/core/database/database_helper.dart`, and `lib/core/utils/app_env.dart`. These are provenance pointers, not a fresh deployment audit. Local SQLite is currently unencrypted; Firebase deployed rules remain unverified.

| Boundary | Responsibility and required controls |
| --- | --- |
| Flutter / device (untrusted) | UI, local trip/packing data, session handling and preferences. Never authoritative for access rights, subscriptions, invite consumption or privileged writes. Device storage and all client inputs can be inspected or modified. |
| Firebase managed services | Auth identity and Firestore persistence. Rules must independently enforce ownership/membership and field restrictions; authentication alone is insufficient. Audit deployed rules and indexes before release. |
| Proposed minimal trusted backend | Validate identity and authorization; verify subscription events; redeem invites atomically; proxy secret-bearing APIs; dispatch notifications; execute retention/rights jobs. Not implemented or deployed by this document. |
| Providers and operators | Contractual residency, access management, monitoring, backups and recovery. Responsibilities must be explicit per service, not inferred from a VPS purchase. |

Preserve current Firebase and SQLite architecture until a tested migration/sync design is approved. Selecting an EU VPS would not relocate Firebase, third-party APIs, device data or their support/subprocessor access.

## EU provider and DPA decision gate

Before selecting any hosting, Firebase service configuration, analytics, messaging, weather or subscription provider, record:
- Selectable EU region for each relevant workload and backup; documented location of logs, replicas, support access and subprocessors.
- Controller/processor roles, appropriate DPA, security commitments, subprocessors, deletion/return terms and incident notification responsibilities.
- Transfer locations and mechanism for any non-EEA access, with qualified legal assessment; EU storage alone does not establish compliance.
- Backup/export/restore capabilities, costs, outage support, encryption/key controls and exit portability.

Parent-verified HostGator documentation does not offer selectable EU VPS region and requires customer-managed VPS backups. Do not treat it as meeting this baseline without new contractual evidence and legal review. No vendor guarantees or certifications are asserted here.

## Operational controls to implement and prove

- **Secrets:** `.env` is bundled as a Flutter asset and cannot hold backend secrets. Keep privileged keys in a server-side managed secret store with least-privilege identities, rotation, access audit and incident revocation. Public client configuration is not authorization. Inventory existing bundled values without copying them into docs/logs; owner rotates exposed privileged credentials.
- **Encryption:** require validated TLS for network paths; do not disable certificate checks. Verify provider encryption at rest and key/access management. Assess local SQLite encryption, OS-protected key storage, logout/account-switch cleanup and device-backup exclusions. Do not claim current local encryption.
- **Backups (3-2-1):** maintain three copies including primary, two independent storage types/systems, and one offsite copy in an approved region. Assign an owner per dataset; Firebase, future backend data, configuration and device-only data need distinct coverage. Replication alone is not backup. Protect backups with encryption and separated, least-privilege credentials; reconcile rights/retention requirements with backup expiry.
- **Recovery:** owners approve RPO/RTO and backup cadence based on business needs, not invented promises. Test isolated restores before launch and on an approved recurring schedule; record date, dataset, integrity checks, elapsed recovery time and failures. Reapply deletion/blocking records before restored data becomes available. Identify local-only data that cannot be recovered centrally.
- **Monitoring:** alert on denied/abnormal access, entitlement/invite abuse, job failures, provider outages, backup failures and unexpected spend. Minimize identifiers; never log tokens, message bodies, document contents or API keys. Assign alert responders, escalation and incident/breach assessment procedures, including applicable notification deadlines after legal review.

## External user-owned setup checklist (not performed)

- [ ] Approve architecture, risk owners, data map and legal review.
- [ ] Select service-by-service EU regions; obtain DPAs, subprocessor/transfer evidence and exit terms.
- [ ] Provision accounts, billing, domains/DNS and least-privilege operator identities with MFA.
- [ ] Audit/test deployed Firebase rules and indexes; establish trusted backend and webhook identity validation.
- [ ] Configure server secrets, key rotation and sanitized logging; review bundled assets.
- [ ] Configure backup destinations, access separation, retention and deletion reconciliation; prove isolated restore.
- [ ] Configure alerts, incident contacts and approved recovery targets.
- [ ] Configure subscription, weather and notification services; review SDK data collection and store disclosures.
- [ ] Obtain legal approval and production release approval. No purchase, deployment or publication is authorized here.

Related: [data and rights design](../legal/data-retention-rights.md), [legal document requirements](../legal/privacy-terms-requirements.md), [threat model](threat-model.md).

Legal baseline: [GDPR official text](https://eur-lex.europa.eu/eli/reg/2016/679/?locale=ES), especially Articles 25, 28, 32 and Chapter V. This is engineering guidance, not legal advice.
