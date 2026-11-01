# Vendored queries and scripts for the report snapshots

The studies behind the dashboard's **snapshot** pages were run by their authors and published in ThePHPF/SIG-ambassadors, PR #40
(credit: GianfriAur). The queries and scripts are copied here **verbatim**, with a header comment naming the source document and code block, so the results can
be reproduced or checked without the PR. They are exported by `scripts/export_report_queries.py`, never retyped.

**Important:** this project has not run these queries against BigQuery or the APIs. They are the authors' code as published. Check a dry run before a real run,
and see `pr-40-review.md` for known issues in some of them (for example, the vendor-committed share in the Composer query).

| File | Runs on | How | Feeds |
|---|---|---|---|
| `github_repos_composer.sql` | BigQuery `github_repos` (frozen snapshot, loaded 2025-10-14) | `scripts/run_report_query.sh github_repos_composer run` | `composer_adoption.csv` |
| `github_repos_licences.sql` | BigQuery `github_repos` | `scripts/run_report_query.sh github_repos_licences run` | `php_licences.csv` |
| `stackoverflow_bigquery.sql` | BigQuery `stackoverflow` (frozen dump, 2022) | `scripts/run_report_query.sh stackoverflow_bigquery run` | `so_questions_*.csv` (BigQuery rows) |
| `stackoverflow_sede.sql` | data.stackexchange.com (T-SQL) | by hand in the browser; export the result as CSV | `so_questions_*.csv` (Data Explorer rows) |
| `github_longevity_first_commits.sql` | BigQuery `github_repos.commits` | by hand; the output is joined to the repository list by `scripts/score.php` | `top_long_running_php.csv` |
| `scripts/collect.php` | GitHub search API | `php collect.php` (about 10 requests a minute; set a token for more) | input to `score.php` |
| `scripts/score.php` | local, reads the files above | `php score.php` | `top_long_running_php.csv` |
| `scripts/discrepancy.php` | GitHub API + raw.githubusercontent.com | `php discrepancy.php` (hours; writes after every cell) | `licence_vs_composer_*.csv` |
| `scripts/cohort.php` | Packagist + ecosyste.ms APIs | `php -d memory_limit=2G cohort.php` | not charted yet |

## Checking a rerun against the published numbers

```bash
./scripts/run_report_query.sh all dry      # bytes each query would scan; nothing is billed
./scripts/run_report_query.sh all run      # writes data/reports/raw/*.csv (guarded by MAX_BYTES_BILLED, default 100 GB)
python3 scripts/verify_report_tables.py    # compares them with data/reports/*.csv; exit code 1 on any difference
```

The runner refuses output whose first column is wrong, empty output, and any echoed statement text. The verifier only compares: it never overwrites `data/reports/`.
Because both datasets are frozen snapshots, a rerun should reproduce the published counts exactly.

The runner and verifier were tested here with a stand-in for `bq` (clean, echoed, wrong-header and empty output) and with a round trip from the published tables.
That checks their logic, not the queries themselves.

## Regenerating these files

```bash
python3 scripts/export_report_queries.py ../SIG-ambassadors/subgroup-research --commit <sha>
```
