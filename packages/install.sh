#!/usr/bin/env bash
# Installs every tool this setup depends on.
#
#   ~/dotfiles/packages/install.sh
#
# Two phases:
#   1. Homebrew + everything in packages/Brewfile
#   2. The handful of tools Homebrew doesn't carry (oh-my-zsh, powerlevel10k,
#      bun, Claude Code, npm globals, uv tools)
#
# Idempotent: every step checks first and skips if already present. Safe to
# re-run to pick up newly added packages.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }
say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
skip() { printf '  = %s\n' "$*"; }
did()  { printf '  + %s\n' "$*"; }

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
say "Homebrew"
if ! have brew; then
  did "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  skip "brew already installed"
fi
# Apple Silicon installs to /opt/homebrew, which isn't on PATH until zprofile runs.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

say "Brewfile packages (herdr, tmux, gh, terraform, casks, …)"
# --no-upgrade: install what's missing but don't silently bump everything else;
# upgrade deliberately with `brew upgrade` instead.
# A single failing formula must not abort the run — the phase 2 tools below are
# independent of it. Record the failure and report it at the end instead.
brew_failed=0
brew bundle install --file "$REPO/packages/Brewfile" --no-upgrade || brew_failed=1

say "herdr agent integrations"
# claude/settings.json (symlinked from this repo) registers a SessionStart hook at
# ~/.claude/hooks/herdr-agent-state.sh. That file is generated and owned by herdr —
# it's deliberately NOT vendored into git, because herdr overwrites it on update.
# Regenerate it here so a fresh machine's settings.json isn't pointing at nothing.
HERDR_INTEGRATIONS=( claude codex )
if have herdr; then
  for target in "${HERDR_INTEGRATIONS[@]}"; do
    if herdr integration status 2>/dev/null | grep -qE "^${target}: current"; then
      skip "herdr $target integration"
    else
      did "herdr integration install $target"
      herdr integration install "$target" || echo "  ! failed (non-fatal)"
    fi
  done
else
  echo "  ! herdr not on PATH yet — re-run this script in a new shell"
fi

# ── 2. Things Homebrew doesn't carry ──────────────────────────────────────────

say "oh-my-zsh + powerlevel10k"
# --keep-zshrc is essential: ~/.zshrc is a symlink into this repo and the
# installer would otherwise replace it with its own template.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  did "installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended --keep-zshrc
else
  skip "oh-my-zsh"
fi

P10K="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K" ]; then
  did "cloning powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K"
else
  skip "powerlevel10k"
fi

say "bun"
if [ ! -x "$HOME/.bun/bin/bun" ]; then
  did "installing bun"
  curl -fsSL https://bun.sh/install | bash
else
  skip "bun"
fi

say "Claude Code"
if ! have claude && [ ! -x "$HOME/.local/bin/claude" ]; then
  did "installing claude"
  curl -fsSL https://claude.ai/install.sh | bash
else
  skip "claude"
fi

say "npm global packages"
NPM_GLOBALS=(
  clawhub
  eas-cli          # Expo Application Services
  firebase-tools
  mobai-mcp        # device-automation MCP server
)
if have npm; then
  installed="$(npm ls -g --depth=0 --parseable 2>/dev/null || true)"
  for pkg in "${NPM_GLOBALS[@]}"; do
    if grep -q "/${pkg}\$" <<<"$installed"; then
      skip "$pkg"
    else
      did "npm i -g $pkg"; npm install -g "$pkg"
    fi
  done
else
  echo "  ! npm not found — skipped (expected from the 'node' brew formula)"
fi

say "uv tools"
UV_TOOLS=( nano-pdf )
if have uv; then
  for tool in "${UV_TOOLS[@]}"; do
    if uv tool list 2>/dev/null | grep -q "^${tool} "; then
      skip "$tool"
    else
      did "uv tool install $tool"; uv tool install "$tool"
    fi
  done
else
  echo "  ! uv not found — skipped"
fi

say "Done"
cat <<'EOF'
  Tools installed. Notes:

  - herdr now comes from Homebrew. If you have an older curl-installed copy at
    ~/.local/bin/herdr it will shadow the brew one (that dir is earlier in PATH):
        rm ~/.local/bin/herdr
    Use `brew upgrade herdr` from now on, not `herdr update`.
  - Open a new shell so PATH picks up bun / brew.
  - `packages/sync.sh` reports anything installed here but not tracked in the Brewfile.
EOF

if [ "$brew_failed" -ne 0 ]; then
  printf '\n\033[1m  ! brew bundle reported a failure above\033[0m — the non-brew tools still\n'
  printf '    installed fine. Scroll up for which package, then re-run once fixed.\n'
  exit 1
fi
