---
title: PHP applications on the web
---

**The question:** when people say "PHP runs a large part of the web", what are they actually pointing at?
This page answers it by counting sites that run a *named PHP application* such as WordPress, Drupal or Magento,
rather than only sites where a crawler spotted the word "PHP".

**Why it matters:** "PHP is on over half of all sites" invites the reply that those are old servers nobody maintains.
"PHP is what WordPress, WooCommerce, Drupal and Magento are written in" is the same fact, but about software that is
actively developed and widely used.

New to these terms (flagged as PHP, named application, crawl)? See the [glossary](/glossary).

**Source:** [HTTP Archive](https://httparchive.org) through Google BigQuery (`httparchive.crawl.pages`), mobile client,
home pages only. Technology detection is [Wappalyzer](https://github.com/HTTPArchive/wappalyzer); its definitions change
between crawls, so part of any trend can be detection change rather than real change.

```sql totals
select
  strftime(crawl_date, '%Y-%m') as crawl,
  *,
  round(100.0 * runs_a_php_application / total_sites, 2) as pct_sites_php_app,
  round(100.0 * php_detected / total_sites, 2) as pct_sites_php_flagged
from php.php_apps_totals
order by crawl_date
```

```sql latest
select * from ${totals} order by crawl_date desc limit 1
```

## The latest crawl at a glance

<BigValue data={latest} value=pct_of_cms_on_php title="CMS sites on PHP (%)" />
<BigValue data={latest} value=pct_of_shops_on_php title="Ecommerce sites on PHP (%)" />
<BigValue data={latest} value=total_sites title="Sites crawled" fmt=num0 />

Of the sites that use a content management system (a CMS, the software behind most blogs and company sites),
the first number is the share built on a PHP application. The second is the same for online shops. The third is how many
home pages the crawl covered, which is the base for everything below.

## Share of CMS and ecommerce sites on PHP

**What it shows:** for each crawl, the percentage of CMS sites and of online shops that run on a PHP-based application.
A line going up means PHP applications are gaining share of that category; down means they are losing it.

<LineChart
  data={totals}
  x=crawl
  xType=category
  sort=false
  y={['pct_of_cms_on_php','pct_of_shops_on_php','pct_php_strict']}
  yAxisTitle="% of sites"
  title="PHP share by crawl"
/>

**Reading the three lines.** `pct_of_cms_on_php` is CMS sites on PHP. `pct_of_shops_on_php` is shops on PHP, using the same
definition of "shop" as the Web Almanac so the figure can be compared with the published report. `pct_php_strict` is the same
but drops two detections, `Squarespace Commerce` and `Wix eCommerce`. Those record that a site builder *supports* selling, not that a
particular site sells, so the strict line is a tighter definition of "online shop".

**Caveats:** "on PHP" means the site runs one of the applications in a fixed list of PHP-based platforms
(see the repository). Platforms that the detection data does not link to PHP either way, such as Shoper and JTL Shop, are not on the list.

## How much PHP is not a named application?

**What it shows:** two groups of sites that use PHP. The first runs a named PHP application (WordPress, Drupal and so on).
The second is flagged as PHP by the crawler but runs none of the applications on our list.

**How "flagged as PHP" works:** the crawler marks a site as PHP in two ways. Either it sees direct evidence (for example an
`X-Powered-By: PHP` header or a PHP session cookie), or another detection implies it: whenever WordPress, Drupal, Joomla or Magento is detected,
PHP is added automatically. This means nearly every site running a listed application is also flagged as PHP, by construction.

<BarChart
  data={totals}
  x=crawl
  xType=category
  y={['runs_a_php_application','php_without_a_named_application']}
  type=stacked
  sort=false
  yFmt=num0
  title="Sites running a named PHP application vs PHP with no named application"
/>

**Reading it:** the bottom segment is sites running a named PHP application. The top segment is sites where the crawler saw PHP directly
but which run no application from our list: custom code, frameworks used directly (such as Laravel or Symfony), or applications we do not name.
That top segment is the part of PHP that a count of named applications leaves out, so counting only named applications **understates** PHP.

**Careful with raw counts.** The HTTP Archive crawl grew a lot between 2021 and 2023, so the bars above get taller partly because
more sites were crawled, not because PHP grew. Compare crawls using the share of all sites below, not the bar heights.

<LineChart
  data={totals}
  x=crawl
  xType=category
  sort=false
  y={['pct_sites_php_app','pct_sites_php_flagged']}
  yAxisTitle="% of all crawled sites"
  title="Share of all crawled sites: running a named PHP application vs flagged as PHP"
/>

The table below gives the numbers. The first column, sites running a named application where PHP was *not* flagged, is close to zero
because of the implication rule above. It is not an independent check on the detection, and it is not evidence that the two methods agree.
The second column is the informative one: the PHP sites that a named-application count does not see.

<DataTable data={totals} rows=10>
  <Column id=crawl />
  <Column id=php_app_but_php_not_flagged title="Named app, PHP not flagged" fmt=num0 />
  <Column id=php_without_a_named_application title="PHP flagged, no named app" fmt=num0 />
</DataTable>

## WordPress family

**What it shows:** how much of "WordPress" is plain WordPress, and how much is WordPress with an ecommerce add-on.
WooCommerce and Easy Digital Downloads are plugins that only run on top of WordPress, so a shop built with them is also a WordPress site.

<BarChart
  data={totals}
  x=crawl
  xType=category
  y={['wp_core_only','woocommerce','easy_digital_downloads']}
  type=stacked
  sort=false
  yFmt=num0
  title="WordPress core only vs WooCommerce vs EDD"
/>

**Reading it:** `wp_core_only` is WordPress sites with no commerce plugin detected. `woocommerce` and `easy_digital_downloads`
are sites running those plugins. These are counts of sites, and the crawl was much smaller in 2021 and 2022 than later, so compare shares rather than bar heights across crawls. A site that has both plugins appears in both series, so adding the bars slightly overstates the
number of WordPress sites. This family matters because WooCommerce alone is the largest PHP commerce platform in the crawl, and
it would be invisible in any count that looked only at which technologies imply PHP.

## Top platforms (latest crawl)

**What it shows:** the 25 most common CMS and ecommerce platforms in the latest crawl, coloured by whether they are PHP-based
(`true`) or not (`false`). It puts the PHP share in context: how large the PHP platforms are compared with the rest of the market.

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

**Caveat:** some rows are add-ons that run on another row (for example WooCommerce on WordPress), so a site can appear in more than
one bar. Do not add the bars together to get a total.

## Core vs derivatives (latest crawl)

**What it shows:** for platforms that have add-ons or variants, how many sites run the base platform alone and how many
run it with a derivative. For WordPress, the derivatives are WooCommerce and Easy Digital Downloads. Examples elsewhere include Magento with Hyva
Themes and Wix with Wix eCommerce.

```sql families
select family, parent_sites, core_only, with_derivative, pct_with_derivative, derivative_without_parent
from php.php_apps_families
where crawl_date = (select max(crawl_date) from php.php_apps_families)
order by parent_sites desc
```

<DataTable data={families}>
  <Column id=family />
  <Column id=parent_sites title="Sites on the base platform" fmt=num0 />
  <Column id=core_only title="Base only" fmt=num0 />
  <Column id=with_derivative title="With a derivative" fmt=num0 />
  <Column id=pct_with_derivative title="% with a derivative" />
  <Column id=derivative_without_parent title="Derivative, base not detected" fmt=num0 />
</DataTable>

**Reading it:** `% with a derivative` is how common the add-on is among sites on the base platform.
The last column is a data-quality check: it counts sites where the add-on was detected but the base platform was not.
It should be close to zero. A large number means the link between the two is wrong, or the base platform is going undetected
on sites where the add-on is visible, which would make the other columns undercount the base.