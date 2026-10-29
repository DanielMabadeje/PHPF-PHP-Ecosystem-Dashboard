---
title: Platform trends
---

Which PHP-based platforms are most widely detected, and how has their reach changed across the included HTTP Archive crawls?
This page follows the leading PHP platforms in the latest crawl and compares their site counts and share of all crawled sites over time.

```sql latest_platforms
select
  p.platform,
  p.sites,
  round(100.0 * p.sites / t.total_sites, 2) as pct_all_sites
from php.php_apps_platforms p
join php.php_apps_totals t on p.crawl_date = t.crawl_date
where p.crawl_date = (select max(crawl_date) from php.php_apps_platforms)
  and p.is_php = true
order by p.sites desc
limit 12
```

```sql platform_trends
with latest_php_platforms as (
  select platform
  from php.php_apps_platforms
  where crawl_date = (select max(crawl_date) from php.php_apps_platforms)
    and is_php = true
  order by sites desc
  limit 8
)
select
  strftime(p.crawl_date, '%Y-%m') as crawl,
  p.platform,
  p.sites,
  round(100.0 * p.sites / t.total_sites, 2) as pct_all_sites
from php.php_apps_platforms p
join php.php_apps_totals t on p.crawl_date = t.crawl_date
join latest_php_platforms top on p.platform = top.platform
where p.is_php = true
order by p.crawl_date, p.sites desc
```

## Leaders in the latest crawl

<DataTable data={latest_platforms} rows=12>
  <Column id=platform title="PHP platform" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=pct_all_sites title="% of all crawled sites" />
</DataTable>

The percentage uses all home pages in that crawl as its denominator. It is not a share of PHP platforms: a site can run more than one
platform, and add-ons can be counted alongside their parent platform.

## How their reach changed

<LineChart
  data={platform_trends}
  x=crawl
  xType=category
  sort=false
  y=sites
  series=platform
  yAxisTitle="Detected sites"
  title="Site counts for the eight leading PHP platforms in the latest crawl"
/>

HTTP Archive crawls differ in size, so counts alone can make growth look larger or smaller than it is.

<LineChart
  data={platform_trends}
  x=crawl
  xType=category
  sort=false
  y=pct_all_sites
  series=platform
  yAxisTitle="% of all crawled sites"
  title="Share of all crawled sites for the same PHP platforms"
/>

The set of platforms is chosen from the latest crawl and then followed backward. A platform not detected in an earlier crawl has no row
for that crawl. Wappalyzer's detection rules can change, so movements may reflect detection changes as well as real-world adoption.

## Query and source

These charts use [`platforms.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/platforms.sql)
and [`totals.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/totals.sql).
See [what each extraction answers](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/README.md)
and the [research query index](/php-usage/research-questions).
