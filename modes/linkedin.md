# Mode: linkedin — LinkedIn Job Scanner

Scan LinkedIn for job opportunities using saved searches or profile-derived criteria. **Main agent only — no subagents.**

## Pacing Rule — Applies to Every Operation

Before **every** `browser_navigate` call (without exception):

```bash
bash batch/pace-check.sh
```

- `wait > 60`: save any progress accumulated so far, call ScheduleWakeup with the wait value, stop
- `ok`: proceed

After every `browser_navigate`: run `bash -c "bash batch/random-sleep.sh"` (uniform 3–45s) before the next action (LinkedIn bot detection).

These two checks stack — pace check first, then navigate, then random sleep.

---

## Step 1 — Auth Check

```bash
bash batch/pace-check.sh
```

```
browser_navigate(url="https://www.linkedin.com/jobs/")
bash batch/random-sleep.sh
browser_snapshot()
```

**Auth indicators:**
- ✅ Logged in: search bar visible, "Jobs" nav present, job listings or recommendations shown
- ❌ Not logged in: "Join now" / "Sign in" buttons dominant, marketing landing page

**If not logged in:**
> "LinkedIn authentication required. Please log in to LinkedIn in your browser (type `! open https://www.linkedin.com` to open it), then run `/career-ops linkedin` again."

Stop. Do not proceed.

---

## Step 2 — Source Selection

Present options to the user:

```
LinkedIn scan sources:
  A) Your saved jobs    — jobs you bookmarked on LinkedIn (high-intent: you looked at them)
  B) Profile criteria   — construct searches from your portals.yml keywords + DFW/Remote targeting
  C) Both (recommended) — saved jobs first, then criteria-based searches
```

If the user doesn't specify a preference, default to **C**.

---

## Step 3A — Saved Jobs

**Note:** LinkedIn's "saved searches" feature has been removed/restructured as of 2026. Saved jobs live at `/jobs-tracker/`. Job alert subscriptions are at `/jobs/alerts/` (may redirect to `/jobs/jam/`).

```bash
bash batch/pace-check.sh
```

```
browser_navigate(url="https://www.linkedin.com/jobs-tracker/")
bash batch/random-sleep.sh
browser_snapshot()
```

Extract all visible saved job cards. Display them:

```
Your LinkedIn saved jobs:
  1. {title} — {company} ({location})
  2. ...
```

For each saved job, proceed directly to Step 4 (extract URL, apply type, then liveness check in Step 7).

**Also check job alerts** (separately, optional if the user has them set up):

```bash
bash batch/pace-check.sh
```

```
browser_navigate(url="https://www.linkedin.com/jobs/alerts/")
bash batch/random-sleep.sh
browser_snapshot()
```

If redirected to `/jobs/jam/` or similar, note the new URL and extract any alert-triggered jobs shown.

---

## Step 3B — Profile-Derived Searches

Read `portals.yml` → `linkedin.searches[]`. For each enabled search entry, construct the LinkedIn URL:

```
https://www.linkedin.com/jobs/search/?keywords={encoded_keywords}&location={encoded_location}&f_WT={work_type_codes}&f_TPR=r604800&position=1&pageNum=0
```

LinkedIn work type codes: `1` = on-site, `2` = remote, `3` = hybrid
`f_TPR=r604800` = last 7 days (prevents stale listings)

Searches are defined in `portals.yml` under `linkedin.searches`. If that section is absent, fall back to these defaults:

| Name | Keywords | Location | Work Types |
|------|----------|----------|-----------|
| Power BI Senior Analyst — Remote | `Power BI Senior Analyst` | United States | 2 |
| Senior BI Analyst — Remote | `Senior BI Analyst` | United States | 2 |
| Business Intelligence Analyst — DFW | `Business Intelligence Analyst` | Dallas-Fort Worth Metroplex | 1,2,3 |
| Senior Data Analyst Power BI — Remote | `Senior Data Analyst Power BI` | United States | 2 |
| BI Developer — Remote | `BI Developer` | United States | 2 |
| Healthcare BI Analyst — Remote | `Healthcare Business Intelligence Analyst` | United States | 2 |
| Senior Data Analyst — DFW Hybrid/On-site | `Senior Data Analyst` | Dallas-Fort Worth Metroplex | 1,3 |
| Analytics Engineer Power BI — Remote | `Analytics Engineer Power BI` | United States | 2 |

---

## Step 4 — Extract Job Listings

For each search URL (saved or criteria-based):

1. `bash batch/pace-check.sh`
2. `browser_navigate(url=search_url)`
3. `bash batch/random-sleep.sh`
4. Use a **two-phase browser_evaluate** to extract job IDs from the page:
   - **Phase 1 (scroll):** call `browser_evaluate` with a `setTimeout`-chained scroll to trigger lazy-load of all 25 cards. This fires in the background — no sleep needed.
   - **Phase 2 (extract):** immediately call a second `browser_evaluate` to pull all job IDs from the DOM (e.g. `document.querySelectorAll('[data-job-id]')`). By the time this runs the DOM has loaded.
   - A single JS call in Phase 2 should return all 25 IDs from the page at once.
5. For each job card extract:
   - `title` — job title
   - `company` — employer name
   - `location` — city/state or "Remote"
   - `linkedin_url` — `https://www.linkedin.com/jobs/view/{id}/`
   - `apply_type` — "Easy Apply" (LinkedIn-native) or "Apply" (external ATS)
6. For **"Apply" (external ATS)** jobs: run pace check → navigate to the job detail → find the "Apply on company website" link → extract the external ATS URL. Use this as the pipeline URL, not the LinkedIn URL.
7. For **"Easy Apply"** jobs: use the LinkedIn URL as-is (no additional navigation needed).
8. If the page shows 25+ results and there's a "Next" page (max 3 pages per search):
   - `bash batch/pace-check.sh`
   - navigate to next page
   - `bash batch/random-sleep.sh`
   - extract and accumulate

---

## Step 5 — Dedup

**Build `/tmp/seen_urls.txt` once at scan start** (before processing any search page) with a single Bash call:

```bash
cut -f1 /Users/jameslackey/code/career-ops/data/scan-history.tsv | sort -u > /tmp/seen_urls.txt
grep -oE 'https://www\.linkedin\.com/jobs/view/[0-9]+/' /Users/jameslackey/code/career-ops/data/pipeline.md | sort -u >> /tmp/seen_urls.txt
sort -u /tmp/seen_urls.txt -o /tmp/seen_urls.txt
```

After extracting all IDs from a search page, dedup the **full batch** with a single call:

```bash
bash batch/dedup-ids.sh ID1 ID2 ID3 ...
```

`dedup-ids.sh` prints `NEW {id}` or `DUP {id}` for each. Only `NEW` items proceed. **Never loop over IDs individually in shell** — a per-ID `grep` loop triggers a permission prompt on every iteration.

Also check against:
- `data/applications.md` → company + first 3 words of role already evaluated
- `data/pipeline.md` → exact URL already pending or processed (already covered by `/tmp/seen_urls.txt`)

Mark each extracted job: `new` | `dup_url` | `dup_role` | `dup_history`

Only `new` items proceed.

---

## Step 6 — Title Filter

Apply `portals.yml` `title_filter` to all `new` items:
- At least 1 `positive` keyword must match (case-insensitive)
- 0 `negative` keywords must match

Mark filtered-out jobs as `skipped_title`.

---

## Step 7 — Liveness Verification

For each job that passed dedup + title filter:

1. `bash batch/pace-check.sh`
2. `browser_navigate(url=job_url)`
3. `bash batch/random-sleep.sh`
4. `browser_snapshot()` — check liveness:
   - ✅ Active: job title + description visible + Apply/Easy Apply button present in main content
   - ❌ Expired: "No longer accepting applications" | "This job is no longer available" | generic search redirect | HTTP 404/410 | content < 300 chars
5. Active → add to pipeline (Step 8)
6. Expired → record `skipped_expired` in scan-history.tsv, skip

---

## Step 8 — Add to Pipeline

For each verified active listing:

1. Add to `data/pipeline.md`:
   ```
   - [ ] {url} | {company} | {title}
   ```
   Use the external ATS URL when available; LinkedIn URL otherwise.

2. Record in `data/scan-history.tsv`:
   ```
   {url}	{YYYY-MM-DD}	LinkedIn — {search_name}	{title}	{company}	added
   ```

For filtered/duplicate/expired jobs, record in scan-history.tsv with the appropriate status (`skipped_title`, `skipped_dup`, `skipped_expired`).

---

## Step 9 — Output Summary

```
LinkedIn Scan — {YYYY-MM-DD}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sources: {N} saved search(es), {N} criteria search(es)
Jobs found: {N} total across all searches
Duplicates skipped: {N}
Filtered by title: {N}
Expired/closed: {N}
────────────────────────────────────
New added to pipeline: {N}

  + {company} | {title} | via {search_name}
  ...

→ Run /career-ops pipeline to evaluate new offers.
```

---

## Resuming an Interrupted Scan

If a session is interrupted mid-scan (context limit, crash, etc.) and a new session continues, the prior session's transcript contains all dedup results. Use the helper scripts to recover without re-scanning:

**Extract new IDs from a prior transcript:**
```bash
bash batch/extract-scan-ids.sh ~/.claude/projects/-Users-jameslackey-code-career-ops/{session-uuid}.jsonl
```
Prints one LinkedIn job ID per line (only `NEW` items, sorted).

**Extract id/title/company metadata from a prior transcript:**
```bash
bash batch/extract-job-metadata.sh ~/.claude/projects/-Users-jameslackey-code-career-ops/{session-uuid}.jsonl
```
Prints TSV: `id  title  company` for every triplet found in the transcript.

Both scripts are allowlisted in `.claude/settings.json` — no approval prompt needed.

The transcript path uses the session UUID visible in the current context summary. After recovering IDs, resume from Step 6 (title filter) or Step 7 (liveness) as appropriate.

---

## Suggested Additional Searches (for future portals.yml expansion)

Beyond the defaults above, these search angles are worth adding when James's profile evolves:

- **People / HR Analytics + Power BI** — Power BI is dominant in HRIS/Workday analytics; strong comp, KPMG background fits
- **Financial Services BI** — "BI Analyst Finance" or "FP&A Analytics" + DFW — KPMG Tax background is directly relevant
- **Insurance Analytics** — Large DFW employers (e.g., Chubb, Travelers, USAA in San Antonio) with heavy Power BI usage
- **Consulting / Big 4 adjacent** — "Senior Analyst" at Deloitte, EY, PwC (internal roles, not client-facing) — KPMG transition is natural
- **Supply Chain Analytics + Power BI** — Large DFW logistics/CPG HQs (Toyota, Keurig Dr Pepper, ALDI) with Power BI-heavy environments
