# dotfiles — todo

## Blocking (you must do)
- **Restart iTerm2 to activate the Python API** (needed for native split-pane
  teammates). `EnableAPIServer` is now set in both the live prefs domain and
  `iterm/com.googlecode.iterm2.plist`, but iTerm2 only starts the API server at
  launch — I couldn't restart it because this Claude session is running *inside*
  iTerm2. After relaunching, check it with:
  ```bash
  it2 app theme     # should print the theme, not a connection error
  ```
  The first connection also pops an iTerm2 permission prompt — approve it. Until
  this is done, teammates keep falling back to a separate tmux session.
- **Quit and reopen iTerm2** so it loads prefs from `~/dotfiles/iterm` (yaquake
  dropdown hotkey + keymaps won't apply until relaunch). Same restart covers both.
- **(Optional) Make the repo public** if you still want that — Claude's safety
  classifier hard-blocks pushing personal config to a *public* repo, so it was
  created **private** at https://github.com/nbaker47/dotfiles. Flip in GitHub →
  Settings → Danger Zone → Change visibility. Files are audited-clean (no secrets).
- On each *other* machine: `git clone https://github.com/nbaker47/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh`.

## Follow-ups
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
