#!/usr/bin/env bash
# Claude Code Stop hook — captures 5h + 7d rate limit snapshot for pace-check.sh.
# Reads session JSON from stdin, writes /tmp/claude-rl.json if rate limit data present.

input=$(cat)
rl_five=$(echo "$input"        | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_resets=$(echo "$input"      | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_seven=$(echo "$input"       | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_resets_7d=$(echo "$input"   | jq -r '.rate_limits.seven_day.resets_at // empty')

[ -z "$rl_five" ] || [ -z "$rl_resets" ] && exit 0

ts=$(date +%s)

if [ -n "$rl_seven" ] && [ -n "$rl_resets_7d" ]; then
    printf '{"used_pct":%s,"resets_at":%s,"ts":%s,"used_pct_7d":%s,"resets_at_7d":%s}\n' \
        "$rl_five" "$rl_resets" "$ts" "$rl_seven" "$rl_resets_7d" > /tmp/claude-rl.json
else
    printf '{"used_pct":%s,"resets_at":%s,"ts":%s}\n' \
        "$rl_five" "$rl_resets" "$ts" > /tmp/claude-rl.json
fi
