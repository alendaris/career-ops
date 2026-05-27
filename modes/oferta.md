# Mode: oferta — Full A-G Evaluation

When the candidate pastes a job offer (text or URL), ALWAYS deliver all 7 blocks (A–F scored dimensions + G legitimacy). **Every block is required for every report regardless of score or final decision. SKIP does NOT mean abbreviate.**

## Step 0 — Archetype Detection

Classify the offer into one of the target archetypes (see `_profile.md`). If hybrid, list the 2 closest. This determines:
- Which proof points to prioritize in Block A
- How to score Block B (North Star Alignment)
- Which STAR stories to prepare in the Interview Plan

---

## Block A — CV Match

**Score: X.X/5**

Read `cv.md`. Create a table mapping each JD requirement to exact CV evidence.

| JD Requirement | CV Evidence | Strength |
|----------------|-------------|----------|

Strength key: ✅ Strong / ✅ Meets / ⚠️ Partial / ❌ Gap

**Gaps** — for each gap:
1. Hard blocker or nice-to-have?
2. Adjacent experience available?
3. Mitigation plan (phrase, framing, or portfolio project)

**Score guidance:**
- 4.5–5.0: All required qualifications met with strong evidence; differentiators present
- 3.5–4.4: All or nearly all required met; gaps only on preferred items
- 2.5–3.4: Most required met; 1–2 hard gaps on required items
- 1.5–2.4: Significant required gaps or wrong-archetype tool/skill set
- 1.0–1.4: Fundamental mismatch (wrong archetype, massively overqualified/underqualified, required credential missing)

---

## Block B — North Star Alignment

**Score: X.X/5**

How well the role fits the candidate's target archetypes and career direction. Consider: archetype detected, role-shape fit (build vs. manage vs. deploy), domain transferability, and whether this is a step toward the North Star or a lateral/backward move.

**Score guidance:**
- 4.5–5.0: Primary archetype (Senior DA, DS, Analytics Manager) with strong role-shape fit
- 3.5–4.4: Primary archetype but role-shape concerns (e.g., too much infrastructure ownership, domain pivot required)
- 2.5–3.4: Secondary archetype (BI Developer, Power BI Developer) — skill match but not the career target
- 1.0–2.4: Wrong archetype (DE/AE/infrastructure, entry level, unrelated domain, contract-only)

---

## Block C — Compensation

**Score: X.X/5**

Table with disclosed range or market estimate vs. candidate's targets. Note negotiation angle or floor risk.

| Source | Data |
|--------|------|

**Score guidance** (from `_profile.md`):
- Published range includes $100K–$120K → 4.0–4.5
- Published ceiling $115K–$120K → 4.0
- Published ceiling $100K–$115K → 3.5–3.8
- Published ceiling < $100K or midpoint below $100K → 2.0–3.0
- No salary disclosed → 3.5; estimate from market + company size

Apply COL adjustment for confirmed relocation markets (see `_profile.md` location policy).

---

## Block D — Cultural Signals

**Score: X.X/5**

Company stability, remote policy, team structure, culture analogues to KPMG consulting. Cross-reference with Block G research (layoffs, hiring freeze signals).

**Score guidance:**
- 4.5–5.0: Stable company, consulting/analytics culture analogous to KPMG, strong remote/hybrid policy
- 3.5–4.4: Solid company with minor concerns (no comp disclosure, early-stage startup risk, limited remote)
- 2.5–3.4: Mixed signals (recent layoffs in adjacent departments, opaque hiring pattern, startup < 20 people)
- 1.0–2.4: Concerning signals (resume farming pattern, ghost job indicators, no company presence)

---

## Block E — Red Flags

**Score: X.X/5** (5.0 = no red flags; deduct for each blocker or warning)

| Flag | Type | Impact |
|------|------|--------|

Types: Hard Stop / Soft Gap / Warning
If no red flags: "No material red flags."

**Score guidance:**
- 5.0: No blockers or material warnings
- 4.0–4.9: One soft gap; manageable with mitigation
- 3.0–3.9: One hard gap or two or more soft gaps
- 2.0–2.9: Multiple hard gaps or one decisive blocker (mandatory clearance, contract-only, out-of-market location)
- 1.0–1.9: Multiple decisive blockers

---

## Block F — Location

**Score: X.X/5**

Assess against location policy in `_profile.md`.

| Signal | Detail |
|--------|--------|

**Score guidance** (from `_profile.md`):
- Remote (any US) → 5.0
- DFW on-site/hybrid, commute ≤ 35 min from 75007 → 5.0
- Confirmed relocation markets (Orlando, LA/Anaheim, Bay Area, Toledo OH orbit) → 4.5
- DFW on-site/hybrid, long commute (Fort Worth far west, Denton, McKinney) → 3.5
- Any other US relocation required → 1.0
- Multiple locations including DFW: score as DFW (per `_profile.md` multi-location rule)

---

## Block G — Posting Legitimacy

Analyze the job posting for signals that indicate whether this is a real, active opening. This helps the user prioritize their effort on opportunities most likely to result in a hiring process.

**Ethical framing:** Present observations, not accusations. Every signal has legitimate explanations. The user decides how to weigh them.

### Signals to analyze (in order):

**1. Posting Freshness** (from Playwright snapshot, already captured in Step 0):
- Date posted or "X days ago" — extract from page
- Apply button state (active / closed / missing / redirects to generic page)
- If URL redirected to generic careers page, note it

**2. Description Quality** (from JD text):
- Does it name specific technologies, frameworks, tools?
- Does it mention team size, reporting structure, or org context?
- Are requirements realistic? (years of experience vs technology age)
- Is there a clear scope for the first 6-12 months?
- Is salary/compensation mentioned?
- What ratio of the JD is role-specific vs generic boilerplate?
- Any internal contradictions? (entry-level title + staff requirements, etc.)

**3. Company Hiring Signals** (2-3 WebSearch queries, combine with Block D research):
- Search: `"{company}" layoffs {year}` — note date, scale, departments
- Search: `"{company}" hiring freeze {year}` — note any announcements
- If layoffs found: are they in the same department as this role?

**4. Reposting Detection** (from scan-history.tsv):
- Check if company + similar role title appeared before with a different URL
- Note how many times and over what period

**5. Role Market Context** (qualitative, no additional queries):
- Is this a common role that typically fills in 4-6 weeks?
- Does the role make sense for this company's business?
- Is the seniority level one that legitimately takes longer to fill?

### Output format:

**Assessment:** One of three tiers:
- **High Confidence** — Multiple signals suggest a real, active opening
- **Proceed with Caution** — Mixed signals worth noting
- **Suspicious** — Multiple ghost job indicators, investigate before investing time

**Signals table:** Each signal observed with its finding and weight (Positive / Neutral / Concerning).

**Context Notes:** Any caveats (niche role, government job, evergreen position, etc.) that explain potentially concerning signals.

### Edge case handling:
- **Government/academic postings:** Longer timelines are standard. Adjust thresholds (60-90 days is normal).
- **Evergreen/continuous hire postings:** If the JD explicitly says "ongoing" or "rolling," note it as context — this is not a ghost job, it is a pipeline role.
- **Niche/executive roles:** Staff+, VP, Director, or highly specialized roles legitimately stay open for months. Adjust age thresholds accordingly.
- **Startup / pre-revenue:** Early-stage companies may have vague JDs because the role is genuinely undefined. Weight description vagueness less heavily.
- **No date available:** If posting age cannot be determined and no other signals are concerning, default to "Proceed with Caution" with a note that limited data was available. NEVER default to "Suspicious" without evidence.
- **Recruiter-sourced (no public posting):** Freshness signals unavailable. Note that active recruiter contact is itself a positive legitimacy signal.

---

## Post-evaluation

**ALWAYS** after generating blocks A-G (plus Customization Plan and Interview Plan):

### 1. Save report .md

Save the full evaluation to `reports/{###}-{company-slug}-{YYYY-MM-DD}.md`.

- `{###}` = next sequential number (3 digits, zero-padded)
- `{company-slug}` = company name in lowercase, no spaces (use hyphens)
- `{YYYY-MM-DD}` = current date

**Report format:**

```markdown
# Evaluation Report #{###} — {Company}

**Role:** {Role}
**Company:** {Company}
**Score:** {X.X/5}
**URL:** {url}
**PDF:** ❌ or ✅
**Legitimacy:** {High Confidence | Proceed with Caution | Suspicious}
**Date:** {YYYY-MM-DD}

---

## Block A — CV Match
**Score: X.X/5**
(full content — match table + gaps)

## Block B — North Star Alignment
**Score: X.X/5**
(full content — archetype fit, role-shape analysis, career direction)

## Block C — Compensation
**Score: X.X/5**
(full content — comp table, floor/ceiling check, negotiation angle)

## Block D — Cultural Signals
**Score: X.X/5**
(full content — company stability, remote policy, culture fit)

## Block E — Red Flags
**Score: X.X/5**
(full content — flags table or "No material red flags")

## Block F — Location
**Score: X.X/5**
(full content — location assessment per policy)

## Block G — Posting Legitimacy
**Assessment: {High Confidence | Proceed with Caution | Suspicious}**
(signals table + context note — no numeric score)

---

## Customization Plan
(ALL reports: for score < 4.0 write "Not pursuing — {reason}. If pursuing after {condition}: {table}". For score ≥ 4.0: full table of CV/LinkedIn changes.)

## Interview Plan
(ALL reports: for score < 4.0 write "Not pursuing." For score ≥ 4.0: STAR+R stories table mapped to JD requirements.)

## Machine Summary

```yaml
company: "{company}"
role: "{role}"
score: {X.X}
legitimacy_tier: "{High Confidence | Proceed with Caution | Suspicious}"
archetype: "{detected}"
final_decision: "{Apply | Consider | Skip}"
hard_stops:
  - "{blocking gap or risk}"
soft_gaps:
  - "{non-blocking gap}"
top_strengths:
  - "{strength most relevant to this role}"
risk_level: "{Low | Medium | High}"
confidence: "{Low | Medium | High}"
next_action: "{one concrete next step}"
```
```

### 2. Register in tracker

**ALWAYS** register in `data/applications.md`:
- Next sequential number
- Current date
- Company
- Role
- Score: match average (1-5)
- Status: `Evaluated`
- PDF: ❌ (or ✅ if auto-pipeline generated PDF)
- Report: relative link to the report .md (e.g. `[001](reports/001-company-2026-01-01.md)`)

**Tracker format:**

```markdown
| # | Date | Company | Role | Score | Status | PDF | Report |
```
