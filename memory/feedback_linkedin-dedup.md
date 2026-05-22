---
name: feedback_linkedin-dedup
description: LinkedIn scan dedup pattern, scroll/extract technique, and transcript recovery scripts
metadata:
  type: feedback
---

Use `batch/dedup-ids.sh` + `/tmp/seen_urls.txt` (built once at scan start) to dedup all IDs per page in a single Bash call. Never loop over IDs individually in shell — a per-ID `grep` triggers a permission prompt on every iteration.

**Why:** Per-ID grep loop required user approval on every single iteration during a scan. Batch script call is a single allowlisted invocation.

**How to apply:**
- Build `/tmp/seen_urls.txt` once before any search page: cut URLs from `data/scan-history.tsv` + grep LinkedIn URLs from `data/pipeline.md`, sort -u
- After extracting IDs from a page, call `bash batch/dedup-ids.sh ID1 ID2 ID3 ...` with all IDs at once
- Parse `NEW` vs `DUP` from output

**Two-phase browser_evaluate for LinkedIn lazy-loading:**
- Phase 1: fire a `setTimeout`-chained scroll sequence (0→scrollHeight in 8 steps, 250ms apart) — returns immediately, scroll happens in background
- Phase 2: second `browser_evaluate` to extract all job IDs from the DOM

**Recovering from interrupted scans:**

If a session ends mid-scan (context limit etc.), use the helper scripts to recover IDs from the prior transcript without re-scanning:

```bash
# Extract just the NEW IDs
bash batch/extract-scan-ids.sh ~/.claude/projects/-Users-jameslackey-code-career-ops/{session-uuid}.jsonl

# Extract id/title/company metadata (TSV)
bash batch/extract-job-metadata.sh ~/.claude/projects/-Users-jameslackey-code-career-ops/{session-uuid}.jsonl
```

Both scripts are allowlisted in `.claude/settings.json`. The session UUID appears in the context summary after compaction.

**Related:** [[feedback_batch-script-pattern]]
