#!/usr/bin/env bash
# Dotfiles bootstrap — symlinks every managed config into place.
# Idempotent: safe to re-run. Existing real files are backed up first.
#
#   git clone <repo> ~/dotfiles && ~/dotfiles/bootstrap.sh
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
linked=0; backed_up=0

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

# iTerm2 — can't symlink the plist (iTerm rewrites it); instead point iTerm at
# the repo's iterm/ folder as its prefs source. iTerm reads on launch, writes on
# quit, so the yaquake dropdown + keymaps stay versioned automatically.
echo "==> Pointing iTerm2 at $REPO/iterm"
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$REPO/iterm"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
echo "  iTerm2: QUIT AND REOPEN iTerm for prefs (yaquake hotkey, keymaps) to load."

# Reload what we can without a restart
command -v tmux >/dev/null && tmux source-file "$HOME/.tmux.conf" 2>/dev/null && echo "==> tmux reloaded" || true
pgrep -x karabiner_console_user_server >/dev/null 2>&1 && \
  echo "==> Karabiner picks up karabiner.json automatically (it watches the file)." || true

echo
echo "Done. linked=$linked backed_up=$backed_up"
[ "$backed_up" -gt 0 ] && echo "Backups of replaced files: $BACKUP"
echo "Open a new shell (or 'source ~/.zshrc') and run 'grid' for the 2x2 Claude tmux."
