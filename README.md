# dotfiles

Personal machine config, version-controlled and synced across computers. One
`bootstrap.sh` **installs every tool** and symlinks every config into place.

## New machine

```bash
git clone <this-repo-url> ~/dotfiles
~/dotfiles/bootstrap.sh
```

That installs Homebrew if missing, everything in `packages/Brewfile` (herdr, tmux,
gh, terraform, the casks…), then the non-brew tools (oh-my-zsh, powerlevel10k, bun,
Claude Code, npm globals, uv tools) — and only then symlinks the configs, since
`shell/zshrc` sources oh-my-zsh and needs it to exist.

Then **quit and reopen iTerm2** (so it loads prefs from this repo), open a new
shell, and run `grid` for the 2×2 Claude tmux layout.

**Setting this up with Claude?** Point it at
[`docs/for-claude-on-a-new-machine.md`](docs/for-claude-on-a-new-machine.md) —
install + verification steps, how the agent helpers (`therdr`, `agentpane`)
work under herdr, and the gotchas that already cost hours here.

```bash
~/dotfiles/bootstrap.sh --links-only     # skip installs, just re-link configs (fast)
~/dotfiles/bootstrap.sh --packages-only  # install/update tools, leave symlinks alone
```

## Packages

| Path | What |
|------|------|
| `packages/Brewfile` | Every Homebrew formula + cask. Edit this to add a tool. |
| `packages/install.sh` | Brew bundle, then the tools Homebrew doesn't carry. Idempotent. |
| `packages/sync.sh` | Read-only drift report: installed-but-untracked vs tracked-but-missing. |

Adding a tool: `brew install foo`, then add `brew "foo"` to the Brewfile. Run
`packages/sync.sh` any time to catch things you installed and forgot to track.

The Brewfile deliberately lists only **top-level** packages (`brew leaves`-style),
not the ~100 transitive dependencies — Homebrew resolves those itself, and listing
them would make the file unreadable and churn on every upgrade.

### Why Homebrew and not Nix

Considered and rejected for this setup: a third of the list is macOS GUI casks
(Docker Desktop, Godot, Rectangle) that nix-darwin ends up delegating to Homebrew
anyway; `herdr` and `claude` ship their own self-updaters that fight Nix's
immutable store; and the macOS-specific bits here (the iTerm2 `defaults write`,
Karabiner) already work fine in plain bash. Nix pays off across many machines and
per-project dev shells — this is one Mac, so it'd be a rewrite plus a new language
for no reproducibility win. `brew bundle` covers it in one declarative file.

## What's in here

| Path | Symlinks to | What |
|------|-------------|------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global Claude Code instructions (resume cmd, Agent Teams coordination, commits, todo.md) |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings - enabled plugins (incl. **claude-mem**) + marketplaces, plus **Agent Teams** always on (see below). Plugins auto-install from these on first run. |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Claude Code status line, ported from the zsh PS1: `[dir] [git branch] [k8s ns@cluster] <model>` |
| `shell/zshrc` | `~/.zshrc` | zsh + oh-my-zsh + p10k; aliases; the **`grid`** 2×2 Claude tmux launcher |
| `shell/zprofile` | `~/.zprofile` | Homebrew shellenv |
| `shell/p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt |
| `tmux/tmux.conf` | `~/.tmux.conf` | mouse on; `prefix+e` + auto re-tile to a clean 2×2 grid |
| `karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | Karabiner-Elements: SEFD arrows + JKL modifiers nav layer (hold `;`) |
| `git/gitconfig` | `~/.gitconfig` | git identity/config |
| `agents/skills/` | `~/.agents/skills` | Agent skills (vendored). `~/.claude/skills/<name>` symlinks are rebuilt by bootstrap. New `npx skills add ...` installs land here and auto-track. |
| `agents/skill-lock.json` | `~/.agents/.skill-lock.json` | Skill install manifest |
| `iterm/com.googlecode.iterm2.plist` | *iTerm custom prefs folder* | iTerm2 — **yaquake** dropdown profile (hotkey), keymaps, profiles |
| `packages/Brewfile` | *(not a symlink)* | Homebrew formulae + casks, installed by `bootstrap.sh` |

## Agent Teams (on by default)

`claude/settings.json` carries the two keys that turn it on, so a bootstrapped machine
has it without any per-machine setup:

```json
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
"teammateMode": "auto"
```

The env var enables spawning teammates (peer agents with their own context that keep
running, as opposed to subagents that return a report and exit). `teammateMode: auto`
opens each one in its own split pane, which is why the `grid` layout and
`tmux/tmux.conf` matter here: with no pane to open, teammate-spawning commands fall
back to running inline.

### Native iTerm2 split panes (instead of tmux)

Teammates can open as **native iTerm2 splits** rather than a separate tmux session.
Claude Code prompts to set this up the first time; bootstrap does it up front so the
prompt never appears on a new machine. Two pieces, both tracked here:

1. **`it2` CLI** — a uv tool, listed in `packages/install.sh`.
2. **iTerm2's Python API** — `EnableAPIServer`, set by `bootstrap.sh` and committed in
   `iterm/com.googlecode.iterm2.plist`. It's the GUI's
   *Settings → General → Magic → Enable Python API*.

**The API server only starts at launch, so iTerm2 must be restarted once after
enabling it.** Until then `it2` fails with "There was a problem connecting to iTerm2"
and teammates fall back to tmux. Verify with `it2 app theme` — it should print the
theme rather than a connection error. The first connection also raises an iTerm2
permission prompt to approve.

## The agent kit is also installable via claude-harness

The agent kit — the plugins + marketplaces in `claude/settings.json` (claude-mem,
frontend-design, gopls-lsp + the thedotmack marketplace), the Agent Teams flags, and
the vendored skills in `agents/skills/` — is mirrored in
[nbaker47/claude-harness](https://github.com/nbaker47/claude-harness) as `kit/`, with
`kit/install-kit.sh` installing it globally into `~/.claude`.

- **On this machine, dotfiles stays the source of truth.** Everything is symlinked
  from here (`~/.claude/settings.json`, `~/.agents/skills`, the per-skill links in
  `~/.claude/skills`), and the harness installer respects that: its settings merge is
  add-if-absent (it writes *through* the symlink into this repo, and is a no-op when
  the keys are already set), and it skips any skill already present rather than
  fighting the symlinks. Do NOT delete the copies here — they are live symlink targets.
- **On a new machine you can get the kit either way**: `bootstrap.sh` (full dotfiles —
  shell, iTerm2, packages, the lot) or `claude-harness/kit/install-kit.sh` (just the
  Claude agent kit, no shell/terminal config). Running both is safe; whichever comes
  second finds everything in place and changes nothing.
- When the kit changes here (new plugin, new skill), refresh the harness's `kit/` copy
  so both installers stay equivalent.

## How each piece syncs

- **Symlinked files** (claude, shell, tmux, karabiner, git): edits to the live
  file write straight through to the repo. `git add -p && git commit && git push`,
  then `git pull` on the other machine — no copying.
- **iTerm2** is special: it constantly rewrites its plist, so it can't be a
  symlink. Instead bootstrap sets iTerm's *"Load preferences from a custom
  folder"* to `iterm/`. iTerm reads it on launch and writes it back on quit, so
  changes you make in iTerm's UI land in the repo. After changing iTerm settings,
  **quit iTerm** (to flush), then commit `iterm/com.googlecode.iterm2.plist`.

  Two things to know about that plist:

  - **iTerm2 writes it as XML**, and only exports the *syncable* settings — it drops
    `NoSync*` keys, window frames, Sparkle updater state and Apple system keys. So it
    is much smaller than a raw copy of `~/Library/Preferences/com.googlecode.iterm2.plist`
    (29 keys vs 76). That's correct: profiles, keymaps and the yaquake hotkey are all
    in the exported set; the dropped keys are machine-local by design.
  - **Use `plutil`, not Python, to read or edit it.** The XML embeds raw control
    characters from the keymap escape sequences, so `plistlib`/expat fails with
    "not well-formed"; `file` even reports it as `data`. `plutil` handles it:

    ```bash
    plutil -extract EnableAPIServer raw -o - iterm/com.googlecode.iterm2.plist
    plutil -replace EnableAPIServer -bool true iterm/com.googlecode.iterm2.plist
    plutil -remove  SomeKey                    iterm/com.googlecode.iterm2.plist
    ```

    If you do need Python, convert a *copy* to binary first
    (`plutil -convert binary1 -o /tmp/x.plist …`) and parse that.

## NOT synced here (deliberately)

- `~/.claude/settings.local.json` — per-machine permission grants; stays local.
- **claude-mem's memory store** lives in `~/.claude-mem/` (a multi-GB SQLite DB +
  vector index) — far too big/churny for git. The *plugin* syncs via
  `settings.json`; the *memories themselves* are machine-local. To carry them to
  another machine, copy `~/.claude-mem/` with the worker stopped (rsync/Syncthing),
  not git.
- Secrets, tokens, credentials — never. (`bootstrap.sh` only links the files listed
  above.)

## Updating

Edit configs normally on whichever machine. Then:

```bash
cd ~/dotfiles && git add -A && git commit -m "chore: update <thing>" && git push
# other machine:
cd ~/dotfiles && git pull   # symlinks already point here, so it's live immediately
```
