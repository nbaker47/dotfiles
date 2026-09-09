#!/usr/bin/env bash
# Claude Code WorktreeRemove hook - the counterpart of worktree-create.sh.
#
# Removes the worktree directory and, when the branch is the one create made
# (worktree-<name>), the branch too - the same outcome as Claude Code's built-in
# removal, which drops both. Never touches a worktree outside the parking lot
# ($CLAUDE_WORKTREE_ROOT, default ~/worktrees), so a hand-made worktree elsewhere
# is left alone.
set -euo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.worktree_path // .path // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[ -n "$path" ] || { echo "worktree-remove: no worktree_path in hook input" >&2; exit 0; }

root="${CLAUDE_WORKTREE_ROOT:-$HOME/worktrees}"
case "$path" in
  "$root"/*) ;;
  *) echo "worktree-remove: $path is outside $root, leaving it alone" >&2; exit 0 ;;
esac
[ -d "$path" ] || { echo "worktree-remove: $path already gone" >&2; exit 0; }

common="$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
[ -n "$common" ] || { rm -rf "$path"; exit 0; }
main="$(dirname "$common")"
branch="$(git -C "$path" symbolic-ref -q --short HEAD 2>/dev/null || true)"
name="$(basename "$path")"

git -C "$main" worktree unlock "$path" >/dev/null 2>&1 || true
git -C "$main" worktree remove --force "$path" >&2
if [ "$branch" = "worktree-$name" ]; then
  git -C "$main" branch -D "$branch" >&2 || true
fi
git -C "$main" worktree prune >&2 || true
rmdir "$(dirname "$path")" 2>/dev/null || true   # drop the empty <repo>/ folder
echo "worktree-remove: removed $path" >&2
