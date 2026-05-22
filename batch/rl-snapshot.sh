#!/usr/bin/env bash
# Claude Code Stop hook — captures 5h rate limit snapshot for pace-check.sh.
# Reads session JSON from stdin, writes /tmp/claude-rl.json if rate limit data present.

input=$(cat)
rl_five=$(echo "$input"      | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_resets=$(echo "$input"    | jq -r '.rate_limits.five_hour.resets_at // empty')

[ -z "$rl_five" ] || [ -z "$rl_resets" ] && exit 0

printf '{"used_pct":%s,"resets_at":%s,"ts":%s}\n' \
    "$rl_five" "$rl_resets" "$(date +%s)" > /tmp/claude-rl.json
