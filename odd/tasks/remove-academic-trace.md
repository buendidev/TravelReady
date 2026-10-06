# Remove every trace of the academic project

> This document deliberately does **not** reproduce the strings it removed. An
> inventory that quotes the traces is itself a trace, and the first version of this
> file proved it: the rewrite pass rewrote this file's own quotations, which is why
> the wording here describes the traces instead of naming them.

## Objective
TravelReady is a product, not a final degree project. No file a reader, a user or a
store reviewer can reach may describe it as coursework, and no build may leak it
either.

## Inventory (measured, not guessed)

### Visible to someone using the app
Two screens rendered the same line naming the degree and its acronym — the profile
screen and the chat detail screen. Two copies of one string in two files: it was
centralised, not re-typed.

### Visible to someone visiting the website
The footer of all seven pages carried a line naming the degree and the author, and
`website/contacto.html`'s contact, privacy and legal placeholders were written around
the academic framing.

### Metadata that reaches stores
`pubspec.yaml`'s description named the degree, which matters because that string ends
up in store listings.

### Versioned documentation
`README.md`, `AWS_NOTES.md`, `MARIADB_SETUP.md`, `AGENTS.md`, `.gitignore`,
`.sdd/proposal.md` and `scripts/md_to_docx.py`. The script's only purpose was
producing the academic `.docx` from a markdown file that is not in the repository, so
it was deleted rather than reworded. Historical versions of `SECURITY.md`,
`DB_SETUP.md`, `DATABASE_GUIDE.md` and the Android build files also carried mentions.

### A security constant that carried the trace
`lib/core/security/crypto_service.dart` held a comment and a pepper value with the
degree acronym inside it. **Verified safe to change**: the only caller of the
password-hashing methods is `AuthLocalDataSource`, which nothing references — not the
DI container, not a runtime path, not a test — so no stored hash was ever produced
through a shipped path. The dead datasource itself remains a separate cleanup
candidate.

### Two academic deliverables in git history
A markdown document and a binary `.docx` existed in early commits and were removed
from the tree later. They are deleted from history, not merely from the working tree.

### Local files with no git history
Context and hand-off documents for AI agents, several academic PDFs, screen mockups
and a `NUL` left by a Windows redirect. Six were deleted; three were moved out of the
repository instead, because they are in no git and would not be recoverable — the
Design Thinking PDF, the mockups, and a `config/` directory that turned out **not** to
be an academic trace at all but model-routing profiles for the owner's AI tooling.

## Tasks
- [x] TR-1: The app's visible string, in one place, with a professional wording.
- [x] TR-2: The website footers and the contact/legal copy.
- [x] TR-3: Store metadata.
- [x] TR-4: The versioned documentation.
- [x] TR-5: The academic-only script and the dead security constant.
- [x] TR-6: History rewritten and the folder renamed, done in a separate clone from a verified backup and swapped in afterwards.

## Evidence

- **The two strings a user could see are gone**: both screens now render a single
  constant, `AppStrings.appVersion` in `lib/core/constants/app_strings.dart`, so they
  can no longer disagree about the version either.
- **The security constant is neutral** and its comment now says plainly that the
  scheme does not replace a proper password-hashing function in production.
- **The website** footers read `© 2026 TravelReady · Pablo Buendicho Ortín.` on all
  seven pages, and the contact placeholders were rewritten in a product register
  while keeping their `TODO(owner)` markers and their honest "pendiente" state.
- **Documentation** kept its technical content and lost its academic framing;
  `.gitignore` lost three mentions while keeping every exception intact.
- **One thing a grep cannot check, and it was wrong**: the contact page claimed a
  team that does not exist. There is one person. Rewritten. A grep proves the words
  are gone, never that the tone changed.
- **Acceptance**: the grep over `git ls-files` prints nothing, the whole rewritten
  history contains no match, and the three gates are green — the full test suite, the
  analyzer at its baseline, and `python tool/check_landing.py` with zero warnings.

## Limits
The rewrite changes every commit hash from the first affected one, so the hashes
quoted in earlier feature documents refer to commits that no longer exist under those
names. The backup bundle keeps the old history, and it contains the traces, so it has
to be deleted once the result is accepted.
