#!/usr/bin/env bash
# Usage: bash batch/extract-scan-ids.sh <transcript.jsonl>
# Extracts unique NEW job IDs from a dedup-ids.sh output recorded in a JSONL transcript.
grep -o 'NEW [0-9]\{10\}' "$1" | awk '{print $2}' | sort -u
