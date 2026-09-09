#!/usr/bin/env bash
# Claude Code WorktreeCreate hook - keep worktrees OUT of the code tree.
#
# By default Claude Code creates worktrees at <repo>/.claude/worktrees/<name>, and
# hand-made ones tend to land as siblings (~/Code/<repo>-<lane>), which litters the
# ~/Code root. This hook replaces that: every worktree goes under one parking lot,
#
#     $CLAUDE_WORKTREE_ROOT/<repo>/<name>      (default ~/worktrees/<repo>/<name>)
#
# on a branch named worktree-<name>, branched from origin/HEAD when the repo has a
# remote (Claude Code's "fresh" default) or from HEAD otherwise. Set
# CLAUDE_WORKTREE_BASE=head to branch from the current HEAD instead.
#
# Contract (https://code.claude.com/docs/en/hooks#worktreecreate): JSON on stdin
# with .name and .cwd; print the created worktree's path on stdout; non-zero exit
# aborts creation. Everything chatty goes to stderr.
set -euo pipefail

input="$(cat)"
name="$(printf '%s' "$input" | jq -r '.name // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[ -n "$name" ] || { echo "worktree-create: no worktree name in hook input" >&2; exit 1; }
[ -d "$cwd" ] || cwd="$PWD"

# Resolve the MAIN checkout even when Claude is already inside a linked worktree.
top="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "worktree-create: $cwd is not inside a git repository" >&2; exit 1; }
common="$(git -C "$top" rev-parse --path-format=absolute --git-common-dir)"
main="$(dirname "$common")"
repo="$(basename "$main")"

root="${CLAUDE_WORKTREE_ROOT:-$HOME/worktrees}"
case "$name" in */*|..*) echo "worktree-create: refusing name '$name'" >&2; exit 1 ;; esac
dir="$root/$repo/$name"
branch="worktree-$name"

if [ -d "$dir" ]; then
  echo "worktree-create: reusing $dir" >&2
  printf '%s\n' "$dir"; exit 0
fi
mkdir -p "$(dirname "$dir")"

if git -C "$main" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$main" worktree add "$dir" "$branch" >&2
else
  base="HEAD"
  if [ "${CLAUDE_WORKTREE_BASE:-fresh}" != "head" ]; then
    if git -C "$main" symbolic-ref -q refs/remotes/origin/HEAD >/dev/null 2>&1; then
      git -C "$main" fetch -q origin 2>/dev/null || true
      base="$(git -C "$main" symbolic-ref -q --short refs/remotes/origin/HEAD)"
    fi
  fi
  git -C "$main" worktree add -b "$branch" "$dir" "$base" >&2
fi

# Honour .worktreeinclude (gitignore syntax): copy matching *ignored* files across,
# since Claude Code skips that step when a hook owns creation.
if [ -f "$main/.worktreeinclude" ]; then
  while IFS= read -r pat || [ -n "$pat" ]; do
    pat="${pat%%#*}"; pat="$(printf '%s' "$pat" | sed 's/[[:space:]]*$//')"
    [ -n "$pat" ] || continue
    git -C "$main" ls-files -o -i --exclude-standard -- "$pat" 2>/dev/null \
    | while IFS= read -r f; do
        [ -f "$main/$f" ] || continue
        mkdir -p "$dir/$(dirname "$f")"
        cp "$main/$f" "$dir/$f"
        echo "worktree-create: copied $f" >&2
      done
  done < "$main/.worktreeinclude"
fi

echo "worktree-create: $repo -> $dir ($branch)" >&2
printf '%s\n' "$dir"
