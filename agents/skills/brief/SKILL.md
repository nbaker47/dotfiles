---
name: brief
description: >-
  Generate a polished stakeholder brief of everything shipped since the last
  brief - a screenshot-rich, benefit-first rundown of the features the raw
  commits collapse into. Renders as a Keynote-styled .pptx deck (default) or a
  narrative Markdown page (`/brief md`), saved into docs/briefs and committed.
  Use when the user asks for a "brief", "ship brief", "what's new", "what did we
  ship", a "feature rundown", "release brief", or a "showcase of recent work".
---

# Brief - what shipped, for stakeholders

Turn raw commits into a **polished, benefit-first feature brief with
screenshots** - the kind of thing you send a stakeholder, not a git changelog.
The reader should come away knowing *what is newly possible* and *see* it,
without ever reading a commit hash.

## Invocation

    /brief              -> .pptx deck (default), window = since the last brief
    /brief pptx         -> same, explicit
    /brief md           -> narrative Markdown page instead
    /brief both         -> render both formats from the same content
    /brief md yesterday -> format plus a window / repo filter

`$ARGUMENTS` may carry, in any order:

- **format**: `pptx` (default) | `md` | `both`. Anything else is not a format.
- **window**: `yesterday`, `2026-06-20`, `"3 days ago"`, `"since last friday"` -
  passed to `git log --since=...`. For a single calendar day also pass `--until`
  at the next midnight.
- **repo name** (e.g. `platform`) to restrict a multi-repo scan.

**Default window is since the LAST brief**: the newest dated file in the briefs
directory, counting **both** `.md` and `.pptx` (see step 1). If no brief exists
yet, fall back to **today** (since local midnight). State the window you used in
the output.

## Where output goes

- **Inside a git repo** -> `docs/briefs/` (committed with the repo, so the brief
  history lives beside the code). Create the directory if missing.
- **Outside a repo** (e.g. run from `~/Code` across many repos) ->
  `~/Code/briefs/`.
- Files: `<YYYY-MM-DD>-brief.pptx` / `<YYYY-MM-DD>-brief.md`, dated by the
  window's end. Multi-day ranges keep the end date; the range itself is printed
  inside the brief.
- Screenshots: `<briefs-dir>/assets/<YYYY-MM-DD>/<feature-slug>.png`, referenced
  from Markdown by **relative** path so the folder stays portable.

## Pipeline

### 1. Find the window and collect commits

Find the last brief, then collect commits. The invocation directory may be one
repo OR a container of nested repos (e.g. `~/Code/IHS` holds `platform/` and
`kinoped/`):

```bash
ls docs/briefs/*.md docs/briefs/*.pptx 2>/dev/null | sort | tail -1   # the last brief
find . -maxdepth 3 -name .git \( -type d -o -type f \) -prune | sed 's,/.git,,' | sort -u
git -C "<repo>" log --since=<date> --no-merges \
  --pretty=format:'%h%x09%an%x09%s%x09%b%x1e' --name-only
```

**Both formats count as briefs.** The history is mixed - some entries are
`.pptx` decks, some `.md` pages, and the earliest may be a hand-seeded brief
transcribed from a deck. Sort the whole directory by filename (the
`YYYY-MM-DD` prefix sorts correctly) and take the newest **regardless of
extension**; its date is the start of the window. Never look at only one
extension - doing so re-reports features already covered by a brief in the
other format.

If **no commits** land in the window, say so plainly and stop - never invent a
brief.

### 1b. Read the past briefs before writing a new one

Read the previous brief - and skim further back when the window is long - so the
new one continues the story instead of repeating it. Check what was already
announced, and what a previous "looking ahead" section promised (shipping
something previously listed as proposed is worth calling out explicitly).

- **Markdown** briefs: read the file directly.
- **PPTX** briefs: extract the text (needs python-pptx):

```bash
python3 - <<'PY'
from pptx import Presentation
for i, s in enumerate(Presentation("docs/briefs/<file>.pptx").slides):
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip():
            print(i, "|", sh.text_frame.text.strip().replace("\n", " / "))
PY
```

The same extraction reads any external deck a user points at, which is how a
briefs folder gets seeded from an existing Keynote or PowerPoint: export or read
the deck, transcribe its content into a dated brief, and later briefs then
measure from it. (Keynote `.key` files are not directly readable - use the
`.pptx` export.)

### 2. Coalesce commits into features

Raw commits are not features. Collapse them:

- **Drop non-feature noise** from the showcase: `docs`, `chore`, `test`,
  `build`, `ci`, `style`, dependency bumps. A notable infra/docs item can earn a
  single closing line, not a card of its own.
- **Group** the `feat`/`fix`/`perf`/`refactor` commits belonging to one shipped
  capability. Strong signals: the same Conventional-Commit scope
  (`feat(sessions:` + `fix(sessions:` -> one feature); a `fix` touching the same
  files as a `feat` in the window (polish - fold it in); commits touching the
  same route or component cluster.
- **Name each feature from the user's point of view**, not the commit subject.
  `feat(sessions): chain multiple patterns + per-step dosage` ->
  *"Build multi-step sessions from several patterns, each with its own dosage."*
- Order by impact: new user-facing capability > enhancement > fix. Aim for 4-8
  features; fold the small stuff into one "Fit and finish" entry.

Confirm the coalesced list with the user first **only if** the grouping is
genuinely ambiguous; otherwise proceed.

### 3. Map each feature to a viewable URL

Find a page that shows each feature off, from its changed files. For a Next.js
App Router app (this repo's is at `src/cloud/app/src/app`):

1. **A `page.tsx` under `app/` changed** -> derive the route from its folder,
   stripping route groups in parentheses. `app/(dashboard)/sessions/page.tsx`
   -> `/sessions`.
2. **A dynamic segment** (`[id]`) -> do not guess an id; open the parent list
   page and click into a real instance, or screenshot the list itself.
3. **Only a component changed** -> grep `app/` for its importer to find the
   hosting route: `grep -rl "robot-viewer" src/cloud/app/src/app`.
4. **Only `api/`, `lib/`, prisma, or edge-service files changed** -> no visual
   surface. Write the entry prose-only. **Never fabricate a screenshot.**

### 4. Capture screenshots (both formats use them)

Pick the source automatically:

1. **Local dev** (`http://localhost:3000`) if it responds and is authenticated -
   it shows the freshest, just-committed code.
2. **Auth check**: if a protected route redirects to login, prefer an
   already-authenticated Chrome tab; if still unauthenticated, fall back rather
   than blocking on login.
3. **Deployed app** fallback (read its URL from the repo's CLAUDE.md). Flag in
   the brief when a shot came from the deployed app, so "shipped but not yet
   deployed" stays honest.
4. **Nothing reachable** -> text-only entries plus a short note saying
   screenshots were skipped.

Drive the browser with the claude-in-chrome MCP tools (load them via ToolSearch
in ONE batched call): `tabs_context_mcp` -> reuse an authed tab or
`tabs_create_mcp` -> `navigate` -> let it settle -> screenshot. Frame the
**relevant UI**, not a generic dashboard. One clean shot per feature. If a page
fails after 2-3 attempts, fall back and move on - do not rabbit-hole.

### 5a. Render the deck (`pptx`, the default)

Write a JSON spec - the shape is documented at the top of
`generate_brief_pptx.py`, which sits next to this file - then render it:

```bash
python3 <skill-dir>/generate_brief_pptx.py spec.json \
  -o docs/briefs/$(date +%Y-%m-%d)-brief.pptx
```

Run from the repo root so repo-relative `image` paths resolve. Needs
python-pptx: use a project venv, `pip install --user python-pptx`, or
`uv run --with python-pptx python3 ...`.

Per feature the spec wants: `area` (the eyebrow, uppercased), `title`, `lead`
(1-2 benefit-first sentences), and exactly three `cards` - typically What /
How it works / Why it matters, each body under ~220 characters. Optional per
feature: `caption` (the "▶" demo line) and `image` (repo-relative screenshot
path - when present the shot replaces the card row). Add `next` rows from
`docs/todo.md` or the board's open epics for the dark "looking ahead" closer.

The generator owns the design system - 16:9, dark title and closer, an
at-a-glance agenda, numbered light feature slides with white cards, teal badges,
Georgia/Calibri. **Do not restyle it from the spec.** If a new slide type is
genuinely needed, extend the generator using the same tokens.

### 5b. Render the page (`md`)

```markdown
# Ship Brief — June 28, 2026

_A rundown of what shipped since the last brief (June 21 – June 28)._

## ✨ Build multi-step sessions from several patterns

![Multi-step sessions](assets/2026-06-28/multi-step-sessions.png)

Therapists can now chain several movement patterns into a single guided session
and set a per-step dosage for each. One session can walk a patient through a
whole protocol instead of being limited to a single movement — closer to how a
real rehab plan is actually structured.

---

_Also shipped: documentation for recording sessions against the deployed app._
```

One short `##` card per feature: emoji + plain-language title, the screenshot if
there is one, then 2-4 sentences of benefit-first copy. No hashes, no filenames,
no "we refactored" - say what is now possible. Close with a one-line
"Also shipped:" for noteworthy docs/infra work.

### 6. Check and commit

- Reopen a rendered deck with python-pptx and confirm the slide count: title +
  at-a-glance + one per feature (+ looking-ahead). Trim any card body that
  overflows.
- Commit **only** the brief and its assets - never `git add -A`:

```bash
git add docs/briefs/<name> && git commit -m "docs(brief): what shipped <range>"
```

- Follow the repo's ticket rules if it has them; a brief is granular work, so
  slot it under the docs/tooling epic rather than opening a top-level ticket.
- Tell the user the path, the window covered, and offer to open it.

## Notes

- Tone for both formats: **stakeholder, benefit-first.** No commit hashes, no
  file lists, no engineering minutiae. Respect the repo's customer-facing copy
  rules where it has them.
- The screenshot routing above is tuned for a Next.js app; in another project
  apply the same strategy (page file -> route, component -> hosting page,
  backend -> text-only) with that framework's conventions.
