#!/usr/bin/env bash
# statusLine wrapper for career-ops.
# 1. Captures stdin once.
# 2. Writes /tmp/claude-rl.json for pace-check.sh.
# 3. Delegates to the upstream statusline-command.sh for the main display.
# 4. Appends a pipeline progress line (pending count from data/pipeline.md).

input=$(cat)

# --- Rate limit snapshot (for pace-check.sh) ---
rl_five=$(printf '%s' "$input"      | jq -r '.rate_limits.five_hour.used_percentage // empty'  2>/dev/null)
rl_resets=$(printf '%s' "$input"    | jq -r '.rate_limits.five_hour.resets_at // empty'        2>/dev/null)
rl_seven=$(printf '%s' "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty'  2>/dev/null)
rl_resets_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty'       2>/dev/null)
if [ -n "$rl_five" ] && [ -n "$rl_resets" ]; then
    if [ -n "$rl_seven" ] && [ -n "$rl_resets_7d" ]; then
        printf '{"used_pct":%s,"resets_at":%s,"ts":%s,"used_pct_7d":%s,"resets_at_7d":%s}\n' \
            "$rl_five" "$rl_resets" "$(date +%s)" "$rl_seven" "$rl_resets_7d" > /tmp/claude-rl.json
    else
        printf '{"used_pct":%s,"resets_at":%s,"ts":%s}\n' \
            "$rl_five" "$rl_resets" "$(date +%s)" > /tmp/claude-rl.json
    fi
fi

# --- Upstream statusline ---
STATUSLINE="$HOME/.claude/statusline-command.sh"
if [ -x "$STATUSLINE" ]; then
    printf '%s' "$input" | bash "$STATUSLINE"
else
    printf '%s' "$input" | jq -r '"RL: " + (.rate_limits.five_hour.used_percentage // "?" | tostring) + "% used"' 2>/dev/null || true
fi

# --- Batch progress line (from status-line.sh) ---
BATCH_STATUSLINE="/Users/jameslackey/code/career-ops/batch/status-line.sh"
[ -x "$BATCH_STATUSLINE" ] && bash "$BATCH_STATUSLINE"

# --- Pipeline progress line ---
PIPELINE="/Users/jameslackey/code/career-ops/data/pipeline.md"
if [ -f "$PIPELINE" ]; then
    pending=$(grep -c '^- \[ \]' "$PIPELINE" 2>/dev/null); pending=${pending:-0}
    done_n=$(grep -c '^- \[x\]' "$PIPELINE" 2>/dev/null); done_n=${done_n:-0}
    printf 'pipeline: %d pending · %d done\n' "$pending" "$done_n"
fi
exit 0
