# Pipeline Reload Instruction

Every 10 JDs processed in a pipeline batch, reload:
1. `modes/_shared.md`
2. `modes/oferta.md` (or the active mode file)
3. `modes/_profile.md`
4. `cv.md`
5. This instruction file: `.claude/skills/career-ops/pipeline-reload-instruction.md`

This ensures scoring logic, profile context, and instructions stay fresh throughout a long batch run.
