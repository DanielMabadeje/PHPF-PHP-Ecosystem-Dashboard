---
title: Platform families
---

Some detected technologies are add-ons or variants of another platform. For example, a site running WooCommerce also runs WordPress.
This page looks at how much of each listed platform family is detected with an add-on, and whether the relationship stays consistent
across crawls.

```sql family_trends
select
  strftime(crawl_date, '%Y-%m') as crawl,
  family,
  parent_sites,
  core_only,
  with_derivative,
  pct_with_derivative,
  derivative_without_parent
from php.php_apps_families
order by crawl_date, family
```

```sql latest_families
select
  family,
  parent_sites,
  core_only,
  with_derivative,
  pct_with_derivative,
  derivative_without_parent
from php.php_apps_families
where crawl_date = (select max(crawl_date) from php.php_apps_families)
order by parent_sites desc
```

## Add-on adoption over time

<LineChart
  data={family_trends}
  x=crawl
  xType=category
  sort=false
  y=pct_with_derivative
  series=family
  yAxisTitle="% of parent-platform sites"
  title="Share of each platform family detected with a listed add-on"
/>

The chart includes every family in the query, including site builders such as Wix, Squarespace and Webflow. It is useful for comparing
add-on patterns, not for estimating PHP's share of the web. WordPress and Magento are PHP-based examples in this set.

## Core platform and add-ons in the latest crawl

<BarChart
  data={latest_families}
  x=family
  y={['core_only','with_derivative']}
  type=stacked
  swapXY=true
  sort=false
  yFmt=num0
  title="Sites running a platform alone or with a listed add-on"
/>

<DataTable data={latest_families}>
  <Column id=family title="Platform family" />
  <Column id=parent_sites title="Sites on parent platform" fmt=num0 />
  <Column id=core_only title="Parent only" fmt=num0 />
  <Column id=with_derivative title="With add-on" fmt=num0 />
  <Column id=pct_with_derivative title="% with add-on" />
  <Column id=derivative_without_parent title="Add-on detected without parent" fmt=num0 />
</DataTable>

Within a family, `core_only` plus `with_derivative` equals `parent_sites`. These categories are exclusive within the family, but the same
site may belong to more than one family. `Add-on detected without parent` is a data-quality check and should be close to zero.

## Query and source

This page uses [`families.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/families.sql).
See [what each extraction answers](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/README.md)
and the [research query index](/php-usage/research-questions).
