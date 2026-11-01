---
title: Research questions and queries
sidebar_position: 9
---

The PHP Foundation SIG research compilation documents ten extractions spanning web usage, open-source repositories, packages,
licensing and Stack Overflow. The links below point to the query and method notes in
[SIG-ambassadors PR #40](https://github.com/ThePHPF/SIG-ambassadors/pull/40).

The HTTP Archive PHP-application extraction has refreshable result tables in this dashboard. CMS versions, Composer adoption, licences,
licence declarations, long-running projects and Stack Overflow use the studies' published report tables, imported as snapshots
(`data/reports/`); the dashboard's query runner does not refresh them. The Packagist package study is not charted yet.

| Research question | Query / method reference | Dashboard status |
|---|---|---|
| How long have popular PHP projects been running? | [GitHub PHP project longevity](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-php-longevity.md) | Dashboard page: [Long-running PHP projects](/open-source/longevity) (report snapshot) |
| How has PHP's share of Stack Overflow questions changed over time, using BigQuery? | [Stack Overflow BigQuery extraction](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/stackoverflow-bigquery.md) | Used as a cross-check on [Stack Overflow questions](/community/stack-overflow) (report snapshot) |
| What licences do public PHP repositories declare? | [GitHub repository licences](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-repos-licences.md) | Dashboard page: [Licences](/open-source/licences) (report snapshot) |
| How many public GitHub repositories contain PHP, and what Composer signals do they expose? | [GitHub repositories](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-repos.md) | Dashboard page: [Composer adoption](/open-source/composer) (report snapshot) |
| How common is PHP across crawled websites? | [HTTP Archive crawl](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/httparchive-crawl.md) | Related HTTP Archive totals are published |
| How has PHP's share of Stack Overflow questions changed over time, using SEDE? | [Stack Overflow SEDE extraction](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/stackoverflow-sede.md) | Dashboard page: [Stack Overflow questions](/community/stack-overflow) (report snapshot) |
| Which PHP applications and platforms run on the public web? | [HTTP Archive PHP applications](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/httparchive-php-applications.md) | Dashboard-backed by [`totals.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/totals.sql), [`platforms.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/platforms.sql) and [`families.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/families.sql) |
| Which WordPress, Drupal and Magento versions are visible on public sites? | [HTTP Archive CMS versions](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/raw-data/extractions/httparchive-cms-versions.md) | [2025 and 2026 report snapshots published](/php-usage/versions); not refreshed by this project's query runner |
| How often does a repository's `LICENSE` file disagree with `composer.json`? | [Licence file vs Composer](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/licence-file-vs-composer.md) | Dashboard page: [LICENSE file vs composer.json](/open-source/licence-declarations) (report snapshot) |
| What do the first two years of a Packagist package tell us about adoption? | [Package first two years](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/package-first-two-years.md) | Not charted yet: the report's central comparison is still under review |
| Which PHP repositories have at least 1,000 GitHub stars? | [GitHub PHP repositories](https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/raw-data/extractions/github-php-repositories.md) | Feeds [Long-running PHP projects](/open-source/longevity); the full repository list is not published here |

## Queries currently powering charts

The dashboard's local query registry is maintained in [`scripts/queries.sh`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/scripts/queries.sh):

- [`totals.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/totals.sql) powers overall PHP, CMS, ecommerce and WordPress-family counts.
- [`platforms.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/platforms.sql) powers platform comparisons and trends.
- [`families.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/families.sql) powers add-on adoption and family checks.

For query definitions, outputs and caveats, read the [extraction guide](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/README.md).
To add one of the research-only datasets, its results need to be collected, checked, and published as a dashboard source before charting it.
