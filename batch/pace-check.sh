#!/usr/bin/env bash
# Pace checker for pipeline runs.
# Reads /tmp/claude-rl.json (written by rl-snapshot.sh Stop hook).
# Outputs one line: "ok" | "wait N" (seconds) | "ok (reason)"
#
# Pace formula (from statusline.sh):
#   projected = used_pct * DURATION / elapsed
#   projected > 100 → burning faster than the window allows → wait

SNAPSHOT="/tmp/claude-rl.json"
DURATION=18000  # 5-hour window in seconds
STALE_SECS=300  # treat snapshot older than 5 min as stale

now=$(date +%s)

if [ ! -f "$SNAPSHOT" ]; then
    echo "ok (no snapshot — hook not yet fired)"
    exit 0
fi

data=$(cat "$SNAPSHOT")
used_pct=$(echo "$data" | jq -r '.used_pct // empty')
resets_at=$(echo "$data" | jq -r '.resets_at // empty')
snap_ts=$(echo "$data"   | jq -r '.ts // empty')

if [ -z "$used_pct" ] || [ -z "$resets_at" ]; then
    echo "ok (snapshot missing fields)"
    exit 0
fi

# Stale check
if [ -n "$snap_ts" ] && [ $(( now - snap_ts )) -gt $STALE_SECS ]; then
    echo "ok (snapshot stale — $(( (now - snap_ts) / 60 ))m old)"
    exit 0
fi

elapsed=$(( now - (resets_at - DURATION) ))
if [ "$elapsed" -le 0 ]; then
    echo "ok (window just started)"
    exit 0
fi

time_pct=$(echo "scale=1; $elapsed * 100 / $DURATION" | bc 2>/dev/null)
projected=$(echo "scale=1; $used_pct * $DURATION / $elapsed" | bc 2>/dev/null)
projected_int=$(echo "scale=0; $used_pct * $DURATION / $elapsed" | bc 2>/dev/null)

if [ -z "$projected_int" ]; then
    echo "ok (bc error)"
    exit 0
fi

# Arrow logic from statusline.sh
if   [ "$projected_int" -gt 115 ]; then arrow="↑ FAST"
elif [ "$projected_int" -gt 85  ]; then arrow="→ on pace"
else                                     arrow="↓ under"
fi

mins_remaining=$(( (resets_at - now) / 60 ))

printf 'used=%s%% elapsed=%s%% projected=%s%% [%s] %dm remaining\n' \
    "$used_pct" "$time_pct" "$projected" "$arrow" "$mins_remaining"

if [ "$projected_int" -le 90 ]; then
    echo "ok"
    exit 0
fi

# Calculate wait: pause until projected usage falls to 90% of window
# target_elapsed = time at which current spend rate hits 90% of DURATION
target_elapsed=$(echo "scale=0; $used_pct * $DURATION / 90" | bc 2>/dev/null)
wait_secs=$(( target_elapsed - elapsed ))
[ "$wait_secs" -lt 0 ] && wait_secs=0

echo "wait $wait_secs"
