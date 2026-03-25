#!/bin/bash

# Read Claude Code JSON from stdin
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // empty')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Git info
branch=$(git branch --show-current 2>/dev/null)
status=""
if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then status+="?"; fi
if ! git diff --quiet 2>/dev/null; then status+="!"; fi
if ! git diff --cached --quiet 2>/dev/null; then status+="+"; fi
ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
[ "$ahead" -gt 0 ] 2>/dev/null && status+="⇡$ahead"
[ "$behind" -gt 0 ] 2>/dev/null && status+="⇣$behind"

# Last commit age
last_ts=$(git log -1 --format=%ct 2>/dev/null)
if [ -n "$last_ts" ]; then
    now=$(date +%s)
    diff=$((now - last_ts))
    if [ $diff -lt 60 ]; then age="${diff}s"
    elif [ $diff -lt 3600 ]; then age="$((diff / 60))m"
    elif [ $diff -lt 86400 ]; then age="$((diff / 3600))h"
    else age="$((diff / 86400))d"
    fi
fi

# Build output
dir=$(basename "$PWD")
output="$dir"
[ -n "$branch" ] && output+=" $branch"
[ -n "$status" ] && output+=" $status"
[ -n "$age" ] && output+=" ${age} ago"
[ -n "$model" ] && output+=" | $model"
[ -n "$ctx" ] && output+=" ${ctx}%"
[ -n "$cost" ] && output+=" \$${cost}"

echo "$output"
