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

## Multi-agent coordination — use Agent Teams

I run several agents at once. Coordinate through **Agent Teams**, not a shared file:
use `SendMessage` to hand off, flag conflicts, and report status, and the shared task
list to claim lanes. Within a bakr session teammates spawn as visible panes, so the
team roster is the picture of who is doing what.

The old `~/.claude/comm/` status-file convention is **retired** — Agent Teams replaces
it. Do not create or read `~/.claude/comm/` files.

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
