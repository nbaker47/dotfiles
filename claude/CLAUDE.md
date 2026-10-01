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

## Worktrees live in ~/worktrees, never in ~/Code

Worktrees must not land in the `~/Code` tree - not as `~/Code/<repo>-<lane>` siblings and
not nested under the checkout. The parking lot is **`~/worktrees/<repo>/<name>`**, one
folder per repo, and `~/Code` holds only real checkouts.

- **Claude-made worktrees** (`--worktree`, `EnterWorktree`, `isolation: worktree`
  subagents, background sessions) already go there: the `WorktreeCreate` /
  `WorktreeRemove` hooks in `~/.claude/settings.json` (`~/.claude/hooks/worktree-*.sh`)
  own creation and cleanup. Do not work around them with `git worktree add`.
- **Hand-made worktrees** follow the same rule:
  `git worktree add ~/worktrees/<repo>/<name> -b <branch>` - never `../<repo>-<name>`.
- **Clean up** when a lane is done: `git worktree remove ~/worktrees/<repo>/<name>` from
  the main checkout, then `git worktree prune`. A worktree with unpushed work is kept
  until its owner decides.
- Existing sibling worktrees (e.g. `~/Code/IHS/platform-*`) are legacy; migrate them to
  the parking lot when convenient, do not create more.

## claude-mem can fill the disk (observer self-recording loop)

The claude-mem plugin's background observer runs headless `claude` sessions in
`~/.claude-mem/observer-sessions`. Those sessions fire claude-mem's own hooks, so the observer
records its own ever-growing prompt as a "user prompt" and loops. It filled the disk twice:
Jul 2026, then Sep 2026, when `~/.claude-mem` reached 147 GB (`chroma/` 106 GB,
`claude-mem.db` 44 GB) against only about 4.5k real observations.

- **Stop the loop:** `~/.claude-mem/settings.json` must have
  `"CLAUDE_MEM_EXCLUDED_PROJECTS": "~/.claude-mem/observer-sessions,~/.claude-mem/observer-sessions/**"`.
  The globs are matched against the full cwd, so a bare `observer-sessions` doesn't match.
  Re-check this after any claude-mem update or reinstall.
- **Check it:** if the Mac is low on disk or `~/.claude-mem` is over about 5 GB, run
  `du -sh ~/.claude-mem/*` and count the `user_prompts` rows over 100 KB from project
  `observer-sessions`.
- **Clean up:** build a clean copy with `~/.claude-mem/cleanup/build_clean.py`, swap it in with the
  worker stopped, and delete `chroma/`, which rebuilds itself from SQLite. Keep every observation
  and summary, including ones tagged `observer-sessions`; they're real memories. The observer's own
  transcripts in `~/.claude/projects/-Users-user--claude-mem-observer-sessions/` are also throwaway;
  delete any older than a day.
- **Full write-up:** `~/Code/docs/claude-mem-observer-loop.md`.
