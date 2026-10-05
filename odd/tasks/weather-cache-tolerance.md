# Weather cache tolerance

## Objective
Reading the weather cache must never throw because a stored row is unusable. A bad row is a cache miss, not a failure of the weather feature.

## Evidence
`WeatherCacheDataSource._get` guarded only for an empty result set. Everything after that was unguarded: `jsonDecode` on the stored text, `row['weather_json'] as String`, and eleven field casts on the decoded map. A row written partially, corrupted on disk, or stored by an earlier schema therefore raised out of `getByCity`/`getByCoords` into the weather block.

Observed failures against the shipped code:

| Stored row | Result |
| --- | --- |
| `weather_json` = `'{not json at all'` | `FormatException: Unexpected character (at character 2)` |
| `weather_json` = `{"city":"Madrid"}` (legacy or partial) | `TypeError` on the first missing field |

## Scope
`lib/data/datasources/local/weather_cache_datasource.dart` and its existing test file.

## Tasks
- [x] WCT-1: Add the two regression cases and observe the RED.
- [x] WCT-2: Treat an undecodable or incomplete row as a miss.
- [x] WCT-3: Verify with the focused test, the full suite and the analyzer, then commit.

## Acceptance
`getByCity` and `getByCoords` return `null` for a corrupt or incomplete row instead of throwing. A valid row keeps round-tripping every field and timestamp exactly as before. The cache is not mutated while reading, so the next successful fetch overwrites the bad row through the existing upsert.

## Evidence
- RED: `flutter test --no-pub --no-test-assets test/data/datasources/local/weather_cache_datasource_test.dart` -> exit 1, 5 passed / 2 failed with the two failures quoted above.
- GREEN: same command -> exit 0, **7 passed**.
- `flutter test --no-pub --no-test-assets` -> exit 0, **276 passed**.
- `flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings` -> exit 0, 115 infos, zero warnings, zero errors.

## Not verified here
- The tolerance is verified against an injected database-like query result, not against a real corrupted SQLite file.
- A corrupt row is left in place rather than deleted; recovery relies on the next fetch overwriting it.

## Next step
The larger production-hygiene item found in the same scan: 45 `print` calls across `lib/` that write diagnostics and raw error text to stdout in release, including the user's email on every authentication state change.
