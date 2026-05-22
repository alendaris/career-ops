#!/usr/bin/env bash
# Usage: bash batch/dedup-ids.sh ID1 ID2 ...
# Checks each LinkedIn job ID against /tmp/seen_urls.txt
# Outputs: NEW <id>  or  DUP <id>
for id in "$@"; do
  url="https://www.linkedin.com/jobs/view/${id}/"
  if grep -qF "$url" /tmp/seen_urls.txt 2>/dev/null; then
    echo "DUP $id"
  else
    echo "NEW $id"
  fi
done
