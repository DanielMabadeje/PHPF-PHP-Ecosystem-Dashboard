#!/usr/bin/env bash
# Re-runs one of the vendored BigQuery queries from extractions/reports/ and saves the raw result in data/reports/raw/.
#   ./scripts/run_report_query.sh <name> dry     # print bytes it would scan, bill nothing
#   ./scripts/run_report_query.sh <name> run     # run it and write data/reports/raw/<name>.csv
#   ./scripts/run_report_query.sh all dry|run    # every query below
# Names: github_repos_composer | github_repos_licences | stackoverflow_bigquery
# Env: GCP_PROJECT (billing project), MAX_BYTES_BILLED (per-query guard, default 100 GB; raise it after a dry run).
# Then check the result against the published numbers with: python3 scripts/verify_report_tables.py
set -euo pipefail
cd "$(dirname "$0")/.."

# name|expected first column of the result (a bad or echoed output is refused)
QUERIES=( "github_repos_composer|total_php_repos" "github_repos_licences|license" "stackoverflow_bigquery|quarter" )
TARGET="${1:?usage: run_report_query.sh <name|all> <dry|run>}"; MODE="${2:-dry}"
MAX_BYTES="${MAX_BYTES_BILLED:-100000000000}"
PROJECT_FLAG=(); [ -n "${GCP_PROJECT:-}" ] && PROJECT_FLAG=(--project_id="$GCP_PROJECT")
mkdir -p data/reports/raw
found=0
for entry in "${QUERIES[@]}"; do
  IFS='|' read -r name first_col <<< "$entry"
  [ "$TARGET" = "all" ] || [ "$TARGET" = "$name" ] || continue
  found=1
  sql="extractions/reports/$name.sql"; out="data/reports/raw/$name.csv"
  # SQL goes in on stdin: the files start with '--' comments, which bq would otherwise parse as flags.
  if [ "$MODE" = "dry" ]; then
    echo "== $name"
    bq ${PROJECT_FLAG[@]+"${PROJECT_FLAG[@]}"} --quiet query --use_legacy_sql=false --dry_run < "$sql"
  else
    echo "== $name -> $out"
    bq ${PROJECT_FLAG[@]+"${PROJECT_FLAG[@]}"} --quiet --format=csv query --use_legacy_sql=false \
       --max_rows=100000 --maximum_bytes_billed="$MAX_BYTES" < "$sql" > "$out.tmp"
    awk -v c="$first_col" 'index($0, c ",")==1{p=1} p' "$out.tmp" > "$out.tmp2" && mv "$out.tmp2" "$out.tmp"   # drop any echoed statement text
    head -n 1 "$out.tmp" | grep -q "^$first_col," || { echo "unexpected output for $name; first lines:" >&2; head -3 "$out.tmp" >&2; rm -f "$out.tmp"; exit 1; }
    [ "$(wc -l < "$out.tmp")" -ge 2 ] || { echo "empty result for $name" >&2; rm -f "$out.tmp"; exit 1; }
    mv "$out.tmp" "$out"
  fi
done
[ "$found" = 1 ] || { echo "unknown query '$TARGET'" >&2; exit 2; }
