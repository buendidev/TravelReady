# TravelReady — sitio público

Static multi-page site, Spanish-first: thirteen pages. No build step, no
JavaScript, no analytics, no cookies, no trackers, no external fonts or
CDNs, no deployment config and no `<img>` anywhere — the app screens and
the payment card are drawn with CSS. The one raster in the repository,
`og-card.png`, exists only for crawlers: no page requests it.

## Files

Thirteen pages — seven marketing pages with one search intent each, a
pricing page, a purchase-path page and four legal texts — plus the shared
stylesheet, the brand assets and the crawler files:

- `index.html` — what TravelReady is: hero with an app mockup, value
  strip, one-line summary of each of the six features (each linking to
  `funciones.html`), a quick guide linking to every other page and a
  one-line download call to action.
- `funciones.html` — the six features explained in prose, with the three
  app mockups (`capturas` is not a page: the mockups live here).
- `como-funciona.html` — the three steps, the first day with the app and
  what the user needs.
- `estado.html` — what already works, what is still pending, and the
  known limits.
- `faq.html` — recurring questions, including the ones the offline and
  beta limits raise.
- `descargar.html` — APK placeholder, requirements, install notes and
  the owner TODO.
- `contacto.html` — contact channel, and where the legal texts live.
- `precios.html` — what is free today, what the subscription will cover
  and the honest answer to "how much": no price exists yet, so none is
  published. Four `TODO(owner)` items, no invented number.
- `pago.html` — how a purchase will actually happen (store billing, or a
  processor's hosted page if a web checkout is ever built), the 14-day
  withdrawal right, and a CSS-drawn card that collects nothing.
- `aviso-legal.html`, `privacidad.html`, `terminos.html`, `cookies.html`
  — the four legal texts, published as **drafts**: each carries a visible
  `draft-notice` and the `TODO(owner)` markers for data only the owner can
  supply.
- `favicon.svg` — the brand mark, hand-authored vector.
- `og-card.svg` and `og-card.png` — the 1200×630 social card and its
  source; regeneration command under "Visual verification".
- `styles.css` — design tokens matching the app palette (`#006571`),
  light and dark schemes via `prefers-color-scheme`, responsive layout,
  `:focus-visible` rings, CSS-only motion (hero entrance, scroll-driven
  reveals, hover/focus micro-interactions) and a `prefers-reduced-motion`
  guard.
- `sitemap.xml` — the thirteen canonical URLs, no `lastmod` (there is no
  reliable date to put there).
- `robots.txt` — `Allow: /` plus one `Sitemap:` line.

## Pages

| Page | Content |
| --- | --- |
| `index.html` | Hero, value strip, feature one-liners, site guide, download CTA |
| `funciones.html` | Six features in prose, three screen mockups |
| `como-funciona.html` | Three steps, first day, requirements |
| `estado.html` | Working, pending and known limits |
| `faq.html` | Seven questions, answers honest about what is not ready |
| `descargar.html` | APK placeholder, requirements, install notes |
| `contacto.html` | Contact channel, where the legal texts live |
| `precios.html` | Free today versus the future subscription, no prices yet |
| `pago.html` | Two purchase routes, withdrawal right, CSS card |
| `privacidad.html` | Data, purposes, bases, processors, rights (draft) |
| `terminos.html` | Service, account, subscription, withdrawal (draft) |
| `cookies.html` | No cookies here, and what a checkout would add (draft) |
| `aviso-legal.html` | LSSI identifying data and liability (draft) |

Every page shares the same shell: a header `<nav class="site-nav">` with
the brand and two link lists carrying the same eight page links in the
same order (the current one carries `aria-current="page"` in both), and
a footer `<nav class="footer-nav">` with the same links in the same
order. The header lists are:

- `<details class="nav-disclosure">` with a
  `<summary class="nav-summary">Menú</summary>` — the small-screen menu.
  It ships closed and `<details>` opens it natively, so it needs no CSS
  at all to work.
- `<ul class="nav-links nav-links-desktop">` — the wide-screen list,
  hidden below 760 px with `display: none` (out of the accessibility
  tree and out of the tab order) and shown inline above 760 px, where
  the disclosure is not rendered at all.

Which of the two is visible is decided by one media query and `display`
alone: no `::details-content`, no `content-visibility`, no `[open]`
selector on the navigation — nothing engine-specific left to get wrong.
The two lists must not drift; `tool/check_landing.py` fails any page
where the header link lists differ in hrefs, order or which link carries
`aria-current="page"`.

## SEO

Each page has a unique `<title>` and a unique `<meta name="description">`
in Spanish, Open Graph tags (`og:title`, `og:description`, `og:type`), one
absolute `<link rel="canonical">`, one local `<link rel="icon">`, one
absolute `og:image` on the canonical's origin with its `width`, `height`
and `alt`, and a `twitter:card`. The canonical origin is the placeholder
`https://travelready.example` — no domain exists yet (see
`docs/production/owner-action-register.md`). No other URL in any page is
absolute, and the `og:image` file is a real 1200×630 PNG that the checker
decodes and measures, so a placeholder card cannot ship as if it worked.

## Preview locally

Any static server works — the site has zero dependencies:

```powershell
python -m http.server 8080 -d website
# → http://localhost:8080
```

Or just open `website/index.html` in a browser.

## Structural check

Run this after touching the site. It needs no dependencies and exits
non-zero on failure:

```powershell
python tool/check_landing.py
```

It checks the whole static site — every top-level `*.html` file in the
target directory (default `website`) — not just one page.

**Per page** it fails on what can break without a browser: duplicate
`id`s, unclosed or unexpectedly closed tags, any `<script>` element (the
site is JavaScript-free), any `<img>` element (the mockups are CSS), any
resource URL that starts with `http://`, `https://` or protocol-relative
`//` in `href` or `src` (the canonical is the one allowed absolute URL),
HTML classes with no rule in `styles.css`, and broken links:

- `#fragment` must match an `id` in the same page;
- `page.html` and `./page.html` must point at a file in the directory;
- `page.html#fragment` must point at an existing file **and** an `id`
  inside that page.

**Site-wide checks** run whenever the directory holds more than one page
and fail on: a page without exactly one non-empty `<title>`, one
`<meta name="description">` with content, one `<meta name="viewport">`,
one absolute `<link rel="canonical">` whose path is that page's own URL
on the origin, or the `og:title`, `og:description` and `og:type` meta
properties; two pages sharing a title or a description; canonicals with
different origins, or a canonical pointing at another page's URL;
missing or unparseable `sitemap.xml`, or a sitemap whose `<loc>` set does
not exactly match the canonical page URLs in either direction; missing
`robots.txt` or a `Sitemap:` line in it that does not point at the
sitemap on the canonical origin; header or footer navigation whose
ordered link list differs between pages; a page whose header link lists
differ from each other in hrefs or order, or whose `aria-current="page"`
sits on a different link in each of them; **one `h1` per page** — exactly
one `<h1>` element with non-empty text (the count found is reported when
it is wrong); **unique `h1` across pages** — two pages sharing the same
normalized `<h1>` text is a failure, naming the pages; and **no skipped
heading level** — walking the headings in document order, a heading more
than one level deeper than the previous one (an `h3` right after an
`h1`) fails, naming the jump and the heading text; and **repeated
prose**: the
normalized text of every `<p>` outside `<header>`, `<footer>` and
`<nav>` of 120 characters or more must not appear on two pages — the
deterministic guard for the no-duplicated-content rule (nav and footer
are exempt on purpose).

Four rules guard the identity, the assets and the legal texts, and each
exists because of a real incident or requirement. Every page must carry
exactly one local `<link rel="icon">` whose file exists. Every page must
carry exactly one `og:image`, absolute on its own canonical's origin,
resolving to a file in the site that, being PNG, decodes to 1200×630 with
agreeing `og:image:width`/`:height` metas and a non-empty `og:image:alt`.
Every file referenced by an `href` or `src`, plus every page listed in
`sitemap.xml`, must be **tracked by git** — `website/robots.txt` was once
swallowed by a `*.txt` ignore rule while every local run passed and a clean
clone would have failed; outside a git work tree that check degrades to an
`aviso:` instead of failing.

The four legal texts are a **launch gate**: they must exist, each must
carry exactly one non-empty `<p class="draft-notice">`, and every page must
link all four. When counsel approves the texts and the owner supplies the
identity data, the notice comes out and that rule is deliberately replaced:
it exists so that no draft can be published as if it were in force.

The rules are themselves covered by a suite:

```powershell
python -m unittest discover -s tool -p "*_test.py"
```

83 tests build throwaway sites in temporary directories and assert on the
message each rule emits, so a rule that silently disappears is caught. CI
runs the checker and then the suite (`.github/workflows/ci.yml`).

CSS rules that no page uses are reported as an `aviso:` warning, as is
a page between 28 and 40 KiB (the stylesheet between 32 and 40 KiB);
the hard caps are 40 KiB per page and for the stylesheet, which fail the
run. `aviso:` lines never fail the run by themselves.

## Motion (CSS only, no JavaScript)

All motion lives in `styles.css` and animates only `transform`,
`opacity` and paint-only properties — never anything that triggers
layout. Three guarantees, enforced by where the CSS is written:

1. **No content can be hidden by an unsupported engine.** Every zero or
   offset start state (`opacity: 0`, `translate`) is declared only inside
   `@media (prefers-reduced-motion: no-preference)` wrapping
   `@supports (animation-timeline: view())`. An engine without
   scroll-driven animations, or with motion reduced, parses none of it
   and paints every element in its final, fully visible state.
2. **Scroll reveals finish on screen.** The reveal
   `animation-range` is `entry 0% entry 50%`, so the animation completes
   once an element is half inside the viewport: anything more than half
   visible when the page loads is already at its end state.
3. **Reduced motion gets everything, static.** The
   `prefers-reduced-motion: reduce` block disables every animation and
   transition, and explicitly restores `opacity: 1` and
   `translate: none` for every element the guarded block offsets —
   scroll-driven animations ignore `animation-duration`, so they are
   disabled by name, not by duration.

Effects: a staggered hero entrance on load; reveals for section heads,
cards, steps, strip items, status columns/lists, page links, FAQ items
and CTA; card lift with a `:focus-within` equivalent; button press
feedback with a `:focus-visible` equivalent; a sliding underline on
footer nav links; a half-turn spin of the FAQ summary marker on open; a
soft shadow on the sticky header during the first 6 rem of scroll; a slow
3D turn of the payment card on `pago.html` (stilled by the reduce block
like every other effect); and brand-colored `::selection`.

## Pending owner content (marked in the HTML)

- **APK download** — the call to action on `descargar.html` is an honest
  disabled placeholder, not a fake link. Point it at a real artifact
  only when a signed APK exists.
- **Contact channel** — `TODO(owner)` in `contacto.html`.
- **The legal texts** are published as drafts. Before any of them can be
  declared in force: the owner's NIF, domicilio and a real contact address
  on `aviso-legal.html`, the rights channel on `privacidad.html`, the
  notifications channel on `terminos.html`, and counsel review of all four.
  Then remove the `draft-notice` paragraph from each and replace the
  checker's launch gate. Until then the checker refuses to let a draft pass
  as final.
- **The canonical origin** — every absolute URL on the site points at the
  placeholder `https://travelready.example`, because no domain exists yet;
  buying it is an owner action (see
  `docs/production/owner-action-register.md`). The placeholder appears in
  four kinds of place: the `<link rel="canonical">` of each of the
  thirteen pages, the identical `og:image` value on those pages, the
  thirteen `<loc>` entries in `sitemap.xml`, and the `Sitemap:` line in
  `robots.txt`. The social card deliberately carries no domain of its own,
  so buying one never forces the raster to be re-rendered. Replace the
  placeholder in those four places and then prove the replacement is
  complete rather than trusting it:

  ```powershell
  grep -rn "travelready.example" website/*.html website/sitemap.xml website/robots.txt
  # must print nothing
  python tool/check_landing.py
  # must exit 0
  ```

  A half-finished replacement cannot slip through: the checker fails when a
  page has no canonical, when two pages share a title or a description, when
  a canonical points at another page's own path, or when the sitemap and the
  canonicals disagree.

## Verification record

The site has been rendered and measured in a real browser engine (headless
Chromium on this machine), not only checked structurally. Two passes are
recorded: the thirteen-page one that added pricing, the purchase path, the
legal texts, the favicon and the social card, and the original seven-page
one below it.

### Thirteen-page pass

Measured over the DevTools protocol with `Emulation.setDeviceMetricsOverride`
per width — the narrow-window trap avoided — in real time, with the motion
arm proven in-page through `matchMedia`:

- **No horizontal overflow**: `scrollWidth == clientWidth` with a
difference of exactly `0`, on all thirteen pages at 320, 375 and 1440 px —
39 of 39.
- **The payment card fits**: 283.22 × 177 px at 320 px inside a 283 px
content box (0.22 px of sub-pixel bleed, no scroll overflow), 320 × 200 px
at 375 and 1440; it overflows neither its container nor the viewport.
- **No text is stranded at `opacity: 0`**: zero hits on all thirteen pages
at 320 and 1440 px, at the top and after scrolling to the bottom, with
reduced motion; and zero after scrolling with motion allowed. With motion
allowed *at the top* the below-fold elements still read `opacity: 0` before
their reveal, which is the design; a follow-up pass confirmed **none of
them lies inside the initial viewport**, so nothing visible on load is
hidden.
- **The card obeys reduced motion**: `animation-name: none`,
`animation-duration: 0s` and an empty `getAnimations()`; with motion
allowed, `tr-girar` at 9 s and running.
- **The header on the two new pages** (identical numbers for `precios.html`
and `pago.html`): 62.44 px collapsed at 375 px with 0 of 8 links reachable
and the desktop list at `display: none`; 241.59 px opened, 8 of 8
hit-testable and focusable; 60.97 px at 1440 px with the desktop list
inline, 8 of 8 hit-testable and focusable, and the disclosure not rendered.
- **Requests**: three for `index.html` (the page, `styles.css` and
`favicon.svg`) and two for every other page. `og-card.png` is never
requested by a page and serves 200 when fetched directly, as does
`favicon.svg`.
- **The legal footer works**: on `index.html` and `cookies.html` at 375 px,
`elementFromPoint` at the centre of each of the four links returns the
anchor itself — 8 of 8.

### Seven-page pass

The seven-page site has been rendered and measured in a real browser
engine (headless Chromium on this machine), not only checked
structurally. What is verified, with the numbers:

- **Text is never invisible.** Every element holding its own visible text
  was checked for `opacity: 0` behind the motion rules: **zero hits** on
  all seven pages at 320 and 1440 px, at the top of the page and after
  scrolling to the bottom, with reduced motion forced. With motion
  allowed, nothing inside the initial viewport is hidden, and nothing is
  left hidden after scrolling to the bottom, so no reveal strands a word.
- **The header, measured.** Collapsed on phones: **62.44 px** at 320, 375
  and 414 px, with the brand and the `Menú` pill on one row. Opened: the
  disclosure takes a full row and all seven links become clickable,
  284.78 / 241.59 / 198.41 px at those widths, and a second tap collapses
  it again. At 1440 px: 60.97 px, one inline row, seven reachable links.
  Re-verified after the two-list header replaced the forced-open
  disclosure: at 375 px the collapsed header is 62 px with the desktop
  list at `display: none` and unreachably by focus or click, the open
  header is 242 px with the disclosure on its own row and the links
  focusable and hit-testable; at 1440 px the header is 61 px with the
  disclosure not rendered and the desktop list inline, focusable and
  hit-testable. No horizontal overflow in any of those states.
- **No horizontal overflow** — `scrollWidth == clientWidth` — on all
  seven pages at 320, 375, 414, 600 and 1440 px, in both menu states.
- **Two HTTP requests per page**: the page itself and `styles.css`.
  Nothing else is fetched; the only 404 a browser produces is its own
  speculative `/favicon.ico`, which no page references. (Superseded by the
  thirteen-page pass, where `favicon.svg` is referenced and served.)
- **Keyboard**: with the menu collapsed, no tab stop reaches a nav link;
  with it open, all seven do. At 1440 px the summary leaves the tab order
  and the seven links are in it.
- **Focus**: the `:focus-visible` ring is present and identical with and
  without motion.
- **Both colour schemes** were rendered and inspected.

Not verified, and not rounded up:

- **Firefox and Safari.** Still not rendered on this machine. What
  changed is what they would have to get wrong: the desktop navigation
  now rests on nothing newer than a media query and `display` — the
  old reveal via `content-visibility` on `::details-content` is gone —
  and the absence of any engine-specific selector in `styles.css` is
  itself checked (`grep` in the verification record below). What an
  untested engine could still do with a plain media query has no
  evidence here either.
- **A real touch device.** The taps came from synthesized pointer and
  mouse events: no finger, no long-press, no double-tap.
- **Screen readers**, and the accessibility tree of the collapsed
  disclosure, were not inspected.
- Nobody has confirmed the copy against the shipped app beyond the
  features already implemented in this repository.

## Non-goals (by design)

No forms, no analytics, no cookies, no external assets, no hosting
config. A form would need a backend decision first: nothing here posts
data anywhere.

## Visual verification

**Preferred method**: drive Chrome over the DevTools protocol and set each
width with `Emulation.setDeviceMetricsOverride`, force the motion arm with
`Emulation.setEmulatedMedia`, and prove the arm inside the page with
`matchMedia('(prefers-reduced-motion: reduce)')`. That is exactly how the
thirteen-page pass above was measured: `python -m http.server 8123 -d
website` as the origin, no virtual time, 700 ms to settle after load and
800 ms after a scroll.

**Quick single shot** — fine for looking at 1440 px, and the three traps
that make a naive attempt lie about a narrow width:

```powershell
python -m http.server 8123 -d website
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu `
  --hide-scrollbars --no-first-run --force-device-scale-factor=1 `
  --user-data-dir=$env:TEMP\chrome-shot `
  --window-size=1440,900 --screenshot=build\screenshots\hero-desktop.png `
  http://localhost:8123/
```

- **Geometry does not prove that anything is painted.** A closed
  `<details>` in Chromium keeps layout boxes for its content: with the
  reveal rule disabled, all seven nav links still report 59-126 × 37.6 px
  while painting nothing, absorbing no click and taking no focus. Test
  reachability with `document.elementFromPoint(x, y)` and by calling
  `focus()`, never by measuring a rectangle.
- **`--virtual-time-budget` is not trustworthy here.** Under virtual time,
  scroll-driven `view()` timelines are not re-sampled after a programmatic
  scroll, so elements falsely read `opacity: 0`. Render in real time — a
  scratch endpoint that delays the `load` event keeps frames flowing while
  `--dump-dom` waits — and force the motion preference explicitly
  (`--force-prefers-reduced-motion` against
  `--blink-settings=prefersReducedMotion=false`), proving the arm you got
  with `matchMedia`.
- **A narrow `--window-size` is a trap on Windows.** Chrome silently keeps
  a layout viewport of roughly 500 px or more, so a 320 px screenshot is a
  crop of a wider layout that looks like a layout bug. Measure inside a
  same-origin full-width `<iframe>`, or drive the browser over the DevTools
  protocol with `Emulation.setDeviceMetricsOverride`.

Regenerate the social card from its source, with a throwaway profile
because a running Chrome holds the default one (from Git Bash, `$TEMP` is
not a Windows path: build the URL with `cygpath -m "$TEMP"`, or Chrome
answers `net::ERR_FILE_NOT_FOUND`):

```powershell
# og-wrap.html is a throwaway page in the system temp directory:
#   <img src="file:///…/website/og-card.svg" width="1200" height="630">
#   with html,body{margin:0;padding:0;overflow:hidden}
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new `
  --disable-gpu --hide-scrollbars --force-device-scale-factor=1 `
  --window-size=1200,630 --user-data-dir=$env:TEMP\chrome-ogcard `
  --screenshot="C:\Users\buendidev\Documents\GitHub\TravelReady\website\og-card.png" `
  "file:///<temp>/og-wrap.html"
```

Delete the wrapper and the profile afterwards. A `…\Temp\chrome-*` profile
that refuses to delete (`LOCK`, WinError 5) is harmless residue: the
checker only cares about files inside the repository.
