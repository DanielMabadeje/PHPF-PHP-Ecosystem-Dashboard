---
title: Research questions and queries
---

The PHP Foundation SIG research compilation documents ten extractions spanning web usage, open-source repositories, packages,
licensing and Stack Overflow. The links below point to the query and method notes in
[SIG-ambassadors PR #40](https://github.com/ThePHPF/SIG-ambassadors/pull/40).

The HTTP Archive PHP-application extraction has refreshable result tables in this dashboard. CMS-version charts use the published 2025
and 2026 report snapshots; they are not refreshed by this project's query runner. The other research results are not loaded here, so
they are references for future work—not live charts or refreshed estimates.

| Research question | Query / method reference | Dashboard status |
|---|---|---|
| How long have popular PHP projects been running? | [GitHub PHP project longevity](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-php-longevity.md) | Research source; results not loaded |
| How has PHP's share of Stack Overflow questions changed over time, using BigQuery? | [Stack Overflow BigQuery extraction](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/stackoverflow-bigquery.md) | Research source; results not loaded |
| What licences do public PHP repositories declare? | [GitHub repository licences](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-repos-licences.md) | Research source; results not loaded |
| How many public GitHub repositories contain PHP, and what Composer signals do they expose? | [GitHub repositories](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-repos.md) | Research source; results not loaded |
| How common is PHP across crawled websites? | [HTTP Archive crawl](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/httparchive-crawl.md) | Related HTTP Archive totals are published |
| How has PHP's share of Stack Overflow questions changed over time, using SEDE? | [Stack Overflow SEDE extraction](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/stackoverflow-sede.md) | Research source; results not loaded |
| Which PHP applications and platforms run on the public web? | [HTTP Archive PHP applications](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/httparchive-php-applications.md) | Dashboard-backed by [`totals.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/totals.sql), [`platforms.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/platforms.sql) and [`families.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/families.sql) |
| Which WordPress, Drupal and Magento versions are visible on public sites? | [HTTP Archive CMS versions](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/raw-data/extractions/httparchive-cms-versions.md) | [2025 and 2026 report snapshots published](/php-usage/versions); not refreshed by this project's query runner |
| How often does a repository's `LICENSE` file disagree with `composer.json`? | [Licence file vs Composer](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/licence-file-vs-composer.md) | Research source; results not loaded |
| What do the first two years of a Packagist package tell us about adoption? | [Package first two years](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/package-first-two-years.md) | Research source; results not loaded |
| Which PHP repositories have at least 1,000 GitHub stars? | [GitHub PHP repositories](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-php-repositories.md) | Research source; results not loaded |

## Queries currently powering charts

The dashboard's local query registry is maintained in [`scripts/queries.sh`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/scripts/queries.sh):

- [`totals.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/totals.sql) powers overall PHP, CMS, ecommerce and WordPress-family counts.
- [`platforms.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/platforms.sql) powers platform comparisons and trends.
- [`families.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/families.sql) powers add-on adoption and family checks.

For query definitions, outputs and caveats, read the [extraction guide](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/README.md).
To add one of the research-only datasets, its results need to be collected, checked, and published as a dashboard source before charting it.
