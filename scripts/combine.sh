#!/usr/bin/env bash
# Merges the per-date CSVs into one file per query for the dashboard source.
set -euo pipefail
cd "$(dirname "$0")/.."
DEST=dashboard/sources/php
mkdir -p "$DEST"
for q in totals platforms families; do
  files=( $(ls data/httparchive/$q/*.csv 2>/dev/null | sort) )
  [ ${#files[@]} -gt 0 ] || { echo "no data for $q; run the refresh workflow first" >&2; exit 1; }
  out="$DEST/php_apps_$q.csv"
  head -n 1 "${files[0]}" > "$out"
  for f in "${files[@]}"; do tail -n +2 "$f" >> "$out"; done
  echo "wrote $out (${#files[@]} crawl dates)"
done
