#!/bin/bash
# Claude Code statusline — model | dir | git | cost | context%
input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Short dir name (~/project)
short_dir="${dir/#$HOME/~}"
short_dir="${short_dir##*/}"

# Git branch (run in workspace dir, skip if not a repo)
branch=""
if [ -n "$dir" ]; then
  branch=$(git -C "$dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Build output
parts=()

# Model — cyan
[ -n "$model" ] && parts+=("\033[36m${model}\033[0m")

# Directory — blue
[ -n "$short_dir" ] && parts+=("\033[34m${short_dir}\033[0m")

# Git branch — magenta
[ -n "$branch" ] && parts+=("\033[35m${branch}\033[0m")

# Cost — white (only show if > $0)
cost_fmt=$(printf '%.2f' "$cost")
[ "$cost_fmt" != "0.00" ] && parts+=("\$${cost_fmt}")

# Context usage — color-coded: green < 50%, yellow 50-75%, red > 75%
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  if [ "$pct" -lt 50 ]; then
    color='\033[32m'
  elif [ "$pct" -lt 75 ]; then
    color='\033[33m'
  else
    color='\033[31m'
  fi
  parts+=("${color}ctx:${pct}%\033[0m")
fi

# Join with " | "
printf '%b' "$(IFS='|'; echo "${parts[*]}" | sed 's/|/ | /g')"
