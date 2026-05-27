#!/usr/bin/env bash
# Pace checker for pipeline runs.
# Reads /tmp/claude-rl.json (written by rl-snapshot.sh Stop hook).
# Outputs one line: "ok" | "wait N" (seconds) | "ok (reason)"
#
# Pace formula:
#   projected = used_pct * DURATION / elapsed
#   5h window: pause if projected > 90%  (conservative; target ≤90%)
#   7d window: pause if projected > 100% (maximize weekly budget; target 100%)

SNAPSHOT="/tmp/claude-rl.json"
DURATION_5H=18000   # 5-hour window in seconds
DURATION_7D=604800  # 7-day window in seconds
STALE_SECS=300      # treat snapshot older than 5 min as stale

now=$(date +%s)

if [ ! -f "$SNAPSHOT" ]; then
    echo "ok (no snapshot — hook not yet fired)"
    exit 0
fi

data=$(cat "$SNAPSHOT")
used_pct=$(echo "$data"    | jq -r '.used_pct // empty')
resets_at=$(echo "$data"   | jq -r '.resets_at // empty')
snap_ts=$(echo "$data"     | jq -r '.ts // empty')
used_pct_7d=$(echo "$data" | jq -r '.used_pct_7d // empty')
resets_at_7d=$(echo "$data"| jq -r '.resets_at_7d // empty')

if [ -z "$used_pct" ] || [ -z "$resets_at" ]; then
    echo "ok (snapshot missing fields)"
    exit 0
fi

# Stale check
if [ -n "$snap_ts" ] && [ $(( now - snap_ts )) -gt $STALE_SECS ]; then
    echo "ok (snapshot stale — $(( (now - snap_ts) / 60 ))m old)"
    exit 0
fi

# ── 5h window ──────────────────────────────────────────────────────────────

elapsed_5h=$(( now - (resets_at - DURATION_5H) ))
if [ "$elapsed_5h" -le 0 ]; then
    echo "ok (5h window just started)"
    exit 0
fi

time_pct_5h=$(echo "scale=1; $elapsed_5h * 100 / $DURATION_5H" | bc 2>/dev/null)
projected_5h=$(echo "scale=1; $used_pct * $DURATION_5H / $elapsed_5h" | bc 2>/dev/null)
projected_5h_int=$(echo "scale=0; $used_pct * $DURATION_5H / $elapsed_5h" | bc 2>/dev/null)

if [ -z "$projected_5h_int" ]; then
    echo "ok (bc error)"
    exit 0
fi

if   [ "$projected_5h_int" -gt 115 ]; then arrow_5h="↑ FAST"
elif [ "$projected_5h_int" -gt 85  ]; then arrow_5h="→ on pace"
else                                        arrow_5h="↓ under"
fi

mins_remaining_5h=$(( (resets_at - now) / 60 ))

printf '5h: used=%s%% elapsed=%s%% projected=%s%% [%s] %dm remaining\n' \
    "$used_pct" "$time_pct_5h" "$projected_5h" "$arrow_5h" "$mins_remaining_5h"

wait_5h=0
if [ "$(echo "$projected_5h > 90" | bc 2>/dev/null)" = "1" ]; then
    target_elapsed_5h=$(echo "scale=0; $used_pct * $DURATION_5H / 90" | bc 2>/dev/null)
    wait_5h=$(( target_elapsed_5h - elapsed_5h ))
    [ "$wait_5h" -lt 0 ] && wait_5h=0
fi

# ── 7d window ──────────────────────────────────────────────────────────────
# Pass "5h" as $1 to skip 7d entirely (e.g. bash pace-check.sh 5h)

wait_7d=0
if [ "${1:-}" = "5h" ]; then
    : # 7d check skipped — 5h-only mode
elif [ -z "$used_pct_7d" ] || [ -z "$resets_at_7d" ]; then
    echo "7d: no data in snapshot"
elif [ -n "$used_pct_7d" ] && [ -n "$resets_at_7d" ]; then
    elapsed_7d=$(( now - (resets_at_7d - DURATION_7D) ))

    if [ "$elapsed_7d" -gt 0 ]; then
        time_pct_7d=$(echo "scale=1; $elapsed_7d * 100 / $DURATION_7D" | bc 2>/dev/null)
        projected_7d=$(echo "scale=1; $used_pct_7d * $DURATION_7D / $elapsed_7d" | bc 2>/dev/null)
        projected_7d_int=$(echo "scale=0; $used_pct_7d * $DURATION_7D / $elapsed_7d" | bc 2>/dev/null)

        if [ -n "$projected_7d_int" ]; then
            if   [ "$projected_7d_int" -gt 115 ]; then arrow_7d="↑ FAST"
            elif [ "$projected_7d_int" -gt 85  ]; then arrow_7d="→ on pace"
            else                                        arrow_7d="↓ under"
            fi

            days_remaining=$(( (resets_at_7d - now) / 86400 ))
            hrs_remaining=$(( ((resets_at_7d - now) % 86400) / 3600 ))

            printf '7d: used=%s%% elapsed=%s%% projected=%s%% [%s] %dd%dh remaining\n' \
                "$used_pct_7d" "$time_pct_7d" "$projected_7d" "$arrow_7d" \
                "$days_remaining" "$hrs_remaining"

            if [ "$(echo "$projected_7d > 100" | bc 2>/dev/null)" = "1" ]; then
                target_elapsed_7d=$(echo "scale=0; $used_pct_7d * $DURATION_7D / 100" | bc 2>/dev/null)
                wait_7d=$(( target_elapsed_7d - elapsed_7d ))
                [ "$wait_7d" -lt 0 ] && wait_7d=0
            fi
        fi
    fi
fi

# ── Final decision: take the more restrictive wait ─────────────────────────

if [ "$wait_5h" -le 0 ] && [ "$wait_7d" -le 0 ]; then
    echo "ok"
    exit 0
fi

if [ "$wait_5h" -ge "$wait_7d" ]; then
    echo "wait $wait_5h"
else
    echo "wait $wait_7d"
fi
