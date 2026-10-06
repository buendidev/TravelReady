# TravelReady — sitio público

Static multi-page site, Spanish-first. No build step, no JavaScript, no
analytics, no cookies, no trackers, no external fonts or CDNs, no images
and no deployment config. The app screens shown on the site are drawn
with CSS, so there is nothing to host besides these files.

## Files

Seven pages, one search intent each, plus the shared stylesheet and the
crawler files:

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
- `contacto.html` — contact, privacy and legal placeholders.
- `styles.css` — design tokens matching the app palette (`#006571`),
  light and dark schemes via `prefers-color-scheme`, responsive layout,
  `:focus-visible` rings, CSS-only motion (hero entrance, scroll-driven
  reveals, hover/focus micro-interactions) and a `prefers-reduced-motion`
  guard.
- `sitemap.xml` — the seven canonical URLs, no `lastmod` (there is no
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
| `contacto.html` | Contact, privacy and legal placeholders |

Every page shares the same shell: a header `<nav class="site-nav">` with
the brand and the seven page links (the current one carries
`aria-current="page"`), and a footer `<nav class="footer-nav">` with the
same links in the same order. On small screens the header links sit
inside `<details class="nav-disclosure" open>` with a
`<summary class="nav-summary">Menú</summary>`; because `open` is in the
markup the links are visible without any JavaScript, and CSS only hides
the summary from 760 px up.

## SEO

Each page has a unique `<title>` and a unique `<meta name="description">`
in Spanish, Open Graph tags (`og:title`, `og:description`, `og:type`) and
one absolute `<link rel="canonical">`. The canonical origin is the
placeholder `https://travelready.example` — no domain exists yet (see
`docs/production/owner-action-register.md`); when the real domain is
bought, one find-and-replace across these files is the whole migration.
No other URL in any page is absolute.

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
ordered link list differs between pages; **one `h1` per page** — exactly
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
soft shadow on the sticky header during the first 6 rem of scroll; and
brand-colored `::selection`.

## Pending owner content (marked in the HTML)

- **APK download** — the call to action on `descargar.html` is an honest
  disabled placeholder, not a fake link. Point it at a real artifact
  only when a signed APK exists.
- **Contact channel** — `TODO(owner)` in `contacto.html`.
- **Privacy policy and legal notice** — `TODO(owner)` in
  `contacto.html` and in the footer. Do not publish without them.
- **The canonical origin** — every absolute URL on the site points at the
  placeholder `https://travelready.example`, because no domain exists yet;
  buying it is an owner action (see
  `docs/production/owner-action-register.md`). The placeholder appears in
  exactly three kinds of place: the `<link rel="canonical">` of each of
  the seven pages, the seven `<loc>` entries in `sitemap.xml`, and the
  `Sitemap:` line in `robots.txt`. When the real domain exists, replace it
  in those three places and then prove the replacement is complete rather
  than trusting it:

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
- **No horizontal overflow** — `scrollWidth == clientWidth` — on all
  seven pages at 320, 375, 414, 600 and 1440 px, in both menu states.
- **Two HTTP requests per page**: the page itself and `styles.css`.
  Nothing else is fetched; the only 404 a browser produces is its own
  speculative `/favicon.ico`, which no page references.
- **Keyboard**: with the menu collapsed, no tab stop reaches a nav link;
  with it open, all seven do. At 1440 px the summary leaves the tab order
  and the seven links are in it.
- **Focus**: the `:focus-visible` ring is present and identical with and
  without motion.
- **Both colour schemes** were rendered and inspected.

Not verified, and not rounded up:

- **Firefox and Safari.** The inline desktop navigation is revealed by
  `content-visibility: visible` on `::details-content`, which is the rule
  that does the work in Chromium; the companion `display` rule is inert
  there. On an engine where the reveal fails, the fallback is a clickable
  `Menú` in the header: usable, but visibly different from Chrome and
  Edge.
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

How to render it again, and the three traps that make a naive attempt
lie about it:

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
