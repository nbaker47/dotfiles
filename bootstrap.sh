#!/usr/bin/env bash
# Dotfiles bootstrap — installs every tool, then symlinks every managed config.
# Idempotent: safe to re-run. Existing real files are backed up first.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/bootstrap.sh
#
# Flags:
#   --links-only      skip package installation, just symlink configs (fast)
#   --packages-only   only install packages, don't touch symlinks
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
linked=0; backed_up=0

do_packages=1; do_links=1
for arg in "$@"; do
  case "$arg" in
    --links-only)    do_packages=0 ;;
    --packages-only) do_links=0 ;;
    -h|--help)       sed -n '2,10p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown flag: $arg (try --help)" >&2; exit 2 ;;
  esac
done

# Packages first: the configs we link below assume these exist — zshrc sources
# oh-my-zsh, and the `grid` function needs tmux.
if [ "$do_packages" -eq 1 ]; then
  "$REPO/packages/install.sh"
fi

if [ "$do_links" -eq 0 ]; then
  echo; echo "Packages done (--packages-only; symlinks untouched)."; exit 0
fi

# link <repo-relative-source> <absolute-target>
link() {
  local src="$REPO/$1" dst="$2"
  [ -e "$src" ] || { echo "  ! missing in repo: $1 (skipped)"; return; }
  mkdir -p "$(dirname "$dst")"
  # already correctly linked?
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  = $dst"; return
  fi
  # back up an existing real file / wrong link
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$(dirname "$BACKUP/${dst#$HOME/}")"
    mv "$dst" "$BACKUP/${dst#$HOME/}"
    backed_up=$((backed_up+1))
  fi
  ln -s "$src" "$dst"
  echo "  + $dst -> $src"; linked=$((linked+1))
}

echo "==> Linking dotfiles from $REPO"

# Claude Code
link claude/CLAUDE.md        "$HOME/.claude/CLAUDE.md"
link claude/settings.json    "$HOME/.claude/settings.json"
link claude/comm/README.md   "$HOME/.claude/comm/README.md"
link claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"
# (settings.local.json is intentionally machine-local and NOT linked)

# Shell (zsh + powerlevel10k + the `grid` tmux Claude launcher live in zshrc)
link shell/zshrc    "$HOME/.zshrc"
link shell/zprofile "$HOME/.zprofile"
link shell/p10k.zsh "$HOME/.p10k.zsh"

# tmux (2x2 auto-tiled grid)
link tmux/tmux.conf "$HOME/.tmux.conf"

# Karabiner-Elements (SEFD/JKL nav layer)
link karabiner/karabiner.json "$HOME/.config/karabiner/karabiner.json"

# git
link git/gitconfig "$HOME/.gitconfig"

# Agent skills — vendored content lives in the repo; symlinking ~/.agents/skills
# back into it means future `npx skills add ...` installs auto-track in git.
link agents/skill-lock.json "$HOME/.agents/.skill-lock.json"
link agents/skills          "$HOME/.agents/skills"
# Recreate the per-skill symlinks Claude Code reads from ~/.claude/skills/<name>
if [ -d "$REPO/agents/skills" ]; then
  mkdir -p "$HOME/.claude/skills"
  n=0
  for d in "$REPO/agents/skills"/*/; do
    name="$(basename "$d")"; target="../../.agents/skills/$name"; lnk="$HOME/.claude/skills/$name"
    if [ -L "$lnk" ] && [ "$(readlink "$lnk")" = "$target" ]; then continue; fi
    rm -rf "$lnk"; ln -s "$target" "$lnk"; n=$((n+1))
  done
  echo "==> Skills linked into ~/.claude/skills (refreshed $n)"
fi

# iTerm2 — can't symlink the plist (iTerm rewrites it); instead point iTerm at
# the repo's iterm/ folder as its prefs source. iTerm reads on launch, writes on
# quit, so the yaquake dropdown + keymaps stay versioned automatically.
echo "==> Pointing iTerm2 at $REPO/iterm"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$REPO/iterm"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# Python API (Settings > General > Magic > Enable Python API), for the `it2` CLI.
# NOTE: this is NOT how teammates get panes on a herdr machine. iTerm2 splits land
# *beside* herdr, outside its pane system, and fail outright when the inherited
# ITERM_SESSION_ID has gone stale (herdr shells survive iTerm2 restarts). Use
# `therdr` (tmux inside the herdr pane) or `agentpane` instead -- see
# docs/agent-teams-herdr.md. Kept enabled only for non-herdr iTerm2 use.
defaults write com.googlecode.iterm2 EnableAPIServer -bool true
echo "  iTerm2: Python API enabled (for it2 / teammate split panes)."
echo "  iTerm2: QUIT AND REOPEN iTerm for prefs (yaquake hotkey, keymaps, Python API) to load."

# Reload what we can without a restart
command -v tmux >/dev/null && tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "==> tmux reloaded" || true
pgrep -x karabiner_console_user_server >/dev/null 2>&1 && \
  echo "==> Karabiner picks up karabiner.json automatically (it watches the file)." || true

echo
echo "Done. linked=$linked backed_up=$backed_up"
[ "$backed_up" -gt 0 ] && echo "Backups of replaced files: $BACKUP"
echo "Open a new shell (or 'source ~/.zshrc') and run 'grid' for the 2x2 Claude tmux."
