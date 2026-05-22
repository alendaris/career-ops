# Memory Index

- [Skill accuracy & framing rules](user_skills_accuracy.md) — Ground truth on James's actual skill levels; prevents overclaiming Python/ML/Azure/PySpark in CVs and reports
- [Pipeline rate limit pacing](feedback_pipeline-rate-limit-pacing.md) — Check pace-check.sh before each pipeline item; pause via ScheduleWakeup if wait > 60s; sustainable rate is mandatory, not optional
- [KPMG org context & product analytics framing](user_kpmg_org_context.md) — James is in GMS Tax Technology (builds client-facing platforms), not pure consulting — treat as product/platform analytics for screening questions and role fit scoring
- [LinkedIn saved jobs URL](reference_linkedin-saved-jobs-url.md) — Saved jobs are at /jobs-tracker/ (not the deprecated /my-items/saved-job-searches/ which is 404); alerts at /jobs/alerts/
- [LinkedIn dedup & recovery scripts](feedback_linkedin-dedup.md) — batch/dedup-ids.sh for per-page dedup; batch/extract-scan-ids.sh and batch/extract-job-metadata.sh to recover IDs/metadata from interrupted session transcripts
