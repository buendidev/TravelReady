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

## Pending verification

- **A headless Chrome render was done for the old single-page site**
  (see *Visual verification* below), but the **new seven-page layout has
  not been rendered anywhere yet**: the split changed the header (a
  `<details>` menu instead of a wrapping link strip), and no page of the
  new set has been looked at in a browser engine, on a real touch
  device, in Safari or in Firefox.
- Nobody has confirmed the copy against the shipped app beyond the
  features already implemented in this repository.

## Non-goals (by design)

No forms, no analytics, no cookies, no external assets, no hosting
config. A form would need a backend decision first: nothing here posts
data anywhere.

## Visual verification

The **previous single-page site** was rendered and inspected in a real
browser engine, not only checked structurally:

```powershell
python -m http.server 8123 -d website
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu `
  --hide-scrollbars --no-first-run --force-device-scale-factor=1 `
  --user-data-dir=$env:TEMP\chrome-shot --virtual-time-budget=5000 `
  --window-size=1440,900 --screenshot=build\screenshots\hero-desktop.png `
  http://localhost:8123/
```

What that verified, on the single-page site before the split:

- **Desktop at 1440 px in both colour schemes.** The host OS selects the
  dark scheme; the light one was rendered by temporarily disabling the
  dark block and then restoring the file byte for byte.
- **Mobile at 320, 375 and 414 CSS pixels with no horizontal overflow**:
  `scrollWidth == clientWidth` in every case. This was measured inside a
  full-width `<iframe>`, because Chrome headless on Windows refuses to
  honour a window narrower than roughly 500 px and silently keeps a wider
  layout viewport, which produces cropped screenshots that look like a
  layout bug.
- **The mobile menu wrapped onto two rows** instead of hiding links
  behind a horizontal scroll strip. The split replaced that strip with
  the `<details>` disclosure, so this result no longer describes the
  current header.

Still not verified: any page of the current seven-page site in a browser
engine, a real touch device, Safari and Firefox, and the copy against a
released build.
