# Maps & Places integration — owner prerequisites

TravelReady's discovery feature is **provider-neutral by design**. All
provider interaction crosses two boundaries, and only these:

| Boundary | File | Purpose |
|---|---|---|
| `PlacesGateway` | `lib/core/services/places/places_gateway.dart` | Search/discovery (text query + category → `List<PlaceResult>`) |
| `MapAdapter` | `lib/core/services/places/map_adapter.dart` | Map viewport with markers (no SDK types in the signature) |

Current registered implementation: **`DemoPlacesGateway`** — local
fixtures, no network, no keys, results visibly labelled as demo data
in the UI. This is intentional until the prerequisites below exist.

## Owner prerequisites (Google path)

1. **Google Cloud project + billing** with **budget alerts** configured
   before enabling anything — Places calls are billable.
2. **Maps SDK for Android** enabled (map rendering).
3. **Places API (New)** enabled (search/details/photos).
4. **Two API keys**, both Android-restricted:
   - Map key — embedded via `AndroidManifest.xml` meta-data (this is
     the documented Google mechanism; it is *not* a secret, but still
     restrict it to the app's package+SHA-1).
   - Places key — **never in the app or in `.env`** (Flutter bundles
     `.env` into the APK — it is not a secret store). Route Places
     calls through a backend proxy or Firebase callable; the gateway
     implementation then talks to that proxy.
5. **Provider policies to honour in code:**
   - Attribution: render `PlacesGateway.attributionText` whenever
     non-null — already wired in `DiscoveryPage`.
   - Photos: Places photo references are not permanent URLs; resolve
     at display time, don't store rendered photo bytes beyond allowed
     caching windows.
   - Caching/retention: Places (New) restricts storing place data.
     `PlaceResult.toSnapshot()` already applies the retention boundary:
     only provider-neutral user itinerary details
     (name/address/coordinates/official website/hours text/price label)
     persist in `PlaceSnapshot`. Provider identifiers and photo references,
     along with descriptions and other provider content, are dropped.
   - Quota/errors: map provider failures to `PlacesConfigFailure`,
     `PlacesQuotaFailure`, `PlacesParseFailure`
     (`lib/core/services/places/places_failures.dart`) — never return
     fake data on failure.

## Architecture rules for the real implementation

- Implement `PlacesGateway` + `MapAdapter` under
  `lib/core/services/places/` (or `data/datasources/remote/` if it
  becomes a network datasource — keep the interface unchanged).
- Register the real implementation in `lib/injection/injection.dart`
  by swapping the `DemoPlacesGateway` registration — single line.
- `PlacesAvailability.configured` switches the UI off demo mode
  automatically; no UI changes needed.
- The UI must never scrape Google Maps or call Places REST directly
  with an embedded key.
- Keep the demo gateway as the `dev`/`test` implementation — it makes
  widget tests deterministic and the feature demoable without keys.

## Deferred owner actions

- Create Google Cloud project, billing, budget alerts.
- Enable Maps SDK for Android + Places API (New).
- Create and restrict both API keys.
- Decide the Places proxy architecture (backend or callable) and its
  quota/caching policy.
- Review `PlaceSnapshot` retention fields against Places (New) ToS
  before shipping a real provider.
- End-to-end smoke on a physical device (maps need Play Services).
