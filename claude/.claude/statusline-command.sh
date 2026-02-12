#!/bin/bash

dir=$(git rev-parse --show-prefix 2>/dev/null | sed 's:/$::')
if [ -z "$dir" ]; then
    dir=$(basename "$PWD")
fi
parts=$(echo "$dir" | tr '/' '\n' | tail -3 | tr '\n' '/')
dir="${parts%/}"

branch=$(git branch --show-current 2>/dev/null)

status=""
if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then status+="?"; fi
if ! git diff --quiet 2>/dev/null; then status+="!"; fi
if ! git diff --cached --quiet 2>/dev/null; then status+="+"; fi
ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
[ "$ahead" -gt 0 ] 2>/dev/null && status+="⇡"
[ "$behind" -gt 0 ] 2>/dev/null && status+="⇣"

output="$dir"
[ -n "$branch" ] && output+=" $branch"
[ -n "$status" ] && output+=" $status"
[ -n "$AWS_PROFILE" ] && output+=" on ☁️ $AWS_PROFILE"
output+=" >"

echo "$output"
