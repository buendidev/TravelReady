# Handoff pack — scope for an external agent (Windsurf / Devin Desktop)

Written by the Pi orchestrator on 2026-10-09. This directory exists so that a
**different agent, in a different tool, can implement work in this repository
without reading a lie and without re-doing verified work.**

Read this index first, then the one spec that matches the work assigned.

| Spec | Scope | Owner decision already taken |
| --- | --- | --- |
| `recommendations-feed.md` | Swipe feed of recommended places (Tinder-style), Favorites, hidden Dislikes | Right swipe = like, left swipe = dislike; demo fixtures now, real Places later |
| `ai-assistant-llm.md` | Connect a real LLM to the in-app AI assistant | Provider: NaN Builders, model `qwen3.8-flash` |
| `website-amplification.md` | Grow the static website | Amplify it, do **not** rewrite it |

## 1. Do this before handing anything over

An external agent that reads this repository as it stands today will build a
phantom architecture. These are verified defects in the documentation, not
opinions. Fix them first (they are cheap) or the handoff will produce fiction:

1. **`AGENTS.md` documented Hive as a critical rule.** There is no Hive
   anywhere: `pubspec.yaml` has `sqflite: ^2.3.0` and no `hive`. Local
   persistence is SQLite through `lib/core/database/database_helper.dart`.
   **Fixed in this pack**: the rule now describes the real SQLite path.
2. **`AGENTS.md` pinned wrong Firebase versions** (`firebase_auth ^6.4`,
   `cloud_firestore ^6.3` against `^5.5.2` and `^5.6.5` in `pubspec.yaml`).
   **Fixed in this pack.** (`google_sign_in: ^6.2.1` did match.)
3. **`DATABASE_GUIDE.md`, `AWS_NOTES.md` and `MARIADB_SETUP.md` describe a
   backend and a persistence layer that do not exist.** There is no `functions/`,
   no EC2, no MariaDB, and **no Hive**: `DATABASE_GUIDE.md` (297 lines, the worst
   offender) shows `hive_constants.dart`, `@HiveType` models and
   `Hive.openBox` against a dependency that is not in `pubspec.yaml`.
   **Fixed in this pack** with a warning header on each of the three.
   (`DB_SETUP.md` was reviewed and is honest: it states that it is a plan, not
   proof of deployed configuration. Left untouched.)
4. **`AGENTS.md` module table claims M5 "Chats + IA" is done.** The "IA" is a
   local rule-based assistant (`lib/presentation/pages/chats/chat_detail_page.dart:211`,
   comment `Asistente IA local`); there is no LLM provider today. Make that
   explicit or it will be assumed to exist.
5. **`.windsurfrules.txt` says "Be extremely concise. No filler. No explanations
   unless requested."** That instruction actively fights the ODD/RDD discipline
   Gentle AI injects there. **Not changed here** — it is tool configuration, not
   repository content, and the owner's call. Recommended replacement: a pointer
   to `AGENTS.md` plus "concise about results, not about reasoning".
6. **`.gitignore` has a bare `*.pdf`**, so any legal or release PDF dropped into
   the repository is silently invisible to git.
7. **`AGENTS.md` is not in the repository at all.** `.gitignore:83` ignores it, so
   the agent-facing guide — the first file an agent reads — exists only in the
   owner's working copy. A fresh clone has none. The same block ignores
   `.windsurf/`, `skills/`, `prompt.txt`, `undefined_errors.txt` and
   `task_tavelReady`. The Hive and version corrections in `AGENTS.md` were
   applied **locally only** and cannot travel through git until that line is
   revisited by the owner. An implementing agent working from a fresh clone must
   therefore trust this directory over a missing `AGENTS.md`.

## 2. Contract for the receiving agent

- **One feature per branch, one work unit per commit.** Conventional Commit
  messages, English artifacts, tests and docs in the same commit as the
  behaviour.
- **Test-first where a deterministic runner exists.** Observe RED, then GREEN,
  then refactor with checks. This repository has 46 test files and a real CI, so
  "no test possible" is almost never true here.
- **CI must stay green**: `flutter analyze`, `flutter test`, the website
  structural checker, the tool tests and the Firestore rules emulator job
  (`.github/workflows/ci.yml`). No new analyzer diagnostics in touched files.
- **Never rewrite what is already verified.** The website, the itinerary
  foundation and the places boundary are verified work; extend them.
- **Do not commit secrets.** Flutter bundles `.env` into the APK: it is not a
  secret store, and `.env.example` already says so.
- **No new provider identifier or photo reference may reach local storage.** The
  retention boundary is `PlaceResult.toSnapshot()` →
  `PlaceSnapshot` and it is deliberate.

## 3. Sequencing (do not run these in parallel)

The three scopes overlap on `lib/injection/injection.dart`,
`lib/core/router/app_router.dart`, `lib/l10n/*.arb` and `AGENTS.md`. Two agents
editing those in parallel will collide. Recommended order:

1. `recommendations-feed.md` — self-contained, no owner account needed (runs on
   the existing demo gateway), highest user-visible value.
2. `ai-assistant-llm.md` — needs one host decision for the proxy (see the spec);
   it also touches the assistant surfaces.
3. `website-amplification.md` — mostly owner-blocked items; start with the two
   non-blocked ones.

## 4. Continuity between tools

- The durable handoff is **this directory in the repository**, not a chat log and
  not a memory record. An agent resuming work should read the spec, then the
  repository, then `odd/tasks/*.md`.
- Engram continuity does work across tools: the project key is derived from the
  git remote, so a session opened on this same repository resolves to the same
  project (`proyectofinal_travelready`) and `mem_context` returns this session's
  observations. Treat memory as a cache and the repo as the source of truth.
- When a spec here is implemented, its ODD record (`odd/tasks/<feature>.md`) is
  created **by the implementing session**, with its own evidence and commit
  record. This directory is a specification, not a task record: do not mark
  items here as done.
