#!/usr/bin/env bash
# pace-gate.sh — Rate limit gate for career-ops batch/headless operations.
# Blocks until pace-check.sh reports "ok". Call before any token-heavy action.
# For interactive pipeline processing, use ScheduleWakeup instead.
#
# Usage:
#   bash batch/pace-gate.sh             # block until clear, exit 0
#   bash batch/pace-gate.sh && command  # run command only when clear
#
# Options:
#   --max-wait N   Max seconds to wait before giving up (default: 3600)
#   --quiet        Suppress progress output
#   --no-wait      Exit 1 immediately if not clear (non-blocking check)
#   -h, --help     Show this help
#
# Exit codes:
#   0  Clear to proceed
#   1  Still hot after max-wait, or --no-wait triggered
#   2  pace-check.sh not found or not executable

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACE_CHECK="$SCRIPT_DIR/pace-check.sh"
MAX_WAIT=3600
QUIET=false
NO_WAIT=false

usage() {
  cat <<'USAGE'
pace-gate.sh — Rate limit gate for career-ops batch operations.
Blocks until both rate limit windows have headroom:
  5h window: target ≤90% projected (conservative)
  7d window: target ≤100% projected (maximize weekly budget)

Usage: bash batch/pace-gate.sh [OPTIONS]

Options:
  --max-wait N   Max seconds to wait before giving up (default: 3600)
  --quiet        Suppress progress output
  --no-wait      Exit immediately with status 1 if not clear
  -h, --help     Show this help

Exit codes:
  0  Clear to proceed
  1  Still hot after max-wait, or --no-wait triggered
  2  pace-check.sh not found or not executable
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-wait) MAX_WAIT="$2"; shift 2 ;;
    --quiet)    QUIET=true; shift ;;
    --no-wait)  NO_WAIT=true; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [[ ! -x "$PACE_CHECK" ]]; then
  echo "pace-gate: pace-check.sh not found at $PACE_CHECK" >&2
  exit 2
fi

log() { [[ "$QUIET" == "false" ]] && echo "$@"; }

waited=0

while true; do
  full_output=$(bash "$PACE_CHECK")
  result=$(echo "$full_output" | tail -1)

  if [[ "$result" != wait* ]]; then
    log "  [pace-gate] Clear — $full_output"
    exit 0
  fi

  secs="${result#wait }"
  secs=$(( secs > 0 ? secs : 60 ))

  if [[ "$NO_WAIT" == "true" ]]; then
    log "  [pace-gate] Hot — would wait ${secs}s (--no-wait set)"
    exit 1
  fi

  if (( waited + secs > MAX_WAIT )); then
    echo "  [pace-gate] Exceeded max-wait (${MAX_WAIT}s). Aborting." >&2
    exit 1
  fi

  mins=$(( secs / 60 ))
  rem=$(( secs % 60 ))
  log "  ⏸️  [pace-gate] Rate limit hot — waiting ${mins}m ${rem}s... ($(date '+%H:%M:%S'))"
  sleep "$secs"
  waited=$(( waited + secs ))
  log "  [pace-gate] Rechecking..."
done
