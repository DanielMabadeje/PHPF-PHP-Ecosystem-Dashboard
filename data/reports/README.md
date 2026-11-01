# Report snapshots

These tables feed the dashboard's **snapshot** pages (Open source on GitHub, Developer community, CMS versions). Each is a published result of a
SIG research study (ThePHPF/SIG-ambassadors, PR #40). This project does not recompute them on every refresh: the studies use sources that cannot be re-run
on a schedule (a frozen BigQuery dataset, rate-limited GitHub API sampling, a browser-only query tool).

`metadata.json` records, for every file, the report it came from, the section, the commit of the research repository and the import date.

## How each file was made, and how to check it

| File(s) | Made by | Underlying query or script (vendored in `extractions/reports/`) | Reproduce or check |
|---|---|---|---|
| `composer_adoption.csv` | `import_report_tables.py`, table "Results" of `composer-adoption.md` | `github_repos_composer.sql` | `run_report_query.sh github_repos_composer run`, then `verify_report_tables.py` |
| `php_licences.csv`, `php_licence_families.csv` | `import_report_tables.py`, tables "Every licence" and "Families" of `php-licences.md` | `github_repos_licences.sql` | `run_report_query.sh github_repos_licences run`, then `verify_report_tables.py`. The family column follows the extraction's definition of permissive licences. |
| `so_questions_quarterly.csv`, `so_questions_yearly.csv` | `import_report_tables.py`, both "By quarter" and both "By year" tables of `php-share-of-stackoverflow.md` (a `source` column tells the two apart) | `stackoverflow_bigquery.sql` (BigQuery snapshot) and `stackoverflow_sede.sql` (Data Explorer) | BigQuery series: `run_report_query.sh stackoverflow_bigquery run`, then `verify_report_tables.py`. Data Explorer series: run the T-SQL by hand at data.stackexchange.com; there is no API. |
| `licence_vs_composer_outcomes.csv`, `_by_licence.csv`, `_by_stars.csv` | `import_report_tables.py`, tables of `licence-file-vs-composer.md` | `scripts/discrepancy.php` (GitHub API) | Cannot be checked by a query. The study samples up to 100 repositories per licence and star band, so a rerun gives different numbers within sampling error. Takes hours at GitHub's search limit. |
| `top_long_running_php.csv` | `import_report_tables.py`, tables "The first hundred" and "The ten" of `top-long-running-php.md` | `scripts/collect.php`, `github_longevity_first_commits.sql`, `scripts/score.php` | Run in that order (see `extractions/reports/README.md`). Results move with GitHub's star counts and last-push dates, so exact numbers will not match. |
| `cms_versions.csv`, `cms_version_coverage.csv` | **By hand** by the dashboard's author, from `reports/cms-versions.md` and `reports/cms-versions-2026.md` at commit `9585e1ae…` | not vendored yet: the extraction `httparchive-cms-versions.md` was not in the checkout used here | No importer and no query yet. To automate: add the extraction to `EXPORTS` in `scripts/export_report_queries.py` and a table parser to `scripts/import_report_tables.py`. |

Everything the dashboard shows from these files is computed from the columns in them (shares, bounds, ratios), not copied from the reports' prose. Where a derived figure differs from
the report's own, the page says so.

## Refreshing from a newer version of the research

```bash
# with a checkout of the research repository at the commit you want
python3 scripts/import_report_tables.py     ../SIG-ambassadors/subgroup-research --commit "$(git -C ../SIG-ambassadors rev-parse HEAD)"
python3 scripts/export_report_queries.py    ../SIG-ambassadors/subgroup-research --commit "$(git -C ../SIG-ambassadors rev-parse HEAD)"
git diff --stat data/ extractions/reports/   # review what changed
./scripts/combine.sh && (cd dashboard && npm run dev)
```

Both scripts stop with an error if a report or extraction no longer has the expected shape, so a reworded document cannot import silently.
