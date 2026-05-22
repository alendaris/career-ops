---
name: reference_linkedin-saved-jobs-url
description: Correct URLs for LinkedIn saved jobs and alerts (saved searches URL is deprecated/404)
metadata:
  type: reference
---

LinkedIn's "saved searches" feature at `/my-items/saved-job-searches/` returns 404 as of 2026 — it has been removed.

**Correct locations:**
- **Saved jobs** (bookmarked postings): `https://www.linkedin.com/jobs-tracker/`
- **Job alerts** (saved search subscriptions): `https://www.linkedin.com/jobs/alerts/` — may redirect to `/jobs/jam/`

Saved jobs are high-intent: James manually saved them after seeing a notification or browsing. They should be the first source checked in `/career-ops linkedin`.

**Why:** Discovered during a live LinkedIn scan on 2026-05-17 when the old saved searches URL returned 404. Found 2 saved jobs at `/jobs-tracker/` and processed them (SMU added to pipeline, KPMG duped).

**How to apply:** In Step 3A of modes/linkedin.md, always navigate to `/jobs-tracker/` for saved jobs. Never use `/my-items/saved-job-searches/`.
