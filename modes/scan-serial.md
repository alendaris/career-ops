# Mode: scan-serial — Portal Scanner (Serial, Rate-Limited)

Scans configured job portals in serial on the **main agent only**. No subagents.
Checks `batch/pace-check.sh` before each company/step. No parallel execution.

## Execution

**Main agent only — never delegate to a subagent.**

---

## Pacing Rule — Applies Before Every Step

Before navigating to any URL (`browser_navigate`) or fetching any API endpoint (WebFetch/WebSearch):

```bash
bash batch/pace-check.sh
```

- Output `ok` → proceed immediately
- Output `wait N` → call `ScheduleWakeup(delaySeconds=N, prompt=<current loop prompt>)` and stop

No `random-sleep.sh` is used in this mode — that pattern exists for LinkedIn bot detection only and is not needed for corporate careers pages or ATS APIs.

---

## Configuration

Read `portals.yml` which contains:
- `search_queries`: List of WebSearch queries with `site:` filters by portal (broad discovery)
- `tracked_companies`: Specific companies with `careers_url` for direct navigation
- `title_filter`: Positive/negative/seniority_boost keywords for title filtering

## Discovery Strategy (3 levels)

### Level 1 — Direct Playwright (PRIMARY)

**For each company in `tracked_companies`:** Navigate to their `careers_url` with Playwright (`browser_navigate` + `browser_snapshot`), read ALL visible job listings, and extract title + URL from each. This is the most reliable method because:
- Sees the page in real time (not Google's cached results)
- Works with SPAs (Ashby, Lever, Workday)
- Detects new offers instantly
- Doesn't depend on Google indexing

**Every company MUST have `careers_url` in portals.yml.** If it doesn't, find it once, save it, and use it in future scans.

### Level 2 — ATS APIs / Feeds (COMPLEMENTARY)

For companies with a public API or structured feed, use the JSON/XML response as a fast complement to Level 1. Faster than Playwright and reduces visual scraping errors.

**Current support (variables in `{}`):**
- **Greenhouse**: `https://boards-api.greenhouse.io/v1/boards/{company}/jobs`
- **Ashby**: `https://jobs.ashbyhq.com/api/non-user-graphql?op=ApiJobBoardWithTeams`
- **BambooHR**: list `https://{company}.bamboohr.com/careers/list`; single offer detail `https://{company}.bamboohr.com/careers/{id}/detail`
- **Lever**: `https://api.lever.co/v0/postings/{company}?mode=json`
- **Teamtailor**: `https://{company}.teamtailor.com/jobs.rss`
- **Workday**: `https://{company}.{shard}.myworkdayjobs.com/wday/cxs/{company}/{site}/jobs`

**Parsing convention by provider:**
- `greenhouse`: `jobs[]` → `title`, `absolute_url`
- `ashby`: GraphQL `ApiJobBoardWithTeams` with `organizationHostedJobsPageName={company}` → `jobBoard.jobPostings[]` (`title`, `id`; build public URL if not in payload)
- `bamboohr`: list `result[]` → `jobOpeningName`, `id`; build detail URL `https://{company}.bamboohr.com/careers/{id}/detail`; to read full JD, GET the detail and use `result.jobOpening` (`jobOpeningName`, `description`, `datePosted`, `minimumExperience`, `compensation`, `jobOpeningShareUrl`)
- `lever`: root array `[]` → `text`, `hostedUrl` (fallback: `applyUrl`)
- `teamtailor`: RSS items → `title`, `link`
- `workday`: `jobPostings[]`/`jobPostings` (depending on tenant) → `title`, `externalPath` or URL built from host

### Level 3 — WebSearch Queries (BROAD DISCOVERY)

The `search_queries` with `site:` filters cover portals broadly (all Ashby, all Greenhouse, etc.). Useful for discovering NEW companies not yet in `tracked_companies`, but results may be stale.

**Execution priority:**
1. Level 1: Playwright → all `tracked_companies` with `careers_url`
2. Level 2: API → all `tracked_companies` with `api:`
3. Level 3: WebSearch → all `search_queries` with `enabled: true`

Levels are additive — all run, results are merged and deduplicated.

## Workflow

1. **Read configuration**: `portals.yml`
2. **Read history**: `data/scan-history.tsv` → URLs already seen
3. **Read dedup sources**: `data/applications.md` + `data/pipeline.md`

4. **Level 1 — Playwright scan** (serial — one company at a time):
   For each company in `tracked_companies` with `enabled: true` and `careers_url` defined:
   a. `bash batch/pace-check.sh` → `wait N`: ScheduleWakeup(N) and stop | `ok`: continue
   b. `browser_navigate` to `careers_url`
   c. `browser_snapshot` to read all job listings
   d. If the page has filters/departments, navigate relevant sections
   e. For each job listing extract: `{title, url, company}`
   f. If the page paginates:
      - `bash batch/pace-check.sh` → gate
      - `browser_navigate` to next page
      - `browser_snapshot` → extract
      - Repeat until no more pages
   g. Accumulate in candidates list
   h. If `careers_url` fails (404, redirect), try `scan_query` as fallback and note for URL update

5. **Level 2 — ATS APIs / feeds** (serial):
   For each company in `tracked_companies` with `api:` defined and `enabled: true`:
   a. `bash batch/pace-check.sh` → gate
   b. WebFetch the API/feed URL
   c. If `api_provider` is defined, use its parser; if not defined, infer from domain (`boards-api.greenhouse.io`, `jobs.ashbyhq.com`, `api.lever.co`, `*.bamboohr.com`, `*.teamtailor.com`, `*.myworkdayjobs.com`)
   d. For **Ashby**, send POST with:
      - `operationName: ApiJobBoardWithTeams`
      - `variables.organizationHostedJobsPageName: {company}`
      - GraphQL query for `jobBoardWithTeams` + `jobPostings { id title locationName employmentType compensationTierSummary }`
   e. For **BambooHR**, the list only brings basic metadata. For each relevant item, read `id`, GET `https://{company}.bamboohr.com/careers/{id}/detail`, and extract the full JD from `result.jobOpening`. Use `jobOpeningShareUrl` as the public URL if present; otherwise use the detail URL.
   f. For **Workday**, send POST JSON with at least `{"appliedFacets":{},"limit":20,"offset":0,"searchText":""}` and paginate by `offset` until results are exhausted
   g. For each job extract and normalize: `{title, url, company}`
   h. Accumulate in candidates list (dedup with Level 1)

6. **Level 3 — WebSearch queries** (serial):
   For each query in `search_queries` with `enabled: true`:
   a. `bash batch/pace-check.sh` → gate
   b. Run WebSearch with the defined `query`
   c. From each result extract: `{title, url, company}`
      - **title**: from the result title (before the " @ " or " | ")
      - **url**: result URL
      - **company**: after the " @ " in the title, or extracted from domain/path
   d. Accumulate in candidates list (dedup with Level 1+2)

7. **Filter by title** using `title_filter` from `portals.yml`:
   - At least 1 keyword from `positive` must appear in the title (case-insensitive)
   - 0 keywords from `negative` must appear
   - `seniority_boost` keywords give priority but are not required

7b. **Filter by location (optional)** using `location_filter` from `portals.yml`:
   - If the `location_filter` block is absent, all locations pass (default behavior)
   - Empty location on an offer → passes (don't penalize missing data)
   - Any `block` keyword present → reject (takes precedence over allow)
   - Empty `allow` → passes (already cleared block)
   - Non-empty `allow` → at least one keyword must match
   - All matches are case-insensitive substring
   - Location is persisted as the 7th column in `scan-history.tsv` for later audit

8. **Deduplicate** against 3 sources:
   - `scan-history.tsv` → exact URL already seen
   - `applications.md` → normalized company + role already evaluated
   - `pipeline.md` → exact URL already pending or processed

8.5. **Verify liveness of WebSearch results (Level 3)** — BEFORE adding to pipeline:

   > ⛔ **ABSOLUTE RULE: No URL from WebSearch (Level 3) can be added to `pipeline.md` without prior Playwright verification.** This rule has no exceptions. Google caches results for weeks or months. In previous scans, 31 URLs were added without verification and 88% were expired. Skipping this step is worse than not scanning. If there's no time to verify, don't add.

   Levels 1 and 2 are inherently real-time and do not require verification.

   For each new Level 3 URL (sequential):
   a. `bash batch/pace-check.sh` → gate
   b. `browser_navigate` to the URL
   c. `browser_snapshot` to read the content
   d. Classify:
      - **Active**: job title visible + role description + Apply/Submit control visible within the main content. Don't count generic header/navbar/footer text.
      - **Expired** (any of these signals):
        - Final URL contains `?error=true` (Greenhouse redirects this way when an offer is closed)
        - Page contains: "job no longer available" / "no longer open" / "position has been filled" / "this job has expired" / "page not found"
        - Redirects to a generic job search page (e.g. `apply.careers.microsoft.com`, `careers.company.com/jobs`)
        - HTTP 404, 410, or 403 — log as `skipped_expired`
        - Only navbar and footer visible, no JD content (content < ~300 chars)
   e. If expired: log in `scan-history.tsv` with status `skipped_expired` and discard
   f. If active: continue to step 9

   **Don't abort the entire scan if one URL fails.** If `browser_navigate` errors (timeout, 403, etc.), mark as `skipped_expired` and continue with the next.

9. **For each new verified offer that passes filters**:
   a. Add to `pipeline.md` under "Pending": `- [ ] {url} | {company} | {title}`
   b. Log in `scan-history.tsv`: `{url}\t{date}\t{query_name}\t{title}\t{company}\tadded`

10. **Offers filtered by title**: log in `scan-history.tsv` with status `skipped_title`
11. **Duplicate offers**: log with status `skipped_dup`
12. **Expired offers (Level 3)**: log with status `skipped_expired`

## Title and Company Extraction from WebSearch Results

WebSearch results come in format: `"Job Title @ Company"` or `"Job Title | Company"` or `"Job Title — Company"`.

Extraction patterns by portal:
- **Ashby**: `"Senior AI PM (Remote) @ EverAI"` → title: `Senior AI PM`, company: `EverAI`
- **Greenhouse**: `"AI Engineer at Anthropic"` → title: `AI Engineer`, company: `Anthropic`
- **Lever**: `"Product Manager - AI @ Temporal"` → title: `Product Manager - AI`, company: `Temporal`

Generic regex: `(.+?)(?:\s*[@|—–-]\s*|\s+at\s+)(.+?)$`

## Private URLs

If a URL is found that is not publicly accessible:
1. Save the JD to `jds/{company}-{role-slug}.md`
2. Add to pipeline.md as: `- [ ] local:jds/{company}-{role-slug}.md | {company} | {title}`

## Scan History

`data/scan-history.tsv` tracks ALL URLs seen:

```
url	first_seen	portal	title	company	status
https://...	2026-02-10	Ashby — AI PM	PM AI	Acme	added
https://...	2026-02-10	Greenhouse — SA	Junior Dev	BigCo	skipped_title
https://...	2026-02-10	Ashby — AI PM	SA AI	OldCo	skipped_dup
https://...	2026-02-10	WebSearch — AI PM	PM AI	ClosedCo	skipped_expired
```

## Output Summary

```
Portal Scan (serial) — {YYYY-MM-DD}
━━━━━━━━━━━━━━━━━━━━━━━━━━
Companies scanned: N
Offers found: N total
Filtered by title: N relevant
Duplicates: N (already evaluated or in pipeline)
Expired discarded: N (dead links, Level 3)
New added to pipeline.md: N

  + {company} | {title} | {query_name}
  ...

→ Run /career-ops pipeline to evaluate the new offers.
```

## careers_url Management

Each company in `tracked_companies` must have `careers_url` — the direct URL to their job listings page. This avoids looking it up every time.

**RULE: Always use the company's corporate URL; fall back to the ATS endpoint only if no corporate page exists.**

`careers_url` should point to the company's own careers page whenever available. Many companies use Workday, Greenhouse, or Lever underneath, but expose job IDs only through their corporate domain. Using the direct ATS URL when a corporate page exists can cause false 410 errors because the job IDs don't match.

| ✅ Correct (corporate) | ❌ Incorrect as first option (direct ATS) |
|---|---|
| `https://careers.mastercard.com` | `https://mastercard.wd1.myworkdayjobs.com` |
| `https://openai.com/careers` | `https://job-boards.greenhouse.io/openai` |
| `https://stripe.com/jobs` | `https://jobs.lever.co/stripe` |

Fallback: if you only have the direct ATS URL, navigate to the company website first and find their corporate careers page. Use the direct ATS URL only if the company has no corporate careers page.

**Known patterns by platform:**
- **Ashby:** `https://jobs.ashbyhq.com/{slug}`
- **Greenhouse:** `https://job-boards.greenhouse.io/{slug}` or `https://job-boards.eu.greenhouse.io/{slug}`
- **Lever:** `https://jobs.lever.co/{slug}`
- **BambooHR:** list `https://{company}.bamboohr.com/careers/list`; detail `https://{company}.bamboohr.com/careers/{id}/detail`
- **Teamtailor:** `https://{company}.teamtailor.com/jobs`
- **Workday:** `https://{company}.{shard}.myworkdayjobs.com/{site}`
- **Custom:** Company's own URL (e.g. `https://openai.com/careers`)

**API/feed patterns by platform:**
- **Ashby API:** `https://jobs.ashbyhq.com/api/non-user-graphql?op=ApiJobBoardWithTeams`
- **BambooHR API:** list `https://{company}.bamboohr.com/careers/list`; detail `https://{company}.bamboohr.com/careers/{id}/detail` (`result.jobOpening`)
- **Lever API:** `https://api.lever.co/v0/postings/{company}?mode=json`
- **Teamtailor RSS:** `https://{company}.teamtailor.com/jobs.rss`
- **Workday API:** `https://{company}.{shard}.myworkdayjobs.com/wday/cxs/{company}/{site}/jobs`

**If `careers_url` doesn't exist** for a company:
1. Try the pattern for its known platform
2. If that fails, do a quick WebSearch: `"{company}" careers jobs`
3. Navigate with Playwright to confirm it works — pace check first
4. **Save the found URL in portals.yml** for future scans

**If `careers_url` returns 404 or redirect:**
1. Note it in the output summary
2. Try scan_query as fallback
3. Flag for manual update

## portals.yml Maintenance

- **ALWAYS save `careers_url`** when adding a new company
- Add new queries as new portals or interesting roles are discovered
- Disable queries with `enabled: false` if they generate too much noise
- Adjust filter keywords as target roles evolve
- Add companies to `tracked_companies` when you want to track them closely
- Periodically verify `careers_url` — companies change ATS platforms
