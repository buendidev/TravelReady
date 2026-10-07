# Website professional (milestone 0)

Feature document. Owner-authorized work; every task closes with one work-unit
commit on `feat/website-professional`.

## Why

The site is seven marketing pages that are structurally verified but visibly
unfinished: no favicon, no social card, no pricing, no purchase path and no
legal pages. All of it is milestone 0 of `docs/production/launch-plan.md` —
"what can be finished without the owner" — and all of it is what a first
visitor sees.

## In scope

| Unit | Deliverable |
| --- | --- |
| WPRO-1 | Brand assets (favicon, OG card) and the head plumbing on the seven existing pages |
| WPRO-2 | Checker rules for assets/`og:image`/ignored files + Python test suite + CI step |
| WPRO-3 | Four legal pages (`aviso-legal`, `privacidad`, `terminos`, `cookies`) and the footer legal navigation |
| WPRO-4 | `precios.html` and its navigation entry on every page |
| WPRO-5 | `pago.html`: the checkout page with the animated card, CSS only |
| WPRO-6 | Real-engine render verification and documentation |

## Out of scope (non-goals)

- No payment processor, no RevenueCat configuration, no product identifiers:
  the purchase path is described, never simulated.
- No JavaScript on any page. The checker bans `<script>` outright and this
  feature keeps that ban absolute, so no per-page JS policy is introduced.
- No card-input fields anywhere: collecting card data without a processor is a
  PCI-DSS trap and a lie while no checkout exists.
- No analytics, no cookies, no cookie banner (the site sets no cookies).
- No domain swap, no hosting, no legal identity data: owner actions.

## Constraints that are not negotiable

1. `python3 tool/check_landing.py` is the CI gate (`.github/workflows/ci.yml`);
   it must stay green at every commit.
2. Exactly one non-empty `<h1>` per page, unique across pages; no skipped
   heading levels; unique `<title>` and `description` per page.
3. No `<p>` of 120 characters or more may repeat across two pages (the
   repeated-prose rule), so legal boilerplate must be genuinely per-page.
4. Every HTML class used must have a CSS rule, or the checker reports it.
5. The header carries **two** identical nav lists and the footer one; the
   checker compares them against `index.html`, so a nav change touches every
   page in the same commit.
6. Byte budgets: HTML fails above 40 KiB; CSS warns above 32 KiB and fails
   above 40 KiB (`styles.css` is at 29 KiB when this feature opens).
7. `.gitignore` swallows `*.txt` (only `website/robots.txt` is exempt) and
   `*.pdf`. No image extension is ignored.
8. **No third-party code without a license.** `paymorph-html` ships no license
   text at all (`grep -rilE "license|copyright|©"` → 0 matches), so it is not
   vendored into a repository that will be published. The animated card is
   authored here with the site's own tokens.

## Tasks

### WPRO-1 — Assets and head plumbing

- `website/favicon.svg`: the brand mark, drawn as vector, brand colour.
- `website/og-card.svg` (source) and `website/og-card.png` (1200×630, rendered
  from the source with headless Chrome; the command is recorded in
  `website/README.md`).
- All seven pages gain: `<link rel="icon" href="favicon.svg" type="image/svg+xml">`,
  `og:image` (absolute, on the canonical origin), `og:image:width`/`:height`,
  `og:image:alt` and `twitter:card=summary_large_image`.

Evidence: checker green; PNG decodes to 1200×630; both assets present in
`git ls-files`.

### WPRO-2 — Checker: assets, social card, ignored files

- New rules: every page has exactly one `<link rel="icon">` whose target exists;
  every page has `og:image` absolute on the same origin as its canonical and
  pointing at an existing file that decodes to 1200×630; every locally
  referenced asset and every `.html` in `sitemap.xml` is tracked by git, so an
  ignored-but-referenced file fails the gate (the `website/robots.txt` lesson,
  generalised).
- `tool/check_landing_test.py`: `unittest`, fixture sites in temporary
  directories, one test per rule plus one per existing rule that the new code
  could regress. Observed RED before the rules land, GREEN after.
- `.github/workflows/ci.yml`: run the Python suite next to the checker.

### WPRO-3 — Legal pages

Four pages, each one `<h1>`, unique title/description/canonical, a visible
draft notice (`.draft-notice`) stating that the page is not in force yet, and
`TODO(owner)` placeholders for the identity, NIF, address and contact data
(LSSI). Content sources: `docs/legal/privacy-terms-requirements.md`,
`docs/legal/data-retention-rights.md` and the legal annex of the launch plan.
The footer gains a legal navigation reachable from every page. Checker gains:
the four pages exist, carry the draft notice and the required section
headings, and appear in the sitemap.

### WPRO-4 — Pricing

`precios.html` with the free and premium tiers, what each includes, the real
store-commission context and an explicit "not purchasable yet" state, because
no store products exist. Added to both header lists and the footer nav on
every page, and to the sitemap.

### WPRO-5 — Checkout page

`pago.html` explains the two real purchase routes (in-app store billing; the
processor's hosted fields for a future web checkout), states the withdrawal
conditions, and carries the animated card as a decorative CSS-only visual
under the existing `prefers-reduced-motion` double guard, disabled by name in
the reduce block. No inputs, no JS, no stored card data.

### WPRO-6 — Verification and documentation

- Real-engine pass: every page at 320/375/1440, motion arm and reduced-motion
  arm, no horizontal overflow, zero text stuck at `opacity: 0`, favicon and
  `og:image` served 200, request count per page recorded.
- Update `website/README.md` (page map, asset list, regeneration command, JS
  policy, verification record), `docs/production/launch-plan.md` (milestone 0
  state) and `docs/production/owner-action-register.md` (PayMorph written
  licence, legal identity data before the legal pages go live).

## Decisions and risks

- **PayMorph is not vendored** (see constraint 8). The animated card is our own
  CSS; obtaining written terms from infiwebcraft stays an owner action, and the
  component must not be embedded in the app either.
- **Legal pages are drafts by design.** The checker requires the draft notice
  so that a page without identity data cannot be published silently.
- Cross-engine behaviour of the desktop navigation remains Chromium-only
  evidence; this feature does not touch it.
- Firefox and Safari are not installed here: the render pass is Chromium, and
  the claim stays scoped to it.

## Commits

| Unit | Commit | What |
| --- | --- | --- |
| WPRO-1 | `237874f` | Brand assets and the head plumbing on the seven pages (doc: `9faa1a0`) |
| WPRO-2a | `f0e5640` | 52-test unittest harness for the checker plus the CI step |
| WPRO-2b | `1bfa65e` | Icon, social-card and ignored-file rules (74 tests) |
| WPRO-3a | `5f23a1e` | The four legal pages, the sitemap entries and the `.draft-notice` rule |
| WPRO-3c | `74bdf33` | The footer links every page, and two pages stop contradicting the drafts |
| WPRO-3b | `4e2383c` | Launch gate for the legal texts (83 tests) |
| WPRO-4 | `f530aa9` | `precios.html` and its entry in both header lists and the footer nav |
| WPRO-5 | `94a0801` | `pago.html`, the purchase-path copy and the CSS-only animated card |

## Open questions for the owner

- **The card animation never stops.** `pago.html`'s illustration runs a 9-second
  3D flip `infinite` inside the site's motion guard. It is honest decoration and
  it is stilled by the reduce block, but an endless animation costs battery and
  draws the eye on a page whose message is "you cannot pay here". Cheaper
  alternatives are a single entrance turn or a flip on hover/focus. Left as the
  owner's taste decision rather than changed unilaterally.
- **`styles.css` is 31 897 bytes**, 871 bytes under the checker's 32 KiB warning.
  The next visual addition trips the aviso: either raise the threshold
  deliberately, with a reason, or trim the stylesheet.
- **PayMorph:** its written licence from infiwebcraft is still an owner action.
  Nothing of it is vendored, so nothing blocks the site today.

## Log

- **WPRO-3** — the four legal texts landed in two commits (content, then the
  links and the two pages that still claimed the texts were unpublished). The
  checker grew a launch gate for them. Verified with my own probe on real
  content: emptying a notice and dropping a link each produced exactly one
  failure and exit 1.
- **WPRO-4/5** — `precios.html` and `pago.html`. Neither invents anything: four
  `TODO(owner)` items on the pricing page (two amounts, the product identifiers,
  the final free-versus-subscription split) and the checkout page explains the
  two real purchase routes and carries no field, no price and no button. The
  checker refused a mid-work defect on its own: the word `html` inside a CSS
  comment created a phantom declared class and an unused-rule aviso.
- **WPRO-1** — `favicon.svg`, `og-card.svg`, `og-card.png` (1200×630, 196 907
  bytes, rendered from the source with headless Chrome using a throwaway
  profile) and the icon plus `og:image` block on all seven pages. The worker's
  first render failed with `net::ERR_FILE_NOT_FOUND` because Git Bash's `$TEMP`
  is not a Windows path: the wrapper URL needs `cygpath -m`. The card carries
  no domain on purpose, so buying the real domain never requires re-rendering
  the raster. Retry this recipe rather than rediscovering it.
- **WPRO-2a** — `check_directory(directory)` extracted from `main()`; the CLI
  output was diffed against the previous revision and is byte-identical, so the
  gate's behaviour is unchanged. 52 tests, 69 assertions, message-level
  assertions against the real entry point.
- **WPRO-2b** — three rules, each written test-first with its own RED run:
  the icon, the social card (absolute, same origin as the canonical, PNG that
  decodes to 1200×630 with agreeing `width`/`height` metas and a non-empty
  `alt`) and the ignored-but-referenced file. The third generalises the
  `website/robots.txt` incident: it asks git once per run for the tracked set
  and degrades to an `aviso:` outside a work tree. Suite grew 52 → 74 tests.
  Verified against real content, not only fixtures: a copied site inside the
  repository with one injected defect per rule returned exit 1 with exactly
  one message per rule, while the real site stayed at exit 0.
- **WPRO-6** — real-engine pass over the DevTools protocol: 39/39 widths
  with no horizontal overflow, zero text at `opacity: 0` in the
  reduced-motion arm on all thirteen pages, the payment card contained at
  320 px and stilled when motion is reduced, the header on the two new pages
  62.44 px collapsed and 8 of 8 links reachable open, three requests on
  `index.html` and two elsewhere, and the four legal footer links
  hit-testable. Recorded in `website/README.md`.
- **Open design question** for the owner: the card's 9-second turn is
  `infinite`. It obeys reduced motion and costs nothing else, but an endless
  animation is a taste and battery decision, not a technical one.
- Opened after the owner chose milestone 0 over the repository cleanup and the
  RDD review fork. Bundle and the pre-rewrite repository contents were deleted
  with the owner's authorization; the academic PDFs stay in
  `Documents/TravelReady-fuera-del-repo/`.
