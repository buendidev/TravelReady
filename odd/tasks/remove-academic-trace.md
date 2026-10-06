# Remove every trace of the academic project

## Objective
TravelReady is a product, not a final degree project. No file a reader, a user or a
store reviewer can reach may describe it as a TravelReady, a  project, or coursework for
any institute, and no build may leak it either.

## Inventory (measured, not guessed)

### Visible to someone using the app
| Where | What |
| --- | --- |
| `lib/presentation/pages/profile/profile_page.dart:230` | `Text('TravelReady! v1.0 · TravelReady 2026')` |
| `lib/presentation/pages/chats/chat_detail_page.dart:430` | `Text('TravelReady! v1.0 · TravelReady')` |

Two copies of the same string in two files: it gets centralised, not re-typed.

### Visible to someone visiting the website
| Where | What |
| --- | --- |
| all seven `website/*.html` footers | `TravelReady — Pablo Buendicho Ortín.` |
| `website/contacto.html` | the legal-notice and contact placeholders, written around the academic framing |

### Metadata that reaches stores
| Where | What |
| --- | --- |
| `pubspec.yaml:2` | the description literally names "TravelReady - Pablo Buendicho Ortín" |

### Versioned documentation
| File | Matches |
| --- | --- |
| `README.md` | 2, including "Proyecto independiente — TravelReady 2025–2026" |
| `AWS_NOTES.md` | 5, including a whole "Usos recomendados para el TravelReady" section |
| `MARIADB_SETUP.md` | 7, header plus framing |
| `AGENTS.md` | the title line: "# TravelReady — Pablo Buendicho Ortín" |
| `.gitignore` | two comments plus an exception for `!TravelReady_DOCUMENTATION.md` |
| `.sdd/proposal.md` | one design question justified by the TravelReady |
| `scripts/md_to_docx.py` | 4, and its whole purpose is producing the academic `.docx` |

### A security constant that carries the trace
`lib/core/security/crypto_service.dart:9,11` — the comment says "para el TravelReady" and
`_pepper = 'TravelReady!2025SecureKey'`. **Verified safe to change**: the only
consumer of `hashPassword`/`verifyPassword` is `AuthLocalDataSource`, which nothing
references — not the DI container, not any runtime path, not any test — so no stored
hash has ever been produced through a shipped path. The dead datasource itself is a
separate cleanup candidate.

### Local files with no git history
`CONTEXT.md`, `CLAUDE.md`, `HANDOFF_TO_AGENT.md`, `WINDSURF_DEVIN_HANDOFF*.md`,
`Design Thinking - Travel Ready!.pdf`, `stitch_travel_ready_login_screen/**`,
`NUL`, `config/`, `paymorph-html/` and its zip. All untracked, all removable without
touching history.

### The one thing that is not a file edit: git history
The traces are inside past commits. Removing them from the working tree leaves them
readable in `git log -p` for anyone who has or gets a clone. Erasing them completely
means rewriting history, which changes the hash of every commit from the first one
affected and invalidates any existing clone. Nothing has been pushed, so it is
technically clean, but it is destructive and needs explicit authorisation. The
repository's own folder name — `ProyectoFinal_TravelReady` — is part of the same
question.

## Tasks
- [x] TR-1: The app's visible string, in one place, with a professional wording.
- [x] TR-2: The website footers and the contact/legal copy.
- [x] TR-3: Store metadata (`pubspec.yaml`).
- [x] TR-4: The versioned documentation (`README`, `AWS_NOTES`, `MARIADB_SETUP`, `AGENTS`, `.gitignore`, `.sdd/proposal`).
- [x] TR-5: The academic-only script and the dead security constant.
- [ ] TR-6: History rewrite and folder rename — only with explicit authorisation.

## Evidence

### TR-1 to TR-5, done

- **The two strings a user could see are gone**: `profile_page.dart` and
`chat_detail_page.dart` now render **`AppStrings.appVersion`**, added to the
existing `lib/core/constants/app_strings.dart` as `'TravelReady 1.0'`. One source,
so the two screens can no longer disagree about the version either.
- **The security constant is neutral**: `_pepper` is now
`'TravelReady!SecurePepper2026'`, and the comment says plainly that this scheme does
not replace a proper password-hashing function in production. Verified safe before
touching it: the only caller is the unreferenced `AuthLocalDataSource`.
- **The website**: the seven footers read `© 2026 TravelReady · Pablo Buendicho
Ortín.`, and `contacto.html`'s contact, privacy and legal placeholders were rewritten
in a product register while keeping their `TODO(owner)` markers and their honest
"pendiente" state.
- **Metadata**: `pubspec.yaml`'s description no longer names a degree, which matters
because that string reaches store listings.
- **Documentation**: `AGENTS.md`, `README.md`, `AWS_NOTES.md` and `MARIADB_SETUP.md`
keep their technical content and lost their academic framing; `.gitignore` lost its
three mentions while keeping every exception intact; `.sdd/proposal.md`'s design
question no longer justifies itself by a submission date; `scripts/md_to_docx.py`
was deleted because its only purpose was producing the academic `.docx`.
- **Acceptance**: the grep over `git ls-files` prints nothing (the only output was a
`No such file` for the script already deleted from disk and not yet staged), and the
three gates are green: **437 tests**, analyzer exit 0 with the baseline **75 infos**,
`python tool/check_landing.py` exit 0 with **zero `aviso:` lines**.

### One thing a grep cannot check, and it was wrong

A review pass over the prose found the contact page claiming **"el equipo de
TravelReady"**. There is no team: there is one person, and inventing colleagues on a
support page is exactly the kind of detail that reads as fake later. Rewritten to
"el canal oficial de soporte se publicará aquí antes del lanzamiento". The register
of the documents was read line by line for the same reason; a grep proves the words
are gone, never that the tone changed.

### The untracked leftovers

Six files deleted (context and hand-off documents for AI agents, and a `NUL` left by
a Windows redirect). Three were **moved out of the repository** rather than deleted,
to `Documents/TravelReady-fuera-del-repo/`: the Design Thinking PDF, the screen
mockups, and `config/`. The first two are in no git and would not be recoverable; the
third turned out **not** to be an academic trace at all but model-routing profiles
for the owner's AI tooling (a `codellama` and a `gpt-4o-mini` configuration), and
deleting a tool's configuration on the strength of a cleanup instruction is not a
decision this unit was authorised to make. The owner can delete the folder, or the
files can move back.

## Acceptance
The grep over versioned files is clean, the three gates are green, and the wording
was reviewed by a human pass rather than trusted to the grep.

```bash
git ls-files -z | xargs -0 grep -lEi "TravelReady|trabajo fin|||proyecto final|| ||"
```

A grep can prove the absence of the words. It cannot prove that the *tone* stopped
being coursework. That is a review pass over the documents, and it is why the README
and the website were rewritten in a product register instead of having the words
swapped out mechanically. The review earned its place: it caught a sentence claiming
a team that does not exist.

## Limits
TR-6 is still open: the traces remain readable in `git log -p` for as long as the
history is not rewritten, and the repository's folder name still carries the old
project name.

## Next step
TR-6: back up the repository, rewrite the history, verify the grep over the full
history and rename the folder.
