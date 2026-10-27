---
title: Glossary
---

Plain-language definitions of the terms used on this dashboard. If a chart confuses you, start with
[the three groups of PHP sites](#the-three-groups-of-php-sites) below.

## The three groups of PHP sites

Two separate questions are asked about every site in the crawl:

1. **Is it flagged as PHP?** Did the crawler's detection list include a technology called `PHP` for this site?
2. **Does it run a named PHP application?** Did the detection list include at least one technology from our list of PHP-based
   applications (WordPress, WooCommerce, Drupal, Magento and so on)?

Answering both questions gives three groups of sites that use PHP, and these are the numbers behind the charts:

```sql latest_crawl
select strftime(crawl_date, '%Y-%m') as crawl, total_sites
from php.php_apps_totals
order by crawl_date desc
limit 1
```

```sql groups
with latest as (
  select * from php.php_apps_totals order by crawl_date desc limit 1
)
select 'A. Runs a named PHP application, and is flagged as PHP' as which_sites,
       runs_a_php_application - php_app_but_php_not_flagged as sites, 1 as ord from latest
union all
select 'B. Flagged as PHP, but runs no named application',
       php_without_a_named_application, 2 from latest
union all
select 'C. Runs a named PHP application, but is not flagged as PHP',
       php_app_but_php_not_flagged, 3 from latest
union all
select 'All sites flagged as PHP (A + B)', php_detected, 4 from latest
union all
select 'All sites running a named PHP application (A + C)', runs_a_php_application, 5 from latest
order by ord
```

Worked example for the <Value data={latest_crawl} column=crawl /> crawl, out of <Value data={latest_crawl} column=total_sites fmt=num0 /> sites:

<DataTable data={groups}>
  <Column id=which_sites title="Group" />
  <Column id=sites title="Sites" fmt=num0 />
</DataTable>

- **A** is the normal case: a WordPress or Drupal site, which the crawler also marks as PHP.
- **B** is PHP the application list does not see: custom code, frameworks used directly (such as Laravel or Symfony),
  or applications that are not on our list.
- **C** is almost always empty, and that is by design, not a coincidence. See "implies" below.

## Terms

**Crawl, crawl date.** The HTTP Archive visits a very large list of websites about once a month and records what each one sends back.
One such run is a crawl, labelled by its month (for example `2025-07`). This dashboard uses the five crawls the Web Almanac uses, so
the numbers can be compared with its published chapters. The data is only as recent as the latest crawl.

**Site, root page.** A "site" here means a website's home page (the "root page"). The crawl does not look at every page of every site.

**Mobile client.** The crawl was run as a phone would browse. Desktop figures can differ slightly.

**Technology detection, Wappalyzer.** Wappalyzer is the tool that looks at what a site sends (response headers, cookies, scripts,
markup) and recognises technologies from it. A site that hides or removes those traces is not detected, so every figure is a
**floor**, not an exact count. Wappalyzer's rules change over time, so part of any change between crawls can be detection change
rather than real change.

**Detected / flagged as PHP.** A site is *flagged as PHP* when `PHP` appears in its list of detected technologies. That can happen in two ways:
- **Direct evidence:** the crawler sees something PHP-specific, for example an `X-Powered-By: PHP` header or a PHP session cookie.
- **Implied:** another detection brings PHP with it (see below).

**Implies.** A rule that says "if technology A is detected, technology B is present too". For most PHP applications the rule lists `PHP`, so when
WordPress, Drupal, Joomla or Magento is detected, PHP is added automatically. This is why group C above is close to zero:
it can only contain applications whose rules do not imply PHP.

**Requires.** A rule that says "A is only ever detected on top of B". WooCommerce *requires* WordPress and does not imply PHP itself. It reaches
PHP only through WordPress. A count that only followed "implies" would miss it, although it is the largest PHP commerce platform in the crawl.

**Named PHP application, named app.** A site on which at least one technology from our list of PHP-based applications was detected.
The list is written by hand in
[`extractions/sql/_preamble.sql`](https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard/blob/main/extractions/sql/_preamble.sql)
and reproduces the figures in the Web Almanac. It includes WordPress, WooCommerce, Drupal, Joomla, Magento, PrestaShop, OpenCart, TYPO3,
Shopware and others. It is **not** all PHP software. Counting only named applications therefore understates PHP.

**Runs no named application.** Flagged as PHP, but none of the technologies on that list were detected (group B).

**CMS.** Content management system: the software behind most blogs and company sites. A site is counted as a CMS site when at least one of its
detected technologies is in the Wappalyzer category "CMS".

**Ecommerce, shop.** A site is counted as an online shop when it has a technology in the category "Ecommerce". We use two definitions:
- *Web Almanac definition* (the default): drops two detections that mark a shop without being a platform, `Cart Functionality` and
  `Google Analytics Enhanced eCommerce`. Used so the figure can be compared with the published report.
- *Strict definition* (`pct_php_strict`): also drops `Squarespace Commerce` and `Wix eCommerce`, which record that a site builder *supports* selling,
  not that a particular site sells.

**Platform.** A CMS or ecommerce technology, such as WordPress or Shopify.

**Family, base platform, add-on (derivative), core only.** Some platforms run on top of another one: WooCommerce on WordPress, Hyva Themes on Magento.
The base is the *parent*, the add-on is the *derivative*, and the two together are a *family*. "Core only" means a site runs the base without
any add-on. A site running an add-on is counted under both the add-on and its parent in platform lists, so never add those rows together.

**Share, count.** A *count* is a number of sites. A *share* (percentage) is that number divided by the sites in the crawl. The crawl was much
smaller in 2021 and 2022 than later, so compare shares between crawls, not counts.

**Limits of every figure here.** Mobile crawl only; home pages only; undetected technology is counted as absent; detection rules change between crawls.