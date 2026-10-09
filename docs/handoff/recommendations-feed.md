# Swipe recommendations feed (Favorites / hidden Dislikes)

Owner-originated feature. This is the acceptance specification, written so an
implementing agent does not have to guess intent.

## 1. Intent

Before or during a trip, the traveller opens a feed of recommended venues for the
city of the trip (or its surroundings) and browses them **one card at a time**,
like Tinder, instead of reading a list. They can filter what kind of venue
appears. When they like one, it is kept and can be added to the trip itinerary in
a few taps. When they reject one, it must never be offered again.

## 2. Non-negotiable rules

1. **Gesture mapping (owner decision, fixed): right = like, left = dislike.**
   This is the Tinder convention and it was explicitly confirmed, because the
   first description of the feature had it inverted. Do not invert it.
   - Right swipe → the place is saved as a **favorite**.
   - Left swipe → the place is marked **disliked** and must never appear again in
     that user's feed.
2. **A disliked place is invisible to the user.** There is no "disliked" list in
   the UI: the user only experiences the consequence (it stops being offered).
   A reachable "reset the feed" action is still required (see §8) so the user is
   not trapped by their own accidental swipes.
3. **Liking and disliking are mutually exclusive.** Setting one clears the other
   for the same place.
4. **Never claim live results when the provider is not live.** While
   `PlacesGateway.availability == PlacesAvailability.demo`, the feed shows the
   same "Datos de ejemplo" labelling the discovery screen already uses, and it
   must not claim the cards are results for the typed city. This rule already
   exists in `places_gateway.dart`; the feed inherits it.
5. **No provider identifiers or photo references are persisted.** Store only
   provider-neutral fields (`PlaceSnapshot` shape). Provider data has retention
   limits and `PlaceResult.toSnapshot()` is the boundary.
6. No new network dependency, no analytics, no tracking.

## 3. Where it lives

The existing surfaces today:

- `lib/core/services/places/places_gateway.dart` — `PlacesGateway` with
  `availability`, `attributionText` and
  `search({query, category, destinationHint, limit})` returning
  `Either<Failure, List<PlaceResult>>`.
- `lib/core/services/places/demo_places_gateway.dart` — the registered
  implementation (local fixtures).
- `lib/presentation/pages/discovery/discovery_page.dart` — search field,
  category `ChoiceChip`s, `PlaceCard`, details bottom sheet with "Sitio web
  oficial" and "Añadir al itinerario".
- `lib/core/router/app_router.dart` — `/trips/:id/itinerary`,
  `/trips/:id/discovery`.
- `lib/domain/usecases/itinerary/**`, `ItineraryBloc` — the add-to-itinerary path
  that must be reused, not reimplemented.

Add, following the same layering the repository already uses:

- `lib/domain/entities/recommendations/**` — the feed item and the reaction.
- `lib/domain/repositories/favorites_repository.dart` (+ impl under
  `lib/data/repositories/`).
- `lib/data/datasources/local/favorites_local_datasource.dart` — SQLite, using
  the lazy `CREATE TABLE IF NOT EXISTS` pattern already used by
  `ItineraryLocalDataSource`, **and this time also register the schema in
  `lib/core/database/database_helper.dart`** (the itinerary table was left out of
  the central migration as a known 1-line follow-up; do not repeat that).
- `lib/domain/usecases/recommendations/**`.
- `lib/presentation/bloc/recommendations/**`,
  `lib/presentation/pages/recommendations/**`,
  `lib/presentation/widgets/recommendations/**`.
- Routes: `/trips/:id/discovery` gains a segmented control
  `Descubrir | Favoritos`, or a sibling route `/trips/:id/favorites` that opens
  the same page with the Favorites tab selected. **The favorites view must be
  reached from a trip**, because "add to itinerary" needs a trip id.
- `lib/injection/injection.dart`, `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`
  plus the generated localizations, and `odd/tasks/swipe-recommendations.md`.

## 4. Filters

Three filters plus the default, mapping onto the existing provider-neutral
`PlaceCategory` enum
(`monument, museum, food, nature, nightlife, shopping, hotel, other`):

| UI filter | Categories | Gateway call |
| --- | --- | --- |
| Monumentos | `monument`, `museum` | one `search(category:)` per category, then merge |
| Restaurantes | `food` | one call |
| Ocio | `nature`, `nightlife`, `shopping` | one `search(category:)` per category, then merge |
| Todos (default) | all of the above, mixed | `search(category: null)`, then classify client-side |

`hotel` and `other` **never appear in the feed** (a hotel is not a
recommendation of a place to visit). Document that as an intentional product
rule.

## 5. Feed algorithm

Per session, in this order, and always testable:

1. Resolve the location context: the user's typed city, or the trip destination
   as the pre-filled default (`destinationHint`).
2. Fetch through `PlacesGateway` for the active filter (`limit` ~20).
3. Drop everything already reacted to (likes **and** dislikes) — see §6 for the
   key.
4. Drop `hotel`/`other`.
5. Interleave the categories round-robin so "Todos" alternates instead of
   listing monuments then restaurants, then shuffle with an **injected seed**.
   Determinism matters: the shuffle must be reproducible in tests.
6. Show the top card plus two partially visible cards behind it.
7. **Refill** when fewer than 3 unreacted cards remain, at most twice per user
   action, and pass the seen keys so the reload cannot resurrect them.
8. **Exhausted state**: an honest empty state ("no hay más lugares con este
   filtro") with a one-tap way back to changing the filter or resetting the feed.
   Never silently loop the same cards.

## 6. Persistence and the place key

Two tables, both local-only SQLite in v1:

- `place_favorites(place_key TEXT PRIMARY KEY, name, category, address, latitude,
  longitude, website_uri, opening_hours_text, price_level_label, created_at)` —
  the snapshot fields are what the user chose to keep and what the details screen
  and the itinerary sheet need.
- `place_dislikes(place_key TEXT PRIMARY KEY, created_at)` — deliberately stores
  **no name and no snapshot**: "do not recommend this again" needs the key and
  nothing else. Keeping less is both a privacy choice and a retention choice.

`place_key` must be provider-neutral and stable, because `providerId` is not
allowed to persist:

```
place_key = sha256(normalize(name) + '|' + (normalize(address) | rounded lat/lon))
```

- `normalize`: trim, collapse internal whitespace, casefold, strip accents.
- `crypto: ^3.0.3` is already a dependency; use it.
- Consequence to document: two genuinely different venues that normalise to the
  same name and address collapse into one key, and the second is treated as
  already seen. Acceptable, and it must be stated in the code comment.

**Deferred decision (state it in the ODD record):** reactions are per device in
v1. Reinstalling or changing device loses them. Cross-device favorites need a
user-scoped Firestore collection and rules, which belongs with the
`users`/friends model and the rules hardening work — not here.

## 7. UI requirements

- Card: reuse `PlaceCard`'s visual language; the feed card additionally carries
  the category chip, the price label and the address.
- Drag: the top card follows the finger with a rotation proportional to
  horizontal displacement; a green "♥" or red "✕" badge appears once the
  threshold is crossed. Commit the swipe at ~35 % of the card width or on a
  fling faster than ~800 px/s; below threshold the card springs back.
- Feedback: subtle haptic on threshold crossing.
- **Accessibility (required, not optional):** two always-visible buttons —
  "✕ no me interesa" and "♥ me gusta" — with proper `Semantics` labels, focusable
  and operable without a gesture. The swipe is an enhancement, never the only
  way in. The rest of this app already ships `Semantics` labels and skip links;
  match that standard.
- States: loading (skeleton or spinner), error (retry), unavailable provider,
  demo provider (labelled), empty, exhausted. Each with a test.
- Show `attributionText` whenever it is non-null, as `DiscoveryPage` already does.
- Add a single-step **undo** for the last swipe (a short snackbar action). Marked
  as an engineering proposal, not an owner requirement: mis-swipes are the
  predictable failure of this interaction and an undo is far cheaper than a
  support conversation.

## 8. Favorites tab and the itinerary path

- The Favorites tab lists liked places, newest first, with the same card visuals.
- Opening one shows the **existing** details bottom sheet, so the owner gets
  "Sitio web oficial" (`url_launcher`) and "Añadir al itinerario" for free.
- Reuse the existing stacked-sheet flow. There is a known trap already fixed in
  `DiscoveryPage`: do not pop one sheet and push another, hit-testing races.
- Add-to-itinerary must keep its current contract: confirm the add only after
  `ItineraryMutationSucceeded`, and leave the sheet open on failure.
- "Quitar de favoritos" deletes the reaction, so the place can appear in the feed
  again. Removing a favorite is **not** a dislike.
- The "reset the feed" action lives in the feed's overflow menu (or next to the
  filters): it clears dislikes only, behind a confirmation, because dislikes are
  otherwise unreachable by design.

## 9. Required tests

Deterministic, in the repository's existing test layout:

- **Data:** insert/list/delete reactions; like↔dislike mutual exclusion; key
  normalisation (case, accents, extra spaces, missing address → rounded
  coordinates); a dislike row stores no venue name.
- **Domain:** filter → category-set mapping; exclusion of reacted places;
  `hotel`/`other` excluded; seeded shuffle produces the same order twice and a
  different order with a different seed; refill cannot resurrect a seen key;
  exhaustion.
- **Presentation:** swipe right saves to Favorites; swipe left hides and never
  reappears after refill; the buttons do the same as the gestures; demo banner
  shown when `availability == demo`; empty and exhausted states; add-to-itinerary
  from a favorite persists an `ItineraryItem` for the right trip and day.
- **Regression:** full `flutter test` green; `flutter analyze` with no new
  diagnostics in touched files; `git diff --check` clean.

## 10. Out of scope for this feature

- Real Google Places data. The feed is built against the boundary and runs on
  fixtures; enabling the real provider is `docs/places-integration.md` plus the
  owner prerequisites (billing, Maps SDK, Places API (New), restricted keys and
  a server-side proxy for the Places key). When that lands, the feed needs no
  rewrite — only the gateway implementation changes.
- A map view of the feed (`MapAdapter` exists as a boundary with no
  implementation, by design).
- Cross-device sync, sharing, and "friends' favorites".
- Reservations or bookings of any kind.
