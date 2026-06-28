# Global preferences

## End every response with the resume command (crash recovery)

At the **end of every response**, print the Claude Code resume command for the current session, so if
the session suddenly crashes we can jump straight back in:

```
↩️ Resume: claude --resume <current-session-id>
```

Get `<current-session-id>` from the **transcript/task-output path in your own context** (e.g.
`~/.claude/projects/<slug>/<ID>.jsonl` or `…/tasks/<task>.output` under `…/<ID>/`). Do NOT use "newest
`*.jsonl` in the project dir" — multiple Claude agents can run concurrently, each with its own session
file, so the newest one may belong to a different agent. Always show the actual ID, never the
placeholder. Keep it as the final line of the response.

## Parallel-session awareness — `~/.claude/comm/`

I usually run several Claudes at once in different terminals (often ~8), across one or
many projects. Use a single **global** comm directory so every agent knows what the
others are doing — both to avoid clobbering shared work (same files, ports, processes,
devices, CI/cloud sessions) and just for general awareness of who's working on what.

- **Location:** `~/.claude/comm/` (global — spans all projects). **One file per agent:**
  `~/.claude/comm/<your-label>.md`. You write **only your own file**, never edit another
  agent's — so any number of agents can run without ever colliding on the same file.
  (It lives under `~/.claude`, so it's never committed to any repo.)
- **First line is a one-line status**, so others can skim the whole picture without
  reading every entry:
  `🟢 <label> · <project> · <one-line what you're doing> · <YYYY-MM-DD HH:MM TZ>`
  Status glyph: 🟢 active · ⏸️ paused · ✅ done.
- **At session start:** skim everyone's first line (read the dir, it's tiny). Read an
  entry **in full** only when it touches your project or a resource you need. You don't
  have to read all of it — the one-liners are the index.
- **Register your file when you start**, keep it current as you go, and on finish set the
  status to ✅ done (or delete your file). Treat entries with stale timestamps / from
  sessions that have clearly ended as abandoned — don't block on them.
- **Before acting on shared state** — editing a file, or killing/restarting a port,
  process, sim/device, dev server, or CI/cloud session a 🟢 agent owns — check their
  entry first and leave a note in *your* file; wait or redirect if it's truly contended.
- **Identity = your short label + this session's id** (the same id you print for the
  resume command), so a dead session is easy to spot.

Body fields under the one-line header: **Doing · Project (cwd) · Files/areas ·
Owns** (ports · dev servers · devices · CI/cloud · bg jobs) **· Heads-up · Status.**
Create `~/.claude/comm/` if it doesn't exist.

## Commits

- **Conventional Commits.** Every message is `type(optional-scope): summary` —
  imperative, lower-case (`feat(api): add retry`, `fix: handle empty body`,
  `chore: bump deps`). Allowed types: `feat`, `fix`, `chore`, `docs`, `refactor`,
  `test`, `perf`, `build`, `ci`, `style`.
- **Commit granularly — don't wait to be asked.** Whenever a coherent unit of work is
  complete and the tree is in a good state, make a small, focused commit. Push at
  natural checkpoints when the work is ready to share.
- **Never commit secrets** or environment/credential files.
- **Prefer rebase merges** (`gh pr merge --rebase`), not merge commits.
- **No `Co-Authored-By: Claude` trailer** and no "🤖 Generated with Claude Code" footer.

## Track follow-ups in docs/todo.md

Whenever a task leaves loose ends, record them in `docs/todo.md` at the project root
(create the file and `docs/` dir if missing) — do NOT just mention them in chat. This covers:

- **Things the user must do later**: deploys, store/console config, DNS, manual verification,
  credentials, anything outside the code I can't run myself.
- **Things I didn't finish**: stubbed or `TEMP` code, deferred fixes, known bugs left for later,
  partial implementations.

Rules:
- Keep it current: add items as they arise; check off / remove items once they're actually done.
- Each item: a short imperative line, the affected file/path if relevant, and *why* it's pending.
- Group by area or status (e.g. "## Blocking", "## Follow-ups", "## Done") if the list grows.
- When I finish a task, mention in chat that I've updated `docs/todo.md`, but the list itself
  is the source of truth — not the conversation.
