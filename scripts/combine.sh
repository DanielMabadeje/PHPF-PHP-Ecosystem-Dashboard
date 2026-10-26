#!/usr/bin/env bash
# Merges the per-date CSVs of every query in scripts/queries.sh into one file per
# query, in the folder the Evidence "php" source reads from.
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