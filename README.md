# dotfiles

Personal machine config, version-controlled and synced across computers. One
`bootstrap.sh` symlinks everything into place.

## New machine

```bash
git clone <this-repo-url> ~/dotfiles
~/dotfiles/bootstrap.sh
```

Then **quit and reopen iTerm2** (so it loads prefs from this repo), open a new
shell, and run `grid` for the 2×2 Claude tmux layout.

## What's in here

| Path | Symlinks to | What |
|------|-------------|------|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global Claude Code instructions (resume cmd, parallel-session comm, commits, todo.md) |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings - enabled plugins (incl. **claude-mem**) + marketplaces, plus **Agent Teams** always on (see below). Plugins auto-install from these on first run. |
| `claude/comm/README.md` | `~/.claude/comm/README.md` | Protocol/template for the global parallel-agent coordination dir |
| `shell/zshrc` | `~/.zshrc` | zsh + oh-my-zsh + p10k; aliases; the **`grid`** 2×2 Claude tmux launcher |
| `shell/zprofile` | `~/.zprofile` | Homebrew shellenv |
| `shell/p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt |
| `tmux/tmux.conf` | `~/.tmux.conf` | mouse on; `prefix+e` + auto re-tile to a clean 2×2 grid |
| `karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | Karabiner-Elements: SEFD arrows + JKL modifiers nav layer (hold `;`) |
| `git/gitconfig` | `~/.gitconfig` | git identity/config |
| `agents/skills/` | `~/.agents/skills` | Agent skills (vendored). `~/.claude/skills/<name>` symlinks are rebuilt by bootstrap. New `npx skills add ...` installs land here and auto-track. |
| `agents/skill-lock.json` | `~/.agents/.skill-lock.json` | Skill install manifest |
| `iterm/com.googlecode.iterm2.plist` | *iTerm custom prefs folder* | iTerm2 — **yaquake** dropdown profile (hotkey), keymaps, profiles |

## Agent Teams (on by default)

`claude/settings.json` carries the two keys that turn it on, so a bootstrapped machine
has it without any per-machine setup:

```json
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" },
"teammateMode": "auto"
```

The env var enables spawning teammates (peer agents with their own context that keep
running, as opposed to subagents that return a report and exit). `teammateMode: auto`
opens each one in its own tmux split pane, which is why the `grid` layout and
`tmux/tmux.conf` matter here: outside tmux there is no pane to open and teammate-spawning
commands fall back to running inline.

## How each piece syncs

- **Symlinked files** (claude, shell, tmux, karabiner, git): edits to the live
  file write straight through to the repo. `git add -p && git commit && git push`,
  then `git pull` on the other machine — no copying.
- **iTerm2** is special: it constantly rewrites its plist, so it can't be a
  symlink. Instead bootstrap sets iTerm's *"Load preferences from a custom
  folder"* to `iterm/`. iTerm reads it on launch and writes it back on quit, so
  changes you make in iTerm's UI land in the repo. After changing iTerm settings,
  **quit iTerm** (to flush), then commit `iterm/com.googlecode.iterm2.plist`.

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
