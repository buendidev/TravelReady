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

Run this after touching the page. It needs no dependencies and exits
non-zero on failure:

```powershell
python tool/check_landing.py
```

It verifies what can break without a browser: duplicate ids, anchors that
point nowhere, classes used in the markup with no rule in the stylesheet,
unbalanced braces, leaked external resources, and stray `<script>` or
`<img>` tags. It also reports unused CSS rules as a warning.

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
