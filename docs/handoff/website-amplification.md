# Website — amplify, do not rewrite

Owner decision (2026-10-09): the site is **amplified**, not rewritten, and not
handed over as a green-field job.

## 1. What exists (verified)

- `website/`: thirteen static pages — `index.html`, `funciones.html`,
  `como-funciona.html`, `precios.html`, `pago.html`, `descargar.html`, `faq.html`,
  `estado.html`, `contacto.html`, plus `privacidad.html`, `cookies.html`,
  `terminos.html`, `aviso-legal.html` — with one `styles.css`, `favicon.svg`,
  `og-card.png/svg`, `robots.txt`, `sitemap.xml` and a `README.md` that records
  the verification.
- **Zero first-party JavaScript**, no trackers, no framework. ES-first,
  responsive, skip link, ARIA, reduced-motion and dark-scheme handling.
- A **structural checker plus an 83-test suite** run in CI, and a real-engine pass
  (Chromium) recorded in `website/README.md`.
- Known open engineering question: the inline desktop navigation relies on
  `content-visibility: visible` over `::details-content` and was only verified in
  Chromium. Firefox and Safari were not testable in that environment; where the
  technique fails, the header falls back to a clickable `Menú`.

**Why a rewrite is the wrong move:** the current site is verified, cheap and
hostable anywhere. Replacing verified HTML/CSS with a framework trades that for
build tooling, dependencies and a CI story that would have to be rebuilt — a
downgrade in verifiability for a site that has nine content pages and no dynamic
requirement yet.

## 2. Rules for any change here

1. The structural checker and its test suite must stay green. Extend the checker
   with a test when a new rule is introduced; do not weaken a rule to fit markup.
2. No framework, no bundler, no build step. Static files that work from a plain
   web server.
3. No third-party JavaScript, no analytics, no trackers, no external fonts, no
   CDN dependency required for the page to render. Progressive enhancement only.
4. Every page keeps: a skip link, a single `h1`, labelled landmarks, `lang`
   attributes, keyboard reachability, visible focus, and the reduced-motion and
   dark-scheme behaviour.
5. **Absolute URLs follow `website/README.md`.** The site is written against the
   placeholder origin `https://travelready.example`; the replacement procedure
   and its completeness proof are recorded there. Any new page must respect it.
6. Accessibility and copy are reviewable artifacts: no invented legal text, and
   no claim that the app or the site cannot back up.

## 3. Work that can be done today (no owner account, no blocker)

- **Cross-engine verification of the desktop navigation.** Run the existing
  checker and a manual pass in Firefox and Safari (or WebKit), and either confirm
  the `content-visibility` technique or harden the `Menú` fallback so it is
  correct on both. This is the one item here with real engineering value and no
  dependency.
- **English version** of the public pages (the app already ships `app_en.arb`;
  the site is ES-only). Decide the URL shape first (`/en/...` vs `en.*`), keep one
  canonical per language, and extend the sitemap and the checker's link rules.
- **Content and SEO polish**: per-page meta descriptions, Open Graph per page
  where it matters, a real 404 page, and consistent `precios.html` →
  `pago.html` → `descargar.html` flow copy.
- **Accessibility pass**: automated structure checks already exist; add the
  human checks the register still lists as not verified (screen reader over the
  collapsed disclosure, a real touch device).
- **Fix the `TODO(owner)` placeholders in one place** so they are enumerable:
  contact address, legal identity and the APK link must all come from a single
  documented list rather than being scattered in markup comments.

## 4. Work that is owner-blocked (do not start it, and do not fake it)

| Item | Blocked on |
| --- | --- |
| Legal notice with real identifying data (LSSI) | Owner's NIF/address |
| Real contact channel | Owner's address or form |
| Real APK link | Signed release artifact (keystore missing) |
| Going public | Domain, hosting, and the placeholder-origin replacement |
| Web checkout for the subscription | Milestone 2: processor account with **hosted fields** (never a card form of our own, never card data on our servers), plus fiscal registration |
| Privacy policy as published text | The LLM provider decision (see `ai-assistant-llm.md`) changes what it must disclose |

## 5. Verification required for any change here

- Structural checker green, 83-test suite green (extended, not reduced).
- `python -m html.parser`-style parse clean, or the checker's equivalent.
- A recorded real-engine pass for the pages touched, in `website/README.md`, the
  way the previous pass was recorded.
- No new external origin in the markup. Grep for `http://` and `https://` and
  justify every hit in the change.
