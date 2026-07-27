# Setting this up on a new machine — notes for Claude

You are Claude Code, asked to set up this dotfiles repo on a fresh machine.
Read this before running anything. It exists so you don't re-derive things that
already cost hours on the original machine.

## 1. Install

```bash
git clone https://github.com/nbaker47/dotfiles ~/dotfiles
~/dotfiles/bootstrap.sh
```

Installs Homebrew (if missing), everything in `packages/Brewfile`, the non-brew
tools (oh-my-zsh, powerlevel10k, bun, Claude Code, npm globals, uv tools), then
symlinks configs. Order matters — `shell/zshrc` sources oh-my-zsh.

Then **quit and reopen iTerm2** (⌘Q, not ⌘W) so it loads prefs from `iterm/`.

## 2. Verify (don't assume — run these)

```bash
ls -l ~/.zshrc                  # -> ~/dotfiles/shell/zshrc
ls -l ~/.tmux.conf              # -> ~/dotfiles/tmux/tmux.conf
ls -l ~/.claude/settings.json   # -> ~/dotfiles/claude/settings.json
command -v herdr tmux jq gh     # all present (jq is needed by some helpers)

# In a NEW shell (functions don't exist in shells started before the symlink):
type therdr agentpane agentbalance grid
```

`herdr integration status` should show `claude: current`. If not:
`herdr integration install claude`.

## 3. How agents work here — read before spawning any

The machine runs **herdr** as the terminal workspace manager: it owns the
sidebar, spaces, tabs and panes, and it runs *inside* one iTerm2 session. This
breaks the obvious assumptions, so pick deliberately:

| Goal | Command | Cost |
|---|---|---|
| Watch teammates work in panes | `therdr` | herdr sidebar won't track the session |
| Keep the herdr sidebar working | plain `claude` | teammates run in-process — working, but invisible |
| Visible panes AND sidebar tracking | `agentpane <name> [cwd] [prompt]` | separate sessions, not a real team (no shared context/SendMessage) |

- `teammateMode` is pinned to `in-process` in `claude/settings.json`. Do NOT set
  it back to `auto`: outside tmux, `auto` picks the iterm2 backend and the Agent
  tool **fails outright** ("Session '<uuid>' not found"), it does not degrade.
- The mode is snapshotted at process start — editing settings.json does nothing
  to a running session. Restart claude.
- `therdr` passes `--teammate-mode tmux` and `--dangerously-skip-permissions`,
  and configures the pane layout so the orchestrator doesn't get squeezed.
- `agentpane` splits the widest pane 50/50, starts the agent with bypass
  permissions, and rebalances via `agentbalance`. Drive those agents with
  `herdr agent read|prompt|send-keys|list <name>`.

**Don't spend time trying to make herdr track a tmux-wrapped session.** Eight
approaches were tested and ruled out — see `docs/agent-teams-herdr.md`. Summary:
herdr binds agents by scanning a pane's foreground process group, tmux's
client/server split hides claude from it, and `pane.report_agent` is accepted
but never applied.

## 4. Gotchas that already bit us

- **`--allowedTools` is variadic.** `claude --allowedTools 'A,B' "prompt"`
  swallows the prompt as another tool rule. Put the prompt FIRST, flags after.
- **Permission prompts vary in option count.** Some are `1. Yes / 2. No`, others
  `1. Yes / 2. Yes-and-allow / 3. No`. Blindly sending `2` answers *No* on the
  two-option form. Always read the pane before answering.
- **Shell functions need a new shell.** Editing `zshrc` does not affect running
  herdr panes; `source ~/.zshrc` or open a new pane.
- **`ITERM_SESSION_ID` goes stale.** herdr shells are daemon-backed and survive
  an iTerm2 restart, so the inherited value stops resolving. `iterm-fixsession`
  is gone (it wasn't the real fix); just don't rely on iTerm2 pane APIs here.
- **Verify with `ps` carefully.** `ps aux | grep -c 'foo --loop'` matches the
  grep's own command line and reports false positives. Use `[f]oo` or check the
  pane.

## 5. Conventions this machine expects

- Conventional Commits; no `Co-Authored-By: Claude` trailer, no "Generated with"
  footer. Commit granularly without being asked.
- Loose ends go in `docs/todo.md` at the project root, not just chat.
- Parallel sessions register a file in `~/.claude/comm/<label>.md` — skim the
  first line of each at session start; write only your own.
