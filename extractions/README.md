# Extractions: what each query answers

Each SQL file in [`sql/`](sql/) answers one question about the PHP ecosystem. All of them run on the HTTP Archive crawl in
BigQuery (`httparchive.crawl.pages`) for **mobile, root pages only**, once per crawl date, and return a small table with a
`crawl_date` column so the dashboard can show change over time. They are registered in
[`../scripts/queries.sh`](../scripts/queries.sh) and shown on the page
[PHP applications on the web](../dashboard/pages/php-applications.md).

| SQL file | Question it answers | Output | Scans (per crawl date) |
|---|---|---|---|
| [`totals.sql`](sql/totals.sql) | How many sites run a PHP-based application, and what share of CMS sites and online shops is that? | 1 row per crawl | ~8 GB |
| [`platforms.sql`](sql/platforms.sql) | Which CMS and ecommerce platforms are biggest, and which of them are PHP? | up to 100 rows per crawl | ~8 GB |
| [`families.sql`](sql/families.sql) | For platforms with add-ons, how many sites run the base alone and how many with an add-on? | 1 row per family (6) per crawl | ~4 GB |

`_preamble.sql` holds the lists shared by `totals.sql` and `platforms.sql` (which technologies count as PHP applications, which
detections are not platforms, which mark builders that merely support selling). It is not a query on its own.

## `totals.sql`: how big is PHP, and does it depend on the definition?

**Questions it answers**
- What share of CMS sites runs on a PHP application? (`pct_of_cms_on_php`)
- What share of online shops runs on one, using the Web Almanac's definition of a shop (`pct_of_shops_on_php`) and a stricter one that drops
  site-builder commerce flags (`pct_php_strict`)?
- Do "the crawler flagged PHP" and "the site runs a named PHP application" agree? (`php_detected`, `runs_a_php_application`,
  `php_app_but_php_not_flagged`, `php_without_a_named_application`)
- How much of WordPress is plain WordPress versus WooCommerce or Easy Digital Downloads? (`wp_core_only`, `woocommerce`, `easy_digital_downloads`)

**Why it exists:** "PHP is on over half of sites" invites the reply that those are old, unmaintained servers. Counting sites that run
named, actively developed applications moves the burden of proof.

**Shown in:** the headline numbers, the share-of-CMS/shops line chart, the PHP-flag-vs-application chart and table, and the WordPress-family chart.

**Read with care**
- Counts are sites crawled, and the crawl was much smaller in 2021 and 2022 than later. Compare **shares** across crawls, not raw counts.
- "On PHP" means one of the applications in the list in `_preamble.sql`. Platforms the detection data does not link to PHP either way
  (such as Shoper and JTL Shop) are not on it.
- A site with both WooCommerce and Easy Digital Downloads is counted in both.
- Technology names and rules come from Wappalyzer and change between crawls, so part of any trend can be detection change.

## `platforms.sql`: who are the big platforms?

**Questions it answers**
- Which 100 CMS and ecommerce platforms have the most sites in a crawl, and are they PHP-based? (`platform`, `is_php`, `sites`)

**Why it exists:** it puts the PHP share in context. A PHP platform is only impressive next to the non-PHP alternatives it competes with.

**Shown in:** the "Top platforms" bar chart (latest crawl).

**Read with care:** some rows are add-ons that run on another row (WooCommerce on WordPress), so one site can appear in several rows. Never sum the rows.

## `families.sql`: base platform or add-on?

**Questions it answers**
- For each family (WordPress, Weebly, Webflow, Magento, Wix, Squarespace), how many sites run the base platform, and how many of those also run
  a derivative such as WooCommerce, Hyva Themes or Wix eCommerce? (`parent_sites`, `core_only`, `with_derivative`, `pct_with_derivative`)
- Is the parent/derivative link trustworthy? (`derivative_without_parent` should be near zero: add-on detected, base not.)

**Why it exists:** site counts per platform cannot separate core from add-on, because a derivative site carries both detections and is counted
in both rows. This query splits them using the crawl itself.

**Shown in:** the "Core vs derivatives" table (latest crawl).

**Read with care:** the parent/derivative links are recorded by hand in the query (`families` CTE). Wappalyzer's metadata records no other parent links, so
anything not listed counts as standalone.

## Not answered yet

- Which **PHP versions** are in use, and how fast does the web move to supported ones? (Needs a different detection signal.)
- How are **frameworks** (Laravel, Symfony and others) distributed? These are detected as technologies but are not CMS or ecommerce, so these queries skip them.
- **Packagist and licensing** questions need other sources. Two are planned (see the main README roadmap):
  - licence in `LICENSE` versus `composer.json` (GitHub API): how often do the two sources of "what licence is this?" disagree?
  - the first two years of a package (Packagist and ecosyste.ms): do early download patterns differ between adopted and unadopted packages?

To add a query, follow "Adding or changing queries" in the [main README](../README.md), then add a section here with the same headings:
*questions it answers, why it exists, shown in, read with care*.