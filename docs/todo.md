# dotfiles — todo

## Blocking (you must do)
- **Quit and reopen iTerm2** so it loads prefs from `~/dotfiles/iterm` (yaquake
  dropdown hotkey + keymaps won't apply until relaunch).
- **(Optional) Make the repo public** if you still want that — Claude's safety
  classifier hard-blocks pushing personal config to a *public* repo, so it was
  created **private** at https://github.com/nbaker47/dotfiles. Flip in GitHub →
  Settings → Danger Zone → Change visibility. Files are audited-clean (no secrets).
- On each *other* machine: `git clone https://github.com/nbaker47/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh`.

## Follow-ups
- Stale `~/Code/misc/karibiner.json` (3.4 KB, Nov 2025) is an old partial copy of
  the Karabiner config — superseded by `~/dotfiles/karabiner/karabiner.json`. Delete
  it to avoid confusion (left in place for now; not my call to remove).
- claude-mem memories (`~/.claude-mem/`, multi-GB) are machine-local by design. If you
  want them on another machine, rsync/Syncthing the dir with the worker stopped — not git.

## Done
- Unified dotfiles repo at `~/dotfiles` (claude, shell, tmux, karabiner, iterm, git).
- `bootstrap.sh` symlinks all configs into place (idempotent, backs up originals).
- Live files converted to symlinks; iTerm pointed at repo's `iterm/` folder.
- Global `~/.claude/CLAUDE.md` gained: parallel-session comm (`~/.claude/comm/`) +
  Conventional Commits block.
