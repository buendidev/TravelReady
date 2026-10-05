# Client-visible configuration

## Status legend

- **Verified in repository** — this guide and `.env.example` document the current client boundary and variable names.
- **Proposed** — provider restrictions, rotation, and any future backend boundary are required practices, not repository-enforced controls.
- **External/unverified** — provider-console restrictions, quotas, rotation history, and deployed configuration require owner evidence.

See the [security status and release gates](../../SECURITY.md), [threat model](threat-model.md), and [owner-action register](owner-action-register.md) for the corresponding release decisions and owner actions.

Flutter bundles `.env` as an application asset. Its contents are extractable from a distributed binary and must therefore be treated as public client configuration, not as secret storage.

## Allowed values

The only client-visible variable names are:

- `OPENWEATHER_API_KEY`
- `GOOGLE_MAPS_API_KEY`
- `REVENUECAT_API_KEY`
- `REVENUECAT_API_KEY_IOS`

Use provider-issued client identifiers or keys restricted to this application's permitted package/bundle identifiers, signing certificates, APIs, origins, quotas, and environments where the provider supports those controls. Rotate them through the provider when exposure, misuse, personnel changes, or provider guidance requires it; update affected release configuration before shipping a replacement binary.

Never put backend credentials in `.env`, `.env.example`, Flutter assets, or client code. This includes private keys, service accounts, administrator secrets, database passwords, and webhook secrets. Keep those values only in a server-side secret store once a backend boundary exists.

## Local guard

Copy `.env.example` to a local ignored `.env` and supply only restricted client values. Validate the repository template and dependency lock with:

```sh
dart run tool/release_config_validator.dart .
```

The validator deliberately never reads `.env` and never prints configuration values. It checks the version-controlled template, `pubspec.yaml`, and `pubspec.lock`. `pubspec.lock` is version controlled to make Flutter dependency resolution reproducible.

## Production-surface secret scan

The same command also scans existing UTF-8 text files up to 1 MiB beneath production roots when present: `lib`, `android`, `ios`, `web`, `backend`, `server`, `functions`, and `infra`. It reports only a repository-relative path and pattern class, never a matched value. It detects PEM private-key blocks, service-account JSON `type` markers, and assignments to forbidden server-secret variable names.

The scan excludes `.env` files and `build`, `generated`, and `cache` directories. It does not scan documentation, tests, tooling, or unrelated root `config/`. This is a bounded repository guard, not a replacement for secret management, historical-secret scanning, binary scanning, provider-side controls, or a server-side secret store.
