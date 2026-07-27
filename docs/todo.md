# dotfiles — todo

## Try bakr (2026-07-28)
- **bakr is live**: the herdr fork at `~/Code/bakr` (repo nbaker47/bakr) with NATIVE
  Claude Agent Teams — teammates spawn as real bakr panes (verified e2e: lead +
  teammate `@probe`, SendMessage round-trip, sidebar labels). Installed at
  `~/.local/bin/bakr`; run `bakr` in a fresh terminal (it refuses to nest inside
  herdr). Inside bakr panes plain `claude` gets `--teammate-mode auto` via a zshrc
  alias, so teams just work. `bakr harness install` pulls the claude-harness kit
  into any repo; the claude integration hook installs itself on first server start.
- **Migration when ready**: bakr and herdr coexist (separate sockets/config/state).
  When you switch daily driver to bakr, retire `therdr` and consider flipping
  `teammateMode` in settings.json back to `auto`.
- **Known cosmetic gap**: teammate panes show `agent: None` in `bakr pane list`
  (screen-content detection doesn't bind the teammate claude UI yet) — label,
  title, and agent_session all work; tracked in ~/Code/bakr/docs/todo.md.

## Blocking (you must do)
- ~~**Fully QUIT iTerm2 (⌘Q) to activate the Python API**~~ — **done, and it turned
  out to be the wrong fix anyway.** iTerm2 restarted 2026-07-27 15:07 and the API
  socket is live (`EnableAPIServer=1`), but native iTerm2 split-pane teammates are
  still not what we want **under herdr** — see the resolved note below. Kept only
  because the Python API is still needed for non-herdr iTerm2 use.
- **Quit and reopen iTerm2** so it loads prefs from `~/dotfiles/iterm` (yaquake
  dropdown hotkey + keymaps won't apply until relaunch). Same restart covers both.
- **(Optional) Make the repo public** if you still want that — Claude's safety
  classifier hard-blocks pushing personal config to a *public* repo, so it was
  created **private** at https://github.com/nbaker47/dotfiles. Flip in GitHub →
  Settings → Danger Zone → Change visibility. Files are audited-clean (no secrets).
- On each *other* machine: `git clone https://github.com/nbaker47/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh`.

## Follow-ups
- **Agent kit now also ships via claude-harness (2026-07-28)** — the plugins +
  marketplaces + Agent Teams flags from `claude/settings.json` and the vendored
  skills in `agents/skills/` are mirrored as `kit/` in
  https://github.com/nbaker47/claude-harness (`kit/install-kit.sh`, global,
  idempotent, add-if-absent). Dotfiles remains the source of truth on this machine
  (live symlink targets — do not delete the copies here); new machines can use
  either installer. When adding a plugin/skill here, refresh the harness `kit/`
  copy so the two stay equivalent.
- **Remove the old curl-installed herdr**: `rm ~/.local/bin/herdr`. `herdr` is now a
  Homebrew formula (`brew install herdr`, tracked in `packages/Brewfile`), but
  `~/.local/bin` comes earlier in PATH so the old binary shadows it — Homebrew warns
  about this on install. Both are 0.7.5 today, so nothing is broken; they'll diverge
  the first time you `brew upgrade`. Left in place because I didn't install it.
  After removing it, upgrade with `brew upgrade herdr`, not `herdr update`.
- `packages/Brewfile` tracks the tools installed as of 2026-07-27. Run
  `packages/sync.sh` occasionally — it reports anything installed but untracked.
- Tools deliberately *not* in the Brewfile because they self-update or aren't in
  brew: oh-my-zsh, powerlevel10k, bun, Claude Code, the npm globals (clawhub,
  eas-cli, firebase-tools, mobai-mcp) and uv tools (nano-pdf). These live in
  `packages/install.sh` — add new ones to the arrays near the bottom of that file.
- `steipete/tap` is tapped but nothing is installed from it; the tap line is kept in
  the Brewfile so a new machine matches. Drop it if you don't want it.
- Stale `~/Code/misc/karibiner.json` (3.4 KB, Nov 2025) is an old partial copy of
  the Karabiner config — superseded by `~/dotfiles/karabiner/karabiner.json`. Delete
  it to avoid confusion (left in place for now; not my call to remove).
- claude-mem memories (`~/.claude-mem/`, multi-GB) are machine-local by design. If you
  want them on another machine, rsync/Syncthing the dir with the worker stopped — not git.

## Done
- **Agent teams under herdr fixed (2026-07-27)** — `therdr` in `shell/zshrc` runs
  claude inside tmux inside a herdr pane with `--teammate-mode tmux` pinned, so
  teammates spawn as visible tmux panes. Root cause was `teammateMode: auto`:
  outside tmux it picks the iterm2 backend and fails on a stale
  ITERM_SESSION_ID (herdr shells outlive iTerm2 restarts); inside tmux it
  silently degrades to in-process, so teammates work but are invisible. Full
  write-up: `docs/agent-teams-herdr.md`. Also added `agentpane` for spawning
  separate agents into herdr panes via its socket API.
- **iTerm2 native split panes for teammates (2026-07-27)** — `it2` CLI added to the uv
  tools in `packages/install.sh`; iTerm2's Python API (`EnableAPIServer`) enabled by
  `bootstrap.sh` and committed into the tracked plist. A new machine no longer sees the
  "iTerm2 Split Pane Setup" prompt. Still needs a one-time iTerm2 restart (see Blocking).
- **`packages/` layer added (2026-07-27)** — `Brewfile` (26 formulae + 11 casks incl.
  herdr), `install.sh` (brew bundle + oh-my-zsh, p10k, bun, Claude Code, npm globals,
  uv tools), `sync.sh` (drift report). `bootstrap.sh` runs packages before symlinks.
  Evaluated Nix/nix-darwin and stayed on Homebrew — rationale in README.
- **Fixed `shell/zshrc` bug**: it unconditionally sourced
  `~/.openclaw/completions/openclaw.zsh`, which doesn't exist — every new interactive
  shell printed `no such file or directory`. Now guarded with `[ -s ... ] &&`, like
  the bun line. Also made the hardcoded `/Users/user` paths use `$HOME`.
- Unified dotfiles repo at `~/dotfiles` (claude, shell, tmux, karabiner, iterm, git).
- `bootstrap.sh` symlinks all configs into place (idempotent, backs up originals).
- Live files converted to symlinks; iTerm pointed at repo's `iterm/` folder.
- Global `~/.claude/CLAUDE.md` gained: parallel-session comm (`~/.claude/comm/`) +
  Conventional Commits block.

## /brief skill follow-ups
- [ ] Live-test `/brief` end-to-end (run against the 2026-06-28 IHS commits). Untested so far.
- [ ] Confirm claude-in-chrome screenshots actually land as PNGs in ~/Code/briefs/assets/<date>/ — the SKILL assumes a saved-file path; adjust wording if the tool returns inline images only.
