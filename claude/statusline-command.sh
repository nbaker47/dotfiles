#!/bin/bash
# Statusline converted from the zsh PS1 in ~/.zshrc:
#   PS1="%{$fg_bold[green]%}[%1~]%{$fg[yellow]%}\$(parse_git_branch) \$(k8s_info)%{$fg[blue]%} \$>%{$fg[cyan]%}"
# Renders: [last dir component] [git branch] [k8s ns@cluster] <model>
# The trailing "$>" prompt marker from the original PS1 is dropped (no shell to type into).

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$PWD"
model=$(echo "$input" | jq -r '.model.display_name // empty')

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

# %1~ -> last path component, ~ for home
if [ "$cwd" = "$HOME" ]; then
  dir="~"
else
  dir=$(basename "$cwd")
fi

# parse_git_branch() equivalent (skip optional locks so it never blocks on a lockfile)
git_branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    sha=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    [ -n "$sha" ] && branch="detached@$sha"
  fi
  [ -n "$branch" ] && git_branch=" [$branch]"
fi

# k8s_info() equivalent: namespace@cluster, colored by cluster name.
# Unlike the shell version this shows the SHORT cluster name, not the raw context:
# an EKS context is a full ARN and would eat the whole status line.
k8s=""
info=$(kubectl config view --minify --output 'jsonpath={..namespace}@{.current-context}' 2>/dev/null)
if [ -n "$info" ] && [ "$info" != "@" ]; then
  ns="${info%@*}"
  context="${info#*@}"
  case "$context" in
    *green*) kcolor="$GREEN" ;;
    *blue*) kcolor="$BLUE" ;;
    *) kcolor="$YELLOW" ;;
  esac
  # arn:aws:eks:...:cluster/dev-blue -> dev-blue ; gke_proj_zone_name -> name
  short="${context##*/}"
  case "$short" in gke_*) short="${short##*_}" ;; esac
  # a namespace-less context renders as [cluster], not [@cluster]
  if [ -n "$ns" ]; then
    k8s=" ${kcolor}[${ns}@${short}]${RESET}"
  else
    k8s=" ${kcolor}[${short}]${RESET}"
  fi
fi

# Current model (Opus / Sonnet / ...), from the statusline JSON payload
model_seg=""
[ -n "$model" ] && model_seg=" ${CYAN}${model}${RESET}"

# Usage: plan limits (5-hour and weekly windows) and this session's context window.
# rate_limits only exists for Pro/Max accounts and only after the first response, and
# each window can be missing on its own, so every part is optional.
RED='\033[1;31m'
DIM='\033[2m'
pct_seg() {  # label, percentage -> " label NN%" coloured green / yellow (>=70) / red (>=90)
  [ -z "$2" ] && return
  local n color
  n=$(printf '%.0f' "$2")
  if [ "$n" -ge 90 ]; then color="$RED"; elif [ "$n" -ge 70 ]; then color="$YELLOW"; else color="$GREEN"; fi
  printf ' %b%s %s%%%b' "$color" "$1" "$n" "$RESET"
}
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
usage_seg="$(pct_seg 5h "$five")"
if [ -n "$five" ] && [ -n "$five_reset" ]; then
  # BSD date (macOS) first, GNU date as the fallback
  at=$(date -r "$five_reset" +%H:%M 2>/dev/null || date -d "@$five_reset" +%H:%M 2>/dev/null)
  [ -n "$at" ] && usage_seg="${usage_seg}${DIM}→${at}${RESET}"
fi
usage_seg="${usage_seg}$(pct_seg wk "$week")$(pct_seg ctx "$ctx")"

printf "${GREEN}[%s]${RESET}${YELLOW}%s${RESET}%b%b%b" "$dir" "$git_branch" "$k8s" "$model_seg" "$usage_seg"
