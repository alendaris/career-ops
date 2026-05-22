#!/usr/bin/env bash
# Batch progress status line — reads batch-state.tsv, no LLM calls.
STATE="/Users/jameslackey/code/career-ops/batch/batch-state.tsv"
INPUT="/Users/jameslackey/code/career-ops/batch/batch-input.tsv"

[[ ! -f "$STATE" ]] && echo "Batch: not started" && exit 0

total=$(( $(wc -l < "$INPUT") - 1 ))
completed=0; skipped=0; processing=0; failed=0
score_sum=0; score_count=0

while IFS=$'\t' read -r id url status _ _ _ score _ _; do
  [[ "$id" == "id" || -z "$id" ]] && continue
  case "$status" in
    completed) (( completed++ ))
      if [[ "$score" != "-" && -n "$score" ]]; then
        score_sum=$(awk "BEGIN{print $score_sum + $score}")
        (( score_count++ ))
      fi ;;
    skipped)   (( skipped++ )) ;;
    processing) (( processing++ )) ;;
    failed)    (( failed++ )) ;;
  esac
done < "$STATE"

done_count=$(( completed + skipped ))
avg=""
(( score_count > 0 )) && avg=" avg=$(awk "BEGIN{printf \"%.1f\", $score_sum/$score_count}")"

parts="✅${completed}"
(( skipped > 0 ))    && parts+=" ⏭️${skipped}"
(( processing > 0 )) && parts+=" 🔄${processing}"
(( failed > 0 ))     && parts+=" ❌${failed}"

echo "Batch ${done_count}/${total} | ${parts}${avg}"
