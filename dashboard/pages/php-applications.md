---
title: PHP applications on the web
---

**Source:** [HTTP Archive](https://httparchive.org) via BigQuery (`httparchive.crawl.pages`). Mobile client, root pages only.
Technology detection is [Wappalyzer](https://github.com/HTTPArchive/wappalyzer), and its definitions change between crawls,
so part of any trend can be detection change rather than real change.

```sql totals
select
  strftime(crawl_date, '%Y-%m') as crawl,
  *
from php.php_apps_totals
order by crawl_date
```

```sql latest
select * from ${totals} order by crawl_date desc limit 1
```

<BigValue data={latest} value=pct_of_cms_on_php title="CMS sites on PHP (%)" />
<BigValue data={latest} value=pct_of_shops_on_php title="Ecommerce sites on PHP (%)" />
<BigValue data={latest} value=total_sites title="Sites crawled" fmt=num0 />

## Share of CMS and ecommerce sites on PHP

<LineChart
  data={totals}
  x=crawl
  xType=category
  y={['pct_of_cms_on_php','pct_of_shops_on_php','pct_php_strict']}
  yAxisTitle="% of sites"
  title="PHP share by crawl"
/>

`pct_php_strict` drops `Squarespace Commerce` and `Wix eCommerce`, which mark builders that support selling rather than sites that sell.
The looser figure stays comparable with the Web Almanac.

## Do the `PHP` flag and the application flag agree?

<BarChart
  data={totals}
  x=crawl
  xType=category
  y={['runs_a_php_application','php_without_a_named_application']}
  type=stacked
  yFmt=num0
  title="Sites running a named PHP application vs PHP with no named application"
/>

<DataTable data={totals} rows=10>
  <Column id=crawl />
  <Column id=php_app_but_php_not_flagged fmt=num0 />
  <Column id=php_without_a_named_application fmt=num0 />
</DataTable>

## WordPress family

<BarChart
  data={totals}
  x=crawl
  xType=category
  y={['wp_core_only','woocommerce','easy_digital_downloads']}
  type=stacked
  yFmt=num0
  title="WordPress core only vs WooCommerce vs EDD"
/>

A site with both WooCommerce and EDD appears in both series.

## Top platforms (latest crawl)

```sql platforms
select platform, is_php, sites
from php.php_apps_platforms
where crawl_date = (select max(crawl_date) from php.php_apps_platforms)
order by sites desc
limit 25
```

<BarChart
  data={platforms}
  x=platform
  y=sites
  series=is_php
  swapXY=true
  sort=false
  yFmt=num0
/>

Some rows are add-ons that run on another row (WooCommerce on WordPress), so a site can appear in more than one bar.

## Core vs derivatives (latest crawl)

```sql families
select family, parent_sites, core_only, with_derivative, pct_with_derivative, derivative_without_parent
from php.php_apps_families
where crawl_date = (select max(crawl_date) from php.php_apps_families)
order by parent_sites desc
```

<DataTable data={families}>
  <Column id=family />
  <Column id=parent_sites fmt=num0 />
  <Column id=core_only fmt=num0 />
  <Column id=with_derivative fmt=num0 />
  <Column id=pct_with_derivative />
  <Column id=derivative_without_parent fmt=num0 />
</DataTable>

`derivative_without_parent` should be near zero. A large value means the parent link is wrong or the parent goes undetected.
