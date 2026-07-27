#!/usr/bin/env bash
# Reports drift between what's installed on this Mac and what packages/Brewfile
# tracks, so the repo doesn't quietly go stale.
#
#   ~/dotfiles/packages/sync.sh
#
# Read-only — it never edits the Brewfile or installs anything. Copy the lines it
# prints into packages/Brewfile (or `brew uninstall` what you no longer want).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$REPO/packages/Brewfile"
IGNORE="$REPO/packages/.sync-ignore"

# Lines like `brew "gh"` / `cask "godot"` -> bare names.
tracked() { grep -oE "^${1} \"[^\"]+\"" "$BREWFILE" | cut -d'"' -f2 | sort -u; }

# Deliberately-untracked packages, so they don't show up as drift forever.
ignored() {
  [ -f "$IGNORE" ] || { echo; return; }
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "$IGNORE" | grep -v '^$' | sort -u
}

# Only packages installed deliberately — not dependencies pulled in by others.
installed_formulae() { comm -23 <(brew list --installed-on-request --formula | sort -u) <(ignored); }
installed_casks()    { comm -23 <(brew list --cask | sort -u) <(ignored); }

drift=0
report() { # report <label> <installed-list> <tracked-list> <keyword>
  local label="$1" only_installed only_tracked
  only_installed="$(comm -23 <(echo "$2") <(echo "$3"))"
  only_tracked="$(comm -13 <(echo "$2") <(echo "$3"))"

  if [ -n "$only_installed" ]; then
    drift=1
    printf '\n\033[1mInstalled but NOT in Brewfile (%s)\033[0m — add these:\n' "$label"
    while read -r p; do [ -n "$p" ] && printf '  %s "%s"\n' "$4" "$p"; done <<<"$only_installed"
  fi
  if [ -n "$only_tracked" ]; then
    drift=1
    printf '\n\033[1mIn Brewfile but NOT installed (%s)\033[0m — run install.sh, or drop the line:\n' "$label"
    while read -r p; do [ -n "$p" ] && printf '  %s\n' "$p"; done <<<"$only_tracked"
  fi
}

report "formulae" "$(installed_formulae)" "$(tracked brew)" "brew"
report "casks"    "$(installed_casks)"    "$(tracked cask)" "cask"

if [ "$drift" -eq 0 ]; then
  echo "Brewfile is in sync with this machine."
else
  printf '\nNote: the Brewfile intentionally tracks only top-level packages;\n'
  printf 'Homebrew resolves dependencies itself.\n'
fi
