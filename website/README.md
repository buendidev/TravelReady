# TravelReady landing

Static landing page, Spanish-first. No build step, no JavaScript, no
analytics, no cookies, no trackers, no external fonts or CDNs, no images
and no deployment config. The app screens shown on the page are drawn
with CSS, so there is nothing to host besides these two files.

## Files

- `index.html` — semantic markup: skip link, sticky header, hero with an
  app mockup, value strip, six feature cards, three steps, three screen
  mockups, an honest ready-versus-pending product status, a native
  `<details>` FAQ, the download block and the owner placeholders.
- `styles.css` — design tokens matching the app palette (`#006571`),
  light and dark schemes via `prefers-color-scheme`, responsive layout,
  `:focus-visible` rings and a `prefers-reduced-motion` guard.

## Sections

| Anchor | Content |
| --- | --- |
| `#inicio` | Hero, claims and the itinerary mockup |
| `#funciones` | Six feature cards |
| `#como-funciona` | Three steps |
| `#capturas` | Equipaje, descubrimiento and viajes mockups |
| `#estado` | What already works and what is still pending |
| `#faq` | Five questions, answers honest about what is not ready |
| `#descargar` | APK placeholder and the owner TODO |
| `#contacto` | Contact and privacy placeholders |

The header and footer navigation point at those sections.

## Preview locally

Any static server works — the page has zero dependencies:

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
`//` in `href` or `src`, HTML classes with no rule in `styles.css`, and
broken links:

- `#fragment` must match an `id` in the same page;
- `page.html` and `./page.html` must point at a file in the directory;
- `page.html#fragment` must point at an existing file **and** an `id`
  inside that page.

Missing files and dangling fragments are reported separately, naming the
offending page. CSS rules that no page uses are reported as an `aviso:`
warning, not a failure.

**Site-wide checks** activate only when the directory contains more than
one page; with a single page the checker prints one `aviso:` and skips
them, so today's setup stays green. When active, all of the following
are failures: a page without exactly one non-empty `<title>`, one
`<meta name="description">` with content, one `<meta name="viewport">`,
one absolute `<link rel="canonical">` whose path is that page's own
URL on the origin, or the `og:title`, `og:description` and `og:type`
meta properties; two pages sharing a title or a description; canonicals
with different scheme+host origins, or a canonical pointing at another
page's URL;
missing or unparseable `sitemap.xml`, or a sitemap whose `<loc>` set
does not exactly match the canonical page URLs (`index.html` as the
origin root, every other page as `name.html`) in either direction;
missing `robots.txt` or a `Sitemap:` line in it that does not point at
the sitemap on the canonical origin; and header (`<nav>`) or footer
navigation whose ordered list of links differs between pages.

**Weight budget:** every HTML page is capped at 40 KiB and `styles.css`
at 40 KiB (hard failure); exceeding 28 KiB per page or 32 KiB for the
stylesheet prints an `aviso:` warning before the hard limit is reached.

## Pending owner content (marked in the HTML)

- **APK download** — the call to action is an honest disabled
  placeholder, not a fake link. Point it at a real artifact only when a
  signed APK exists.
- **Contact channel** — `TODO(owner)` in `#contacto`.
- **Privacy policy and legal notice** — `TODO(owner)` in `#contacto` and
  in the footer. Do not publish without them.

## Pending verification

- **No browser or device render has been done.** Layout, contrast,
  focus order, the dark scheme and the phone mockups still need a real
  look in a browser and on a phone. The structural check above does not
  replace that.
- Nobody has confirmed the copy against the shipped app beyond the
  features already implemented in this repository.

## Non-goals (by design)

No forms, no analytics, no cookies, no external assets, no hosting
config. A form would need a backend decision first: nothing here posts
data anywhere.

## Visual verification

The page has been rendered and inspected in a real browser engine, not
only checked structurally:

```powershell
python -m http.server 8123 -d website
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu `
  --hide-scrollbars --no-first-run --force-device-scale-factor=1 `
  --user-data-dir=$env:TEMP\chrome-shot --virtual-time-budget=5000 `
  --window-size=1440,900 --screenshot=build\screenshots\hero-desktop.png `
  http://localhost:8123/
```

What that verified:

- **Desktop at 1440 px in both colour schemes.** The host OS selects the
  dark scheme; the light one was rendered by temporarily disabling the
  dark block and then restoring the file byte for byte.
- **Mobile at 320, 375 and 414 CSS pixels with no horizontal overflow**:
  `scrollWidth == clientWidth` in every case. This was measured inside a
  full-width `<iframe>`, because Chrome headless on Windows refuses to
  honour a window narrower than roughly 500 px and silently keeps a wider
  layout viewport, which produces cropped screenshots that look like a
  layout bug.
- **The mobile menu wraps onto two rows** instead of hiding links behind a
  horizontal scroll strip.

Still not verified: a real touch device, Safari and Firefox, and the copy
against a released build.
