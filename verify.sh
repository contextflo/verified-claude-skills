#!/usr/bin/env bash
# Runs every query in one pack (or all packs) against BigQuery.
# A query fails if BigQuery returns an error or zero rows.
#
# Usage:
#   BQ_PROJECT=my-billing-project ./verify.sh              # all packs
#   BQ_PROJECT=my-billing-project ./verify.sh ga4          # one pack
#   BQ_PROJECT=my-billing-project ./verify.sh ga4/queries/01-sessions.sql
#
# Optional:
#   DATASET=my-project.analytics_123456  run the pack against your own dataset
#                                        instead of the public sample named in
#                                        each file's "-- dataset:" header
#   MAX_BYTES=2000000000                 per-query scan cap (default 2 GB)
#   SHOW=1                               print the first 5 rows of each result
#
# BQ_PROJECT is only the project that runs (and pays for) the jobs. The public
# sample datasets are free to read up to your monthly free tier.

set -u

if [ -z "${BQ_PROJECT:-}" ]; then
  echo "BQ_PROJECT is not set (the GCP project that runs the queries)" >&2
  exit 2
fi

for tool in bq jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required but not installed" >&2
    exit 2
  fi
done

MAX_BYTES="${MAX_BYTES:-2000000000}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"

files=()
if [ -z "$TARGET" ]; then
  for f in "$ROOT"/*/queries/*.sql; do files+=("$f"); done
elif [ -f "$TARGET" ]; then
  files+=("$TARGET")
elif [ -d "$ROOT/$TARGET/queries" ]; then
  for f in "$ROOT/$TARGET"/queries/*.sql; do files+=("$f"); done
else
  echo "No pack or file named $TARGET" >&2
  exit 2
fi

passed=0
failed=0
failed_files=()

for f in "${files[@]}"; do
  rel="${f#$ROOT/}"
  sql="$(cat "$f")"

  if [ -n "${DATASET:-}" ]; then
    sample="$(grep -m1 '^-- dataset:' "$f" | sed 's/^-- dataset:[[:space:]]*//')"
    if [ -z "$sample" ]; then
      echo "FAIL  $rel  (DATASET set but file has no -- dataset: header)"
      failed=$((failed + 1)); failed_files+=("$rel"); continue
    fi
    sql="${sql//$sample/$DATASET}"
  fi

  start=$(date +%s)
  out="$(printf '%s\n' "$sql" | bq --quiet --project_id="$BQ_PROJECT" query \
    --use_legacy_sql=false --format=json --max_rows=10000 \
    --maximum_bytes_billed="$MAX_BYTES" 2>&1)"
  status=$?
  secs=$(( $(date +%s) - start ))

  if [ $status -ne 0 ]; then
    echo "FAIL  $rel  (BigQuery error)"
    printf '%s\n' "$out" | tail -n 5 | sed 's/^/      /'
    failed=$((failed + 1)); failed_files+=("$rel"); continue
  fi

  rows="$(printf '%s' "$out" | jq 'length' 2>/dev/null)"
  if [ -z "$rows" ] || [ "$rows" = "0" ]; then
    echo "FAIL  $rel  (zero rows)"
    failed=$((failed + 1)); failed_files+=("$rel"); continue
  fi

  echo "ok    $rel  ($rows rows, ${secs}s)"
  if [ -n "${SHOW:-}" ]; then
    printf '%s' "$out" | jq -c '.[:5][]' | sed 's/^/      /'
  fi
  passed=$((passed + 1))
done

echo
echo "verify: $passed passed, $failed failed, $((passed + failed)) total"
if [ $failed -ne 0 ]; then
  printf '  failed: %s\n' "${failed_files[@]}"
  exit 1
fi
