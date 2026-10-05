# TravelReady landing

Static landing page (Spanish-first). No build step, no JS, no
analytics/cookies/trackers, no deployment config.

## Files

- `index.html` — semantic markup, skip-link, `aria` where needed.
- `styles.css` — design tokens matching the app palette
  (`#006571` primary), dark-mode via `prefers-color-scheme`,
  reduced-motion via `prefers-reduced-motion`, responsive grid.

## Preview locally

Any static server works — the page has zero dependencies:

```powershell
# Python (bundled with most setups)
python -m http.server 8080 -d website
# → http://localhost:8080
```

or just open `website/index.html` in a browser.

## Pending owner content (marked in the HTML)

- **APK download** — the CTA is a disabled placeholder, not a fake
  link. Point it at a real artifact only when a signed APK exists.
- **Contact channel** — `TODO(owner)` in `#contacto`.
- **Privacy policy** — `TODO(owner)` in `#contacto`. Do not publish
  without it.

## Non-goals (by design)

No forms, no analytics, no cookies, no external fonts/CDNs, no
hosting config. If a form is ever added it needs a backend decision
first — nothing here posts data anywhere.
