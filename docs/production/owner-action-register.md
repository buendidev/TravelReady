# Production owner-action register

This is the durable checklist for production actions that only TravelReady's human owner may perform. It is deliberately a planning register, not proof that any account, contract, setting, or approval exists.

**Security boundary:** credentials, recovery codes, payment details, and private keys must never be pasted into chat or committed to this repository. Use the relevant provider's secure console, password manager, and approved secret storage instead.

## Owner actions

| Owner action | Status | Necessary when | Agent prepares first | Human owner action remaining |
|---|---|---|---|---|
| EU hosting provider purchase, EU-region selection, and DPA acceptance | Not needed yet | Before deploying any production backend, web service, database, jobs, or operational tooling | Provider-evaluation criteria, deployment template, and DPA review checklist | Select and purchase a provider, choose an EU region, accept/sign the DPA, and retain the contract record |
| Domain purchase and DNS delegation | Not needed yet | Before a public production web/API domain is required | Domain/DNS record plan and verification runbook; the static site is already written against the placeholder origin `https://travelready.example`, with the one-step replacement procedure in `website/README.md` | Purchase the chosen domain and delegate/configure DNS through the owner-controlled registrar/DNS account, then confirm the placeholder origin has been replaced in the site's canonical tags, `sitemap.xml` and `robots.txt` |
| Public website publication (static seven-page site) | Not needed yet | Before the site is served from a public host | Seven pages with unique metadata, `sitemap.xml`, `robots.txt`, CSS-only motion and a structural checker in CI; the content only the owner can supply is listed in `website/README.md` | Choose the host, replace the placeholder canonical origin, decide and publish the privacy policy and legal notice, choose the contact channel, point the download page at a real APK, then publish and keep the checker green |
| Firebase and Google Cloud ownership, billing, and production settings | Not needed yet | Before production Firebase/Google Cloud services, quotas, or billing are enabled | Project/settings inventory, least-privilege checklist, and rules/index deployment plan | Create or take ownership of the production project, enable billing/services, set provider controls, and approve production settings |
| RevenueCat account, entitlement, and store-product setup | Not needed yet | Before Premium is sold or validated against production stores | Entitlement/product mapping and configuration checklist | Create/own the RevenueCat account, connect the stores, and configure/approve products and entitlements |
| Android device availability for the local family test (the SDK is already installed and the debug APK builds) | Blocked | Before the on-device walkthrough can run | [Local Android build and family-test runbook](android-family-test.md) | Connect an Android phone with USB debugging enabled and authorize it; for a signed release APK, provide an owner-controlled signing configuration without sharing credentials or keystore contents in chat |
| Google Play Console account and release setup | Not needed yet | Before Android production distribution | Android release checklist, listing assets/specification, and signing handoff instructions | Own the Play Console account, complete identity/payment/tax setup, create the app, and approve/publish releases |
| Apple Developer, App Store Connect, Mac, and signing setup | Not needed yet | Before iOS production builds, TestFlight, or App Store distribution | iOS release checklist, identifiers/capabilities plan, and signing handoff instructions | Own the Apple Developer and App Store Connect accounts, provide a suitable controlled Mac/signing workflow, complete agreements, and approve/publish releases |
| API provider accounts and key restrictions (for example Maps or weather) | Not needed yet | Before a production feature depends on a third-party API | Provider inventory, minimum scopes/restrictions, quota plan, and secret-boundary design | Create/own each provider account, accept terms/billing, issue restricted keys in the provider console, and set quotas/alerts |
| Legal counsel review | Not needed yet | Before public production processing of personal data, paid subscriptions, or final legal notices | Draft privacy/terms requirements, processor list, rights/retention design, and questions for counsel | Engage qualified counsel and approve privacy notices, terms, retention schedule, processor/transfer positions, and required registrations/disclosures |
| Backup destination ownership and restore participation | Not needed yet | Before production data or operational configuration is relied on | Backup/restore runbook, retention proposal, and restore-test evidence template | Own the backup destination and access controls, approve retention/costs, and participate in and sign off restore exercises |
| GitHub Actions enablement and CI branch protection | Not needed yet | After repository publication, before relying on CI as a merge control | Version-controlled least-privilege CI workflow and validation documentation | Enable Actions, require the CI check, and enforce full-SHA action policy and branch protection; do not perform this yet |
| Production release approval | Not needed yet | Immediately before each production deployment or store submission | Release candidate, validation evidence, rollback plan, and release checklist | Review evidence, accept residual risk, and explicitly authorize the production deployment or store submission |

## Deferred decision queue

These choices are intentionally deferred; no decision is required now.

| Decision | Decide when |
|---|---|
| EU hosting/provider vendor selection | Before PRF-3 production deployment work |
| Production domain | Before public web/API DNS work |
| Provider quotas and pricing/budget limits | Before enabling billable production services |
| Legal retention durations | During qualified legal review before production processing |

## Maintenance rule

Update an item's status only with repository or owner-provided evidence. Use `Blocked` when a prerequisite prevents progress, `Ready` when the agent preparation is complete and the owner action can be taken, and `Done` only after the owner confirms completion.
