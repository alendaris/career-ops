---
name: feedback_pipeline-rate-limit-pacing
description: Rate limit pacing rule for sequential pipeline runs — must check pace-check.sh before each item and pause when wait > 60s
metadata:
  type: feedback
---

When running /career-ops pipeline sequentially (no subagents), check the rate limit **before processing each item** — before the JD fetch, before evaluation, before anything:

```bash
bash /Users/jameslackey/code/career-ops/batch/pace-check.sh
```

Parse the `wait N` value from output:
- If `wait ≤ 60` → proceed with the next item
- If `wait > 60` → call ScheduleWakeup with that delay (capped at 3600s) and stop the current turn

**Why:** The goal is to consume rate limit at a sustainable pace, not burn through the full window in minutes. "There's still capacity remaining" is NOT a valid reason to skip the wait. The pace-check script computes the correct inter-item delay based on actual usage vs elapsed window — trust it.

**How to apply:** Before **every operation** — every JD fetch, every browser_navigate, every page load, every external tool call. Not just before pipeline items. Not just before liveness checks. Every single operation, no matter how routine or how close to completion the queue is. This rule has been violated repeatedly. Treat any temptation to skip as a signal to stop and check.

**Pattern of failure:** Skipped multiple times across sessions — typically on the last item in a batch, during LinkedIn-style browsing loops, or when items seem straightforward. The skip is never justified by context.

[[project_score-gate-customizations]]
