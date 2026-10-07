# Launch plan — from here to a published product

This is the single ordered picture of what is still missing, who owns each piece,
and what has to be true before each milestone. The owner-action register
(`owner-action-register.md`) holds the actions themselves; the runbooks hold the
how. This document holds the **order** and the **triggers**, so nothing is done
too early and nothing blocks a milestone.

## Milestone 0 — what can be finished without the owner

Code and content work that needs no account, no decision and no payment:

| Item | State |
| --- | --- |
| Remove the academic framing from app, website, docs and metadata | Done — gone from the tree and from the rewritten history |
| Professional website: pricing page, purchase-path page, four legal texts published as drafts, social/OG card, favicon | Done on `feat/website-professional`: thirteen pages, checker plus an 83-test suite green, real-engine pass recorded in `website/README.md` |
| App identity string in one place instead of two literals | Done — `AppStrings.appVersion` |
| Delete the dead local-auth datasource (`AuthLocalDataSource`, `CryptoService.hashPassword`) | Pending |
| The two security loggers (`SecurityLog`, `SecurityLogger`) still coexist | Optional |

Nothing here is blocked, and all of it is what a reader sees first.

## Milestone 1 — the first external tester installs the app

Requires, in this order:

1. **Owner: signing configuration.** `android/key.properties` does not exist, so no
   signed release APK can be built; only the debug artifact exists. Runbook:
   `release-validation.md`.
2. **Owner: Play Console account** (one-off fee), app created, listing written.
3. **Owner: privacy policy published** and reachable by URL — the store requires a
   URL, so this must exist before the listing is submitted.
4. **Owner + me: Firebase production settings** — security rules, indexes, region,
   App Check. PRF-2 records that client-side plan writes and directory reads are
   real gaps and that rules cannot be written safely until the schema/authority is
   fixed with emulator tests. Runbook: `client-configuration.md`.
5. **Owner: data-safety form** in the store listing, which must match what the app
   actually collects. The app now has a truthful basis for it: no analytics, no
   ads, no trackers.

## Milestone 2 — the first euro

1. **Owner: fiscal registration before the activity starts** — see the legal annex.
   Not "when the money arrives": the *alta* has to precede the activity, and Google
   and Apple withhold payouts until the tax information in their consoles is
   complete, so this gates being paid at all.
2. **Owner: RevenueCat account**, products and entitlements configured, and the
   equivalent products created in Play Console.
3. **Me: the subscription flow in the app** through the store's billing, with the
   entitlement reflected in the UI. The paywall's payment sheet belongs to the
   store; the animated component can decorate the paywall but cannot replace it.
4. **Owner: terms and withdrawal conditions** that match the real purchase flow,
   including the 14-day digital-content right and how it is waived.
5. **Me: the web checkout**, if the subscription is also sold from the website.
   That is the only place where a card form of our own is allowed, and it must use
   the processor's hosted fields — never our own server touching card data.

## Milestone 3 — the website goes public

1. **Owner: domain purchase.** The site is written against the placeholder origin
   `https://travelready.example`; the replacement procedure and the proof that it is
   complete are in `website/README.md`.
2. **Owner: hosting choice** (EU region if a backend is involved).
3. **Legal notice published** with the owner's real identifying data (LSSI).
4. **Owner: contact channel** — a real address or form, not a placeholder.
5. **Owner: APK link** pointing at a real signed artifact.
6. **Me: the structural checker in CI** stays green, which it already is.

## Milestone 4 — iOS, and anything after

Apple Developer account, a Mac for building, App Store Connect, and the same
privacy/data-safety work again for the other store. Nothing here blocks the
previous milestones, and no iOS code should be written before an Apple account
exists.

## Legal annex — what applies, when, and what it actually means

Not legal advice: this is a map with sources so a qualified adviser can confirm it
quickly. The fiscal pieces are the ones most often done late and wrong.

### Before the activity starts (Milestone 2)
- **Alta censal** (models 036/037) and the IAE epígrafe the adviser assigns; the
  informatics group is the usual one.
- **RETA if the activity is habitual.** Worth correcting an extended myth: earning
  less than the minimum wage does **not** exclude habitual activity — see
  [STS 941/2025, of 10 July 2025](https://www.iberley.es/noticias/el-ts-aclara-ingresos-smi-alta-reta-autonomos-pensionistas-35716).
  Only pensioners get different treatment. A reduced quota exists for the first
  period, with a possible second year when forecast net income stays below the SMI.
- **Do not wait for the first payout to register.** The stores withhold payments
  until the tax data is complete, and the registration must precede the activity.

### Once there is income
- **VAT depends on who sells to the consumer.** Through the stores, the store is the
  seller to the end user and handles consumer VAT; the developer invoices the
  commission to the store as B2B, which with Google Ireland can mean a reverse
  charge (models 303 and 349). Selling directly from the website makes the owner the
  seller: Spanish VAT, and cross-border EU consumer sales fall under the one-stop
  shop with a **10.000 €** threshold to watch.
  Reference: [AEAT, IVA y comercio electrónico](https://sede.agenciatributaria.gob.es/Sede/iva/iva-comercio-electronico.html).
- **IRPF**: quarterly instalment (130 or 131), invoice and expense ledgers, annual
  return.
- **DAC7**: the stores report developer income to the tax authority automatically.
  There is no version of this where the income stays invisible.
- **Invoicing software**: Verifactu was postponed by the
  [RDL 15/2025](https://sede.agenciatributaria.gob.es/Sede/iva/sistemas-informaticos-facturacion-verifactu/nota-informativa-ampliacion-plazo-adaptacion-facturacion.html)
  to 1 January 2027 for corporate-income-tax payers and 1 July 2027 for the rest,
  with press reports of a further delay. It constrains the software used to invoice,
  not this app.

### Before publishing anything that takes personal data
- **Privacy policy** with the controller's identity, purposes, legal bases,
  recipients and processors, international transfers, retention and rights. The
  AEPD publishes a technical note aimed exactly at
  [mobile apps](https://www.aepd.es/guias/nota-tecnica-apps-moviles.pdf).
- **Records of processing** and **processor contracts** with Firebase/Google,
  RevenueCat and any ad network added later.
- **LSSI**: the website needs an identifying legal notice (identity, NIF, contact).
- **Children**: any age gate or guardian handling is a product decision that must be
  settled before, not after, a store asks.

### Consumer law and stores
- The **14-day withdrawal right** for digital content is only lost with the user's
  prior express consent and acknowledgement; blanket "no refunds" language is not
  enforceable.
- The store **commission** is 15 % under the small-business programmes for the first
  million, which is the real margin.
- **Ads, if they are ever added**, require a consent platform, no personalised ads
  without consent, and the privacy policy has to name the ad technology. The owner
  has already decided against ads on the website.

## What is deliberately not needed yet
Nothing in the register marked "Not needed yet" has to be bought or configured for
milestones 0 and 1: no EU hosting, no paid backend, no ad account, no legal
retainer. The expensive items belong to the milestone that needs them.
