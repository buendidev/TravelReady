# Desktop navigation without an engine-specific trick

## Objective
The header navigation must work inline on desktop and collapsed on mobile using
only universally supported CSS, so that no browser has to be trusted with a
feature that only one engine implements.

## Evidence
The mobile menu is a `<details>` that ships closed, so from 760 px up the link
list has to be forced visible. That forced reveal rests on two rules:

```css
.nav-disclosure::details-content { content-visibility: visible; }  /* Chromium 131+ */
.nav-disclosure .nav-links { display: flex; }                      /* other engines */
```

A real render pass proved the whole reveal is carried by the **first** rule
alone, and that the second is inert in Chromium because the base `.nav-links`
rule already sets `display: flex`. Nothing here can render Firefox or Safari: no
Firefox is installed, no Playwright browser is cached, and there is no WebKit.
So the site's desktop navigation currently depends on a Chromium-131-era
pseudo-element, with an unverified fallback.

## Decision
Remove the dependency instead of testing around it. Two plain lists share the
header: the disclosure for small screens, which needs no CSS at all because
`<details>` is native, and an ordinary list for wide screens, which is hidden on
small screens with `display: none`. Both halves then use nothing newer than a
media query, and there is no engine-specific feature left to get wrong.

Cost, accepted: the seven links appear twice in each page's markup, and the two
lists must not drift. The drift risk is gated by a new checker rule, not by
discipline.

## Tasks
- [x] DN-1: Two header lists per page — the disclosure for mobile, a plain list for desktop — with identical hrefs, order and current-page marker.
- [x] DN-2: CSS that shows exactly one of them per width, with no `::details-content` or `content-visibility` rule left in the stylesheet.
- [x] DN-3: A within-page checker rule: every link list inside the header nav must have the same ordered hrefs and the same marked link.
- [x] DN-4: Verified in a real engine at both widths, in both menu states.

## Acceptance
At 760 px and above the desktop list is visible inline and the disclosure is not
rendered; below 760 px the disclosure shows the `Menú` summary, the desktop list
is not rendered and is absent from the accessibility tree, and the links appear
when the summary is tapped. No page contains `::details-content` or
`content-visibility`. A page whose two header lists differ, or whose current-page
marker sits on a different link in each list, fails the checker.

## Limits
Duplicated markup is a real cost, and the guard only compares the links and the
current-page marker, not the labels: a label drift would pass the checker and has
to be caught in review.

## Evidence

- `python tool/check_landing.py`: exit 0 over seven pages with the cross-page
gate active and **zero** `aviso:` lines.
- **The engine dependency is gone and that is measurable**:
`grep -n "details-content\|content-visibility" website/styles.css` prints
nothing. No engine-specific selector is left for the navigation.
- **The duplication did not drift, labels included** — which the checker does not
guard: extracting both header lists of each page and normalizing whitespace gives
byte-identical blocks on all seven, seven links each.
- The new within-page rule (identical ordered hrefs and the same `aria-current`
link across the header's lists) was proven by injection: a page with two links
swapped, and a page marking a different link as current, both fail with exit 1.
It also fired on the author's own edit mid-implementation, where
`funciones.html`'s second list marked the wrong link — the guard catching genuine
drift, not only a mutant.
- **Rendered in a real engine, inspected by eye**: at 1440 px one inline row with
the disclosure not rendered; at 375 px the collapsed header is ~62 px with only
the `Menú` pill, and opening it lays the seven links out across three rows with
the current page marked. The worker's harness measured the same states
(`display: none` and not focusable below 760 px; `display: flex`, focusable and
hit-testable above) and also caught two specificity bugs, one in each direction,
that the checker cannot see.
- Weight: +459 bytes of markup per page and +494 for the stylesheet, still inside
the budget with no warning.

## Limits, confirmed
The checker compares hrefs, order and the current-page marker, **not the visible
labels**; the label comparison above was done by hand for this unit and is not a
guard. And no non-Chromium render was observed: the claim is now that there is
nothing engine-specific left to fail, not that Firefox was watched working.

## Next step
Nothing outstanding. If the owner wants independent confirmation rather than a
construction with no engine-specific feature, installing Firefox on this machine
and re-running the same two-width render is a two-minute job and a decision of
his.

