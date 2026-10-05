# Data classification, retention and rights design

Status: design for legal and engineering review; not an implemented retention policy.
**Not legal advice.** Counsel must approve purposes, lawful bases, retention triggers/durations, blocking grounds, processor roles and transfers before production.

## Proposed inventory and retention matrix

All purpose/base entries below are candidates marked **legal-review-required**. No retention duration is approved. Owners must enumerate actual fields, stores, SDK collection and recipients before implementation.

| Category / classification | Location or proposed boundary | Candidate purpose / lawful basis (legal-review-required) | Retention decision required |
| --- | --- | --- | --- |
| Identity, account/profile and directory identifiers / personal, restricted | Firebase Auth/Firestore | Account service / contractual necessity to assess; directory discovery needs separate necessity/access assessment | Account lifecycle, inactive accounts and post-closure obligations |
| Trips, packing, activities and tasks / personal, confidential | Local SQLite; any future sync separately inventoried | User-requested planning / contractual necessity to assess | User deletion, account/device lifecycle and sync tombstones |
| Chat/group membership and messages / personal, confidential | Firebase; exact collections to verify | Communication service / contractual necessity to assess | Member departure, sender deletion and other participants' rights |
| Invitations / personal plus sensitive capability token | Proposed trusted backend | Requested sharing and abuse prevention / contractual necessity or legitimate interests to assess | **Single-use; expires after 24h**. Token expiry is an access rule, not an approved audit-record retention period |
| Subscription/payment references / personal, financial metadata | Store/provider and proposed server entitlement records | Purchase fulfillment / contract; fiscal/legal duties only where counsel establishes applicability | Provider obligations, disputes and mandatory records; no payment-card storage assumed |
| Weather queries/location / potentially personal, location-sensitive | Client/provider; proposed secret-bearing proxy | Requested forecast / necessity and optional precise-location permission/base assessment | Query minimization, provider logs and caching; prefer destination over device location |
| Notification tokens/preferences and reminder metadata / personal | Proposed dispatch service plus device | Requested alerts / service necessity or consent as applicable | Token invalidation, opt-out, account closure and reminder completion |
| Travel-document metadata/content, if introduced / highly confidential; may contain special-category data | Future storage must be explicitly designed | User-requested reminders/storage / necessity and Article 9 condition assessment if applicable | Minimize to reminder metadata where possible; separate content decision |
| Security logs, support requests and rights-request evidence / restricted personal | Proposed operational tools | Security/support/accountability / legitimate interests or legal duty to assess | Necessity, access limits, approved evidence periods |
| Backups and blocked records / restricted, inherits source sensitivity | Approved backup stores and isolated legal hold store | Recovery or specific legal duties/claims / counsel-defined basis | Backup rotation, blocking grounds, release trigger and final erasure |

Record each approved retention rule as: category, purpose, base, trigger, duration, authority/rationale, owner, applicable stores/processors, backup treatment and test evidence. Avoid indefinite defaults; do not invent statutory periods. Product invitation expiry does not determine other categories' retention.

## Deletion and blocking mechanics (proposed)

1. Authenticate and proportionately verify the requester without collecting unnecessary identity evidence. Authorize scope; account for shared data and other people's rights.
2. Suspend ordinary access where required; revoke sessions, invitations and notification tokens as appropriate. Ensure enforcement in server/rules, not only UI. Handle SQLite copies, caches and offline devices with account-bound cleanup and synchronization tombstones; acknowledge limits on unreachable devices and copies held by other users.
3. Inventory and erase eligible data across Auth, Firestore, local storage, future services and processors. Account deletion alone does not erase other stores. Track partial failures with idempotent retries and minimal audit evidence.
4. Where counsel establishes a duty to retain or block, isolate only necessary records from ordinary processing. Restrict access to authorized legal/duty handling; prevent searches, app display, notifications, analytics and routine staff access. Do not confuse Spanish legal blocking with the separate GDPR right to restriction.
5. On expiry of the approved blocking ground, erase records and processor copies. Backups must expire under approved rules and restores must reapply deletion/blocking before service resumes; disclose any justified delayed physical erasure rather than promising instant removal from every backup.

## Data subject request workflow

Provide a clear contact/intake channel for access, rectification, erasure, restriction, portability and objection; handle consent withdrawal where consent applies. Log receipt and proportionate verification, search all applicable systems, assess exceptions with counsel, deliver securely, and record completion or a reasoned response. GDPR Article 12 generally requires action within one month, with limited extensions and timely notice; counsel validates applicability and exceptions. Portability scope is not identical to access scope.

Exports must separate requester data from other users' confidential data and provide an appropriate machine-readable format where portability applies. Test wrong-user requests, shared chats, offline devices, retries, blocked records, processor failures and restoration of deleted data. These flows do not yet exist merely because they are specified here.

## Processor and accountability records

Maintain a processing inventory/Article 30 record where applicable, linked to the retention matrix. For each provider record legal entity, role (not automatically processor), service/data categories, purposes, regions/access locations, subprocessors, DPA/version, transfer assessment, security evidence, retention/deletion API, incident contact and contract owner. Include Firebase, weather, subscription/store, future notifications/hosting and operational tools. Review DPIA necessity, especially location or sensitive document features, before enabling them.

## Review references

- [Official GDPR](https://eur-lex.europa.eu/eli/reg/2016/679/?locale=ES): Articles 5–6, 9, 12–22, 25, 28, 30, 32 and Chapter V.
- [AEPD: data protection by default guide](https://www.aepd.es/guias/guia-proteccion-datos-por-defecto.pdf): minimization and privacy-preserving defaults.
- [AEPD: right to erasure](https://www.aepd.es/derechos-y-deberes/conoce-tus-derechos/derecho-de-supresion): erasure and retention exceptions. Counsel must also validate Spanish blocking obligations under applicable law; this document assigns no statutory blocking duration.

References are review aids, not proof that this design or the application complies. Links were not fetched in this documentation-only task.
