# Website: multi-page, SEO and motion

## Objective
The public website stops being a single page and becomes a small, fast,
indexable multi-page site with real motion, without giving up the
constraints the owner already fixed: no JavaScript, no cookies, no
analytics, no external fonts, CDNs or images.

## Evidence
Owner request, recorded in the pending-tasks memory entry (2026-10-05):
"añadir animaciones y efectos para que sea más llamativa", "dejar de ser
una sola página: varias páginas para mejor posicionamiento", "que cargue
muy rápido y optimizada".

Current state measured in the repository: `website/index.html` is 441
lines / 18.888 bytes and carries eight anchors (`#inicio #funciones
#como-funciona #capturas #estado #faq #descargar #contacto`) in one
document, so every section shares one title, one description and one URL:
nothing separates the "what is it", "how it works" and "download"
intents. `website/styles.css` is 813 lines / 22.009 bytes. There is no
`robots.txt`, no `sitemap.xml` and no `rel="canonical"`.

`tool/check_landing.py` reads exactly two files (`index.html`,
`styles.css`) and is wired into CI (`.github/workflows/ci.yml`, step
"Check landing page structure"). It already forbids `<script>`, `<img>`
and external URLs, so the no-JavaScript constraint is enforced, not just
documented. Any split into several pages therefore has to teach the
checker about the new shape first, or CI goes red.

## Scope
- `tool/check_landing.py`: from single-page reader to site checker.
- `website/*.html`: split into per-intent pages sharing one stylesheet.
- `website/sitemap.xml`, `website/robots.txt`: new.
- `website/styles.css`: new tokens for navigation and motion only; no
  dependency, no external asset.
- `website/README.md`, `docs/production/owner-action-register.md`: the
  canonical origin is an owner action, and the register has to say so.
- `.github/workflows/ci.yml` is **not** touched: the checker keeps its
  path and CLI, so the existing step keeps working.

## Non-goals
- No JavaScript, no analytics, no cookies, no forms, no backend, no
  deployment config. A CSS-only mobile menu substitutes for the script a
  normal site would use.
- No new image or font asset: the app mockups stay drawn with CSS.
- Nothing is published: the tree stays local, the domain stays an owner
  action.

## Page map

Seven pages, one search intent each, Spanish, sharing one stylesheet:

| Page | Intent | Content |
| --- | --- | --- |
| `index.html` | what TravelReady is | hero, value strip, short summary of the three pillars and the six features with links, a link grid to every other page, one-line download call to action |
| `funciones.html` | what it does, in detail | the six features explained in prose, with the three app mockups illustrating them |
| `como-funciona.html` | how it is used | the three steps, the first day with the app, and what the user needs |
| `estado.html` | how far the project is | what already works, what is pending, known limits |
| `faq.html` | recurring questions | the current questions plus the ones the offline and beta limits raise |
| `descargar.html` | getting the app | APK placeholder, requirements, install notes, owner TODO |
| `contacto.html` | reaching the owner | contact, privacy and legal placeholders |

No block of prose is repeated verbatim between pages: a page that needs
to mention another's topic links to it with one line instead of copying
the section. `capturas.html` was dropped as a separate page because three
bare mockups are thin content; they belong where they illustrate the
features.

## Constraints confirmed

- **No JavaScript.** The owner's standing constraint is kept, not reopened:
the site stays CSS-only, which is a strict subset of the request. Motion is
therefore CSS-only, and the mobile menu is a `<details>` disclosure.
- **Canonical origin** is a single placeholder, `https://travelready.example`,
because no domain exists yet (`docs/production/owner-action-register.md`
lists the domain purchase as "Not needed yet"). One find-and-replace when
the domain exists, and the checker proves the replacement is complete.

## Tasks
- [x] WSP-1: Generalize the structural checker to a site with several pages.
- [x] WSP-2: Split the page per intent with unique metadata, canonical, sitemap and robots.
- [x] WSP-2b: Repair the two defects review found in WSP-2 (the ignored `robots.txt`, the six pages without an `h1`) and gate them in the checker.
- [x] WSP-3: Add CSS-only motion and effects behind a reduced-motion guard.
- [x] WSP-4: Verify structurally and in a real browser engine, and measure page weight.
- [x] WSP-5: Document the origin placeholder as an owner action.
- [x] WSP-6: Collapse the header menu on small screens (owner decision).
- [x] WSP-7: Verify the collapsed header and the desktop reveal in a real engine, and repair the header height the first pass exposed.

## Acceptance
Every page carries a unique `<title>` and meta description, a canonical
URL on one shared origin, Open Graph tags and a viewport; `sitemap.xml`
lists exactly the pages that exist; `robots.txt` points at the sitemap;
the header and footer list the same links in the same order on every
page; every cross-page link resolves to a file that exists and every
fragment resolves to an id in its target page. No page contains
`<script>`, `<img>` or an external URL. Motion is present but disabled
under `prefers-reduced-motion: reduce`, and no content is unreachable
when a scroll-driven animation is unsupported. `python
tool/check_landing.py` exits 0 and reports no unclosed tags, dangling
anchors, unstyled classes or unbalanced braces.

## Review findings (recorded per unit, as they are found)

### Review of WSP-2, before committing it

- **`website/robots.txt` was ignored by git.** `.gitignore` line 97 is `*.txt`
with a `!docs/*.txt` exception, so the new file existed on disk, the checker
read it, and the commit would have shipped without it — CI would then fail at
the missing-`robots.txt` check on a fresh clone while passing locally. Fixed by
the parent with `!website/robots.txt`; `.gitignore` is a surface the writer did
not have. `git status` now lists `website/robots.txt` as untracked.
- **Six of the seven pages had no `<h1>`.** Only `index.html` had one; the
others started at `<h2>`, and `estado.html` additionally skipped a level
(`h1`-less `h2` followed directly by `h3` columns). A page whose whole point is
to rank for one intent cannot start at `h2`. Repair in flight as WSP-2b, with
two new site-wide rules (one non-empty `h1` per page, `h1` unique across pages)
and a third one for the skipped level, so the next page cannot repeat it.
- **Verified independently of the writer's report**: the checker on the real
site exits 0 with seven pages and the cross-page gate active, zero `aviso:`
lines; every page links to all seven (including itself, as `aria-current`
requires); `sitemap.xml` holds exactly the seven canonical URLs with no
invented `<lastmod>`; `robots.txt` holds the `Sitemap:` line on the same
origin; and the repeated-prose guard genuinely inspects the real prose —
duplicating a real paragraph from `funciones.html` into `estado.html` in a
`build/` copy produced exit 1 naming both pages.
- **Copy spot-check** of `estado.html` and `descargar.html`: no invented
feature, date, version or price; the disabled APK placeholder and the
`TODO(owner)` marker survive; the "límites que ya conocemos" column states only
facts already true of the app (sample discovery data, internet needed for
weather and discovery, no reminders, no cross-device packing sync, no iOS).

## Evidence

### WSP-1 — checker and README (`b82d152`)

`tool/check_landing.py` rewritten into a site checker: discovery of every
top-level `*.html`, the previous per-page checks, cross-page link
resolution, a site-wide gate that activates only above one page, and a
named weight budget (40 KiB hard / 28 KiB warning per page, 40 / 32 KiB
for the stylesheet).

- `python tool/check_landing.py` on the real site: exit 0, one `aviso:` for
single-page mode; `index.html` 18.888 bytes / 441 lines, `styles.css` 22.009
bytes / 813 lines.
- Two-page fixture built outside `website/` (removed afterwards): baseline
exit 0, and exit 1 for each injected defect — a canonical pointing at another
page (`el canonical no apunta a esa misma pagina`), a page absent from
`sitemap.xml`, a dangling cross-page fragment, a header nav that diverges
(named page, expected vs found lists), a link to a missing file, and an
over-budget page. The 28 KiB warning tier was shown not to fail on its own.
- Two judgement calls fixed in review, because the worker's version would
have passed a copy-paste mistake silently: the canonical's **path** is now
required to be that page's own URL (before, only the origin was compared and
the expected sitemap URL was rebuilt from the filename, so a wrong path went
unnoticed), and the navigation reference page is `index.html` instead of the
alphabetically first file, so a divergence message reads against the page a
human expects.
- Not fired: the `<script>`, `<img>`, external-resource, brace-balance and
unclosed-tag paths, whose logic is unchanged from the previous checker and
was already exercised before this unit.

### WSP-2 — the split, plus WSP-2b (`930d7fe`)

Seven pages, one intent each, a shared header and footer nav identical in order,
`aria-current="page"` on the current one, unique title and description per page,
Open Graph tags, one canonical per page on `https://travelready.example`, a
`<details open>` disclosure for small screens, `sitemap.xml` with exactly the
seven canonical URLs and no invented `lastmod`, and `robots.txt` with the
`Sitemap:` line. The checker gained the repeated-prose guard and the three
heading rules. Copy was moved rather than rewritten; `index.html` fell from
441 to 237 lines as its sections moved out.

- `python tool/check_landing.py`: exit 0, seven pages, cross-page gate active,
**zero** `aviso:` lines. Per-page bytes and lines recorded in the commit.
- Weight: seven pages 46.740 B plus `styles.css` 23.163 B = 68,3 KiB total; a
cold load of `index.html` is 33.353 B and the stylesheet is the only other
request. Nothing else is fetched: no font, image, icon or script.
- Link matrix: every page links to all seven, in the same order in the header
and in the footer.
- The repeated-prose guard was shown to inspect **real** prose, not a synthetic
fixture: copying a real paragraph from `funciones.html` into `estado.html` in a
`build/` copy produced exit 1 naming both pages.
- The three heading rules were each shown to fire by injection: a page with its
`h1` removed, two pages sharing an `h1`, and an `h3` injected after the `h1`.
- **No copy changed while the headings were renumbered**: the seven pages kept
byte-identical sizes and line counts (`h1`, `h2` and `h3` are the same length),
which is the independent check on the writer's word-level diff.
- Three defects were found in review and fixed before the commit: `robots.txt`
was ignored by `.gitignore` (`*.txt`), so CI would have failed on a fresh clone
while every local run passed; six pages had no `h1` and `estado.html` skipped a
heading level; and `contacto.html`'s promoted `h1` sat outside `.section-head`,
so it would have rendered at the hero size instead of the `h2` size it had.
- Copy spot-check of `estado.html` and `descargar.html`: no invented feature,
date, version or price; the disabled APK placeholder and its `TODO(owner)`
survive.

### WSP-3 — motion (`64aee7c`)

Hero entrance with a short stagger, reveal on scroll through
`animation-timeline: view()` with `animation-range: entry 0% entry 50%`, a header
shadow over the first 6 rem of scroll, and hover/focus micro-interactions.
`styles.css` 23.402 → 28.071 bytes, still under the 32 KiB warning.

- Every hidden start state and every animation declaration sits inside
`@media (prefers-reduced-motion: no-preference)` nested with
`@supports (animation-timeline: view())`, proven by a brace-depth walk of the
stylesheet: 13 such declarations inside the guard, zero outside, the only
exception being the decorative footer underline resting at `scaleX(0)`.
- No animation touches a layout property, and nothing loops.
- The reduce block cannot lean on `animation-duration` — scroll-driven timelines
ignore it — so it disables the animations by name and restores `opacity: 1` and
`translate: none`.

### WSP-4 — the first render verification (no commit; recorded here)

- **Reduced motion: 0 text-bearing elements at `opacity: 0`** on all seven pages
at 320 and 1440 px, at the top and after scrolling to the bottom.
- With motion allowed: 0 hidden inside the initial viewport, 0 hidden after
scrolling to the bottom.
- 2 requests per page, both 200; no horizontal overflow; focus ring present;
both schemes rendered and inspected.
- The verifier corrected the method it was given: `--virtual-time-budget` never
re-samples a scroll-driven timeline after a programmatic scroll, so it reported
10 falsely stuck elements on `index` at 320 until the frames were forced.
- The host OS has reduced motion on (`MinAnimate = 0`), so the "natural" arm was
the reduced one and the motion arm had to be forced.

### WSP-6 — collapsed menu (`6af4711`) and WSP-7 — its verification (`7934415`)

The seven pages ship `<details class="nav-disclosure">` closed, so phones show
the brand and a `Menú` summary; from 760 px up the links stay inline through
`content-visibility: visible` on `::details-content` plus a companion `display`
rule. The markup change is exactly the removed attribute: every page lost
precisely five bytes.

- The first verification found the collapsed header at **110.44 px**, not the
~60 px the change promised: a `flex-basis: 100%` rule inside the old
`max-width: 560px` block pushed the summary onto its own row at 320, 375 and
414 px. After the fix it is **62.44 px**, and the old value was reproduced
exactly by re-injecting the removed rule, which pins the cause.
- **Geometry is not proof of paint.** With the reveal rule disabled, all seven
desktop links still report 59-126 × 37.6 px while painting nothing and being
unreachable; only `elementFromPoint` and `focus()` caught it. The reveal rests
entirely on `content-visibility: visible`; the companion `display` rule is
inert, because the base `.nav-links` rule already sets flex.
- Keyboard: 0 tab stops reach a nav link while collapsed, 7 of 7 when open.
- Opened states: 284.78 / 241.59 / 198.41 px at 320 / 375 / 414; 600 px, inside
the block whose rules moved, shows no overflow in either state.
- **Chromium-only evidence.** Firefox and Safari were not testable here, and on
an engine where the reveal fails the desktop header falls back to a clickable
`Menú`.

## Not verified here

- Firefox and Safari: the desktop reveal, and therefore the whole cross-engine
claim, is Chromium-only evidence.
- A real touch device: taps were synthesized pointer and mouse events.
- Screen readers and the accessibility tree of the collapsed disclosure.
- The copy against a released build.
- RevenueCat, billing, Maps/Places, Firebase rules, iOS: unrelated to this
feature and still owner-gated.

## Next step

Publishing is the owner's decision and each piece of it has a runbook now: buy
the domain and replace the placeholder origin (procedure in `website/README.md`),
choose the host, decide the privacy policy and legal notice, the contact channel
and the real APK link, then publish and keep `python tool/check_landing.py` green.
The open engineering question is the cross-engine fallback for the desktop
navigation, which needs a Firefox or Safari run to settle.
