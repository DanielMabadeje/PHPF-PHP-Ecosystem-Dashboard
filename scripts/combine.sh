#!/usr/bin/env bash
# Builds every table the Evidence "php" source reads, in dashboard/sources/php/:
#   1. one merged CSV per BigQuery query in scripts/queries.sh (from data/httparchive/<query>/<date>.csv)
#   2. every published-report snapshot in data/reports/*.csv (copied as is; the file name is the table name)
# Both inputs are tracked in git. The output folder is generated and git-ignored, so CI must run this script.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/queries.sh

DEST=dashboard/sources/php
mkdir -p "$DEST"
for entry in "${QUERIES[@]}"; do
  IFS='|' read -r q _preamble table <<< "$entry"
  files=( $(ls data/httparchive/$q/*.csv 2>/dev/null | sort) )
  [ ${#files[@]} -gt 0 ] || { echo "no data for '$q'; run the refresh workflow first" >&2; exit 1; }
  out="$DEST/$table.csv"
  head -n 1 "${files[0]}" > "$out"
  for f in "${files[@]}"; do tail -n +2 "$f" >> "$out"; done
  echo "wrote $out (${#files[@]} crawl dates)"
done

shopt -s nullglob
reports=( data/reports/*.csv )
for f in "${reports[@]}"; do
  cp "$f" "$DEST/$(basename "$f")"
done
echo "copied ${#reports[@]} report snapshot tables from data/reports/"
