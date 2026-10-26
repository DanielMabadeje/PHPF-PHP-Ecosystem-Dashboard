#!/usr/bin/env bash
# Runs the HTTP Archive queries for one or more crawl dates.
#   ./scripts/run_httparchive.sh dry     # print bytes each query would scan, bill nothing
#   ./scripts/run_httparchive.sh run     # run and write data/httparchive/<query>/<date>.csv
# Env:
#   CRAWL_DATES        space-separated, default = the Web Almanac dates
#   MAX_BYTES_BILLED   per-query guard in bytes (default 300 GB). Tune after a dry run.
#   GCP_PROJECT        billing project (optional if gcloud default is set)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-dry}"
DATES="${CRAWL_DATES:-2021-07-01 2022-06-01 2023-06-01 2024-06-01 2025-07-01}"
MAX_BYTES="${MAX_BYTES_BILLED:-300000000000}"
PROJECT_FLAG=()
[ -n "${GCP_PROJECT:-}" ] && PROJECT_FLAG=(--project_id="$GCP_PROJECT")

# query name -> needs the shared preamble?
declare -A PREAMBLE=( [totals]=1 [platforms]=1 [families]=0 )

for date in $DATES; do
  for q in totals platforms families; do
    sql="$(cat extractions/sql/$q.sql)"
    [ "${PREAMBLE[$q]}" = "1" ] && sql="$(cat extractions/sql/_preamble.sql)"$'\n'"$sql"
    out="data/httparchive/$q/$date.csv"
    if [ "$MODE" = "dry" ]; then
      echo "== $q @ $date"
      printf '%s\n' "$sql" | bq "${PROJECT_FLAG[@]}" --quiet query --use_legacy_sql=false --dry_run \
         --parameter="crawl_date:DATE:$date"
    else
      echo "== $q @ $date -> $out"
      printf '%s\n' "$sql" | bq "${PROJECT_FLAG[@]}" --quiet --format=csv query --use_legacy_sql=false \
         --max_rows=1000 --maximum_bytes_billed="$MAX_BYTES" \
         --parameter="crawl_date:DATE:$date" > "$out.tmp"
      # fail loudly on empty results rather than commit a header-only file
      [ "$(wc -l < "$out.tmp")" -ge 2 ] || { echo "empty result for $q @ $date" >&2; rm -f "$out.tmp"; exit 1; }
      mv "$out.tmp" "$out"
    fi
  done
done

if [ "$MODE" = "run" ]; then
  cat > data/metadata.json <<META
{
  "httparchive": {
    "last_refresh": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "crawl_dates": "$(ls data/httparchive/totals | grep -v gitkeep | sed 's/.csv//' | tr '\n' ' ' | sed 's/ *$//')",
    "client": "mobile",
    "scope": "root pages only",
    "source": "httparchive.crawl.pages via BigQuery"
  }
}
META
fi
