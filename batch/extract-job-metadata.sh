#!/usr/bin/env bash
# Usage: bash batch/extract-job-metadata.sh <transcript.jsonl>
# Extracts id/title/company triplets from a JSONL session transcript.
# Output: TSV with columns id, title, company (sorted by id).
python3 - "$1" << 'PYEOF'
import re, sys

with open(sys.argv[1]) as f:
    content = f.read()

pattern = r'\{\"id\":\s*\"(\d+)\",\s*\"title\":\s*\"([^\"]*)\",\s*\"company\":\s*\"([^\"]*)\"'
seen = {}
for id_, title, company in re.findall(pattern, content):
    if id_ not in seen:
        seen[id_] = (title, company)

for id_, (title, company) in sorted(seen.items()):
    print(f'{id_}\t{title}\t{company}')
PYEOF
