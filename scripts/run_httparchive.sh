#!/usr/bin/env bash
# Runs the HTTP Archive queries listed in scripts/queries.sh for one or more crawl dates.
#   ./scripts/run_httparchive.sh dry     # print bytes each query would scan, bill nothing
#   ./scripts/run_httparchive.sh run     # run and write data/httparchive/<query>/<date>.csv
# Env:
#   CRAWL_DATES        space-separated, default = the Web Almanac dates
#   MAX_BYTES_BILLED   per-query guard in bytes (default 20 GB). Tune after a dry run.
#   GCP_PROJECT        billing project ID (optional if gcloud default is set)
# Works with bash 3.2 (macOS) and later.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/queries.sh

MODE="${1:-dry}"
DATES="${CRAWL_DATES:-2021-07-01 2022-06-01 2023-06-01 2024-06-01 2025-07-01}"
MAX_BYTES="${MAX_BYTES_BILLED:-20000000000}"
PROJECT_FLAG=()
[ -n "${GCP_PROJECT:-}" ] && PROJECT_FLAG=(--project_id="$GCP_PROJECT")

echo "mode=$MODE dates=$DATES"

for date in $DATES; do
  for entry in "${QUERIES[@]}"; do
    IFS='|' read -r q preamble _table <<< "$entry"
    mkdir -p "data/httparchive/$q"
    sqlfile="$(mktemp)"
    [ "$preamble" = "1" ] && cat extractions/sql/_preamble.sql >> "$sqlfile"
    cat "extractions/sql/$q.sql" >> "$sqlfile"
    out="data/httparchive/$q/$date.csv"

    # SQL goes in on stdin, never as an argument: it starts with "--" comments,
    # which bq would otherwise parse as flags.
    if [ "$MODE" = "dry" ]; then
      echo "== $q @ $date"
      bq ${PROJECT_FLAG[@]+"${PROJECT_FLAG[@]}"} --quiet query --use_legacy_sql=false --dry_run \
         --parameter="crawl_date:DATE:$date" < "$sqlfile"
    else
      echo "== $q @ $date -> $out"
      bq ${PROJECT_FLAG[@]+"${PROJECT_FLAG[@]}"} --quiet --format=csv query --use_legacy_sql=false \
         --max_rows=1000 --maximum_bytes_billed="$MAX_BYTES" \
         --parameter="crawl_date:DATE:$date" < "$sqlfile" > "$out.tmp"
      # fail loudly on empty results rather than commit a header-only file
      [ "$(wc -l < "$out.tmp")" -ge 2 ] || { echo "empty result for $q @ $date" >&2; rm -f "$out.tmp" "$sqlfile"; exit 1; }
      # the first column of every query is crawl_date; anything else means bq returned
      # something other than the result table (e.g. script text), so do not commit it
      head -n 1 "$out.tmp" | grep -q '^crawl_date' || {
        echo "unexpected output for $q @ $date; first lines:" >&2; head -n 3 "$out.tmp" >&2
        rm -f "$out.tmp" "$sqlfile"; exit 1; }
      mv "$out.tmp" "$out"
    fi
    rm -f "$sqlfile"
  done
done

if [ "$MODE" = "run" ]; then
  first_q="${QUERIES[0]%%|*}"
  cat > data/metadata.json <<META
{
  "httparchive": {
    "last_refresh": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "crawl_dates": "$(ls data/httparchive/$first_q | grep -v gitkeep | sed 's/.csv//' | tr '\n' ' ' | sed 's/ *$//')",
    "client": "mobile",
    "scope": "root pages only",
    "source": "httparchive.crawl.pages via BigQuery"
  }
}
META
fi