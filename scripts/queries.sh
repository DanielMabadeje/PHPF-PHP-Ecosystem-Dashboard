# Registry of HTTP Archive queries. Sourced by run_httparchive.sh and combine.sh.
# One entry per query:  "<sql file name without .sql>|<uses _preamble.sql: 1 or 0>|<dashboard table name>"
# The dashboard table name is what pages query as php.<table>.
QUERIES=(
  "totals|1|php_apps_totals"
  "platforms|1|php_apps_platforms"
  "families|0|php_apps_families"
)