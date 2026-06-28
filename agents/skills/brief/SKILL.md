---
name: brief
description: >-
  Generate a polished "Ship Brief" — a stakeholder-friendly, screenshot-rich
  rundown of the features shipped in a time window (default: today). Scans every
  git repo under the current directory, coalesces the raw commits into the
  human features they collapse into, captures a screenshot of each visual
  feature by driving the browser, and writes a narrative Markdown brief to
  ~/Code/briefs. Use when the user asks for a "brief", "ship brief", "what did
  we ship/build today", a "feature rundown", "release brief", "changelog with
  screenshots", or a "showcase of today's work".
---

# Ship Brief

Turn a day's worth of raw commits into a **polished, benefit-first feature
brief with screenshots** — the kind of thing you'd send a stakeholder, not a
git changelog. The reader should come away knowing *what is newly possible* and
*see* it, without ever reading a commit hash.

## When to use

Trigger on phrases like: "make me a brief", "/brief", "ship brief", "what did we
ship today", "what did we build today", "feature rundown", "release brief",
"daily showcase", "changelog with screenshots".

Optional argument (`$ARGUMENTS`) selects the window or repo:
- *(none)* → **today** (since local midnight), all repos under cwd.
- `yesterday`, `2026-06-20`, `"3 days ago"`, `"since last friday"` → passed to
  `git log --since=...`. For a single calendar day also pass `--until` to the
  next midnight.
- a repo name (e.g. `platform`) → restrict to that repo.
- combinations: `/brief platform yesterday`.

## Output conventions (do not deviate)

- File: `~/Code/briefs/<YYYY-MM-DD>-ship-brief.md` (use the window's end date; for
  a multi-day range use `<start>_to_<end>-ship-brief.md`).
- Screenshots: `~/Code/briefs/assets/<YYYY-MM-DD>/<feature-slug>.png`, referenced
  from the Markdown with a **relative** path (`assets/<date>/<slug>.png`) so the
  brief renders correctly when the `briefs` folder is moved or committed.
- Title: `# Ship Brief — June 28, 2026` (long-form date).
- Tone: **polished stakeholder brief.** Benefit-first prose. NO commit hashes,
  NO file lists, NO "refactored X" engineering minutiae. Write what a user or a
  non-engineer stakeholder would care about.

## Pipeline

### 1. Discover repos and collect commits

The invocation directory may be a single repo OR a container of nested repos
(e.g. `~/Code/IHS` holds `platform/` and `kinoped/`). Find them all:

```bash
find . -maxdepth 3 -name .git -maxdepth 3 \( -type d -o -type f \) -prune \
  | sed 's,/.git,,' | sort -u
```

For each repo, collect the window's commits with body and changed files:

```bash
git -C "<repo>" log --since=midnight --no-merges \
  --pretty=format:'%h%x09%an%x09%s%x09%b%x1e' --name-only
```

(Swap `--since=midnight` for the user's range; add `--until` for a single day.)
If **no commits** in any repo for the window, tell the user plainly and stop —
do not invent a brief.

### 2. Coalesce commits into features

Raw commits are not features. Collapse them:

- **Drop non-feature noise** from the showcase: `docs`, `chore`, `test`,
  `build`, `ci`, `style`, and pure dependency bumps. (You may mention a notable
  infra/docs item in a short closing line, but it is not a feature card.)
- **Group** the remaining `feat`/`fix`/`perf`/`refactor` commits that belong to
  one shipped capability into a single feature. Strong signals:
  - same Conventional-Commit scope (`feat(sessions:` + `fix(sessions:` → one).
  - a `fix` that touches the same files as a `feat` from the same window is
    almost always polish on that feature — fold it in.
  - commits touching the same route/component cluster.
- **Name each feature** from the user's point of view, not the commit subject.
  `feat(sessions): chain multiple patterns + per-step dosage` →
  *"Build multi-step sessions from several patterns, each with its own dosage."*
- Order features by impact (new user-facing capability > enhancement > fix).

Briefly confirm the coalesced feature list with the user before spending time on
screenshots **only if** it's ambiguous (many commits, unclear grouping);
otherwise proceed.

### 3. Map each feature to a viewable URL

For each feature, find a page that shows it off, from its changed files. This
repo's web app is Next.js (App Router) at
`platform/src/cloud/app/src/app`. Resolution order:

1. **A `page.tsx`/`page.ts` under `app/` changed** → derive the route from its
   folder path. Strip route groups in parentheses (`(dashboard)`, `(auth)`).
   `app/(dashboard)/sessions/page.tsx` → `/sessions`.
2. **A dynamic segment** (`[id]`, `[sessionId]`) in the path → don't guess an
   id. Navigate to the parent list page (`/sessions`), screenshot a real
   instance by clicking the first row, or fall back to the list page itself.
3. **Only a component changed** (e.g. `src/components/live/robot-viewer.tsx`) →
   grep `app/` for who imports it to find the hosting route, then screenshot
   that page:
   ```bash
   grep -rl "robot-viewer" platform/src/cloud/app/src/app
   ```
4. **Only `api/`, `lib/`, prisma, edge-service, or backend files changed** →
   the feature has **no visual surface**. Skip the screenshot; write the card
   with prose only (and, where helpful, a tiny representative code or data
   snippet). Never fabricate a screenshot.

### 4. Capture screenshots — local-first, auto

Pick the screenshot source automatically:

1. **Local dev** (`http://localhost:3000`): probe it
   (`curl -sized -o /dev/null -w '%{http_code}' http://localhost:3000` or a
   browser nav). If it responds AND a session is authenticated, use it — this
   shows the freshest, just-committed code.
2. **Auth check**: navigate to a protected route; if redirected to login,
   prefer an already-authenticated existing Chrome tab/session. If still
   unauthenticated, fall back to the deployed app rather than blocking on login.
3. **Deployed app** fallback: the Cloud Run app
   (`https://kinoped-app-66non5c3ka-uc.a.run.app`, or read the current URL from
   the repo/CLAUDE.md if it changed). Note in the brief's footer which source
   each screenshot came from only if it's the deployed one (so "shipped today
   but not yet deployed" features are honestly flagged).
4. **Nothing reachable** → write the feature cards text-only and add a short
   note at the top: *"Screenshots skipped — no running app was reachable."*

Driving the browser (claude-in-chrome MCP — load via ToolSearch first, batched):
`tabs_context_mcp` → reuse an authed tab or `tabs_create_mcp` → `navigate` →
let the page settle → screenshot. Save each capture as a PNG into
`~/Code/briefs/assets/<date>/<feature-slug>.png`. Frame the **relevant UI** (the
new feature in view), not a generic dashboard. One clean screenshot per feature
is enough; capture a second only if the feature is a flow worth two frames.

Stay disciplined: if a page won't load or auth fails after 2–3 attempts, fall
back (deployed → text-only) and move on. Do not rabbit-hole.

### 5. Write the brief

Template (stakeholder tone — adapt, don't pad):

```markdown
# Ship Brief — June 28, 2026

_A rundown of what shipped today across the Kinoped platform._

## ✨ Build multi-step sessions from several patterns

![Multi-step sessions](assets/2026-06-28/multi-step-sessions.png)

Therapists can now chain several movement patterns into a single guided
session and set a per-step dosage (reps, sets, rest) for each. One session can
walk a patient through a whole protocol instead of being limited to a single
movement — closer to how a real rehab plan is actually structured.

## 🎨 Branded loading experience and a redesigned dashboard

![Running-leg loading screen](assets/2026-06-28/loading-screen.png)

The app now greets you with an on-brand running-leg loading animation and a
dashboard with more visual depth and clearer hierarchy, so the first thing you
see feels like a finished product rather than a blank skeleton.

---

_Also today: documentation for recording sessions against the deployed app with
the local edge stack._
```

Rules for the prose:
- One short `##` card per feature: emoji + plain-language title, screenshot (if
  any), then 2–4 sentences of **benefit-first** copy.
- No hashes, no filenames, no "we refactored". Say what's now possible.
- Close with a one-line "Also today:" for noteworthy docs/infra, if any.
- After writing, tell the user the path and offer to open it.

## Notes

- This skill lives in the user's dotfiles (`~/dotfiles/agents/skills/brief`) and
  is global — it works in any repo, but the screenshot routing above is tuned
  for the IHS/Kinoped Next.js app. In a different project, apply the same
  strategy (page-file → route, component → hosting page, backend → text-only)
  using that project's framework conventions.
- The `~/Code/briefs` folder is the home for every brief; create it if missing.
