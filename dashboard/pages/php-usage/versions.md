---
title: CMS versions
---

Do public websites still run forgotten, long-outdated PHP applications? The HTTP Archive can sometimes read a CMS version from a
home page, which lets us check the versions that sites expose. The two snapshots below compare July 2025 with July 2026.

> **Headline:** six weeks after WordPress 7.0 shipped, 59.84% of WordPress sites that exposed a version were already on 7.0.
> This is a share of the **versioned WordPress sites**, not all WordPress sites or all websites. The crawl could identify a version for
> 63.48% of detected WordPress installations, so the 7.0 figure represents about 38% of all detected WordPress sites.

```sql version_coverage
select
  strftime(crawl_date, '%Y-%m') as crawl,
  technology,
  detected_sites,
  sites_with_version,
  sites_without_version,
  pct_with_version
from php.cms_version_coverage
order by crawl_date, technology
```

```sql latest_wordpress
select version_group, sites, share_pct, support_status
from php.cms_versions
where technology = 'WordPress'
  and crawl_date = date '2026-07-01'
  and share_basis = 'versioned'
order by sites desc
```

```sql unsupported_versions
select
  strftime(crawl_date, '%Y-%m') as crawl,
  technology,
  sum(share_pct) as pct_versioned_on_eol_releases
from php.cms_versions
where technology in ('Drupal', 'Magento')
  and share_basis = 'versioned'
  and support_status = 'End of life'
group by crawl_date, technology
order by crawl_date, technology
```

## What versions do sites expose?

<BarChart
  data={latest_wordpress}
  x=version_group
  y=share_pct
  yFmt=num1
  swapXY=true
  sort=false
  title="WordPress version distribution, July 2026"
/>

Shares in the chart are among WordPress sites that declared a version. The 36.52% whose version was not identified are excluded from the
chart, not treated as an old release.

<DataTable data={latest_wordpress}>
  <Column id=version_group title="WordPress version" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
  <Column id=support_status title="Release status at crawl" />
</DataTable>

The latest crawl found 5,090,760 WordPress sites; 3,231,804 exposed a version. Of those versioned sites, 59.84% reported 7.0, released
six weeks before the crawl. The year before, 65.07% of versioned sites were on WordPress 6.8 eleven weeks after its release. The two
snapshots suggest fast adoption in both cases; they are not a monthly time series.

## Older releases remain visible

<BarChart
  data={unsupported_versions}
  x=crawl
  xType=category
  sort=false
  y=pct_versioned_on_eol_releases
  yFmt=num1
  series=technology
  yAxisTitle="% of versioned sites"
  title="Drupal and Magento sites reporting an end-of-life release"
/>

In July 2026, 39.54% of versioned Drupal sites were on releases no longer receiving security fixes, down from 51.2% a year earlier.
Drupal 7 alone accounted for 21.77%; Drupal 8 and 9 accounted for another 17.77%. Magento 1 was still reported by 1,322 sites
(4.58% of versioned Magento installations), despite reaching end of life in 2020.

```sql latest_coverage
select technology, detected_sites, sites_with_version, sites_without_version, pct_with_version
from php.cms_version_coverage
where crawl_date = date '2026-07-01'
order by technology
```

<LineChart
  data={version_coverage}
  x=crawl
  xType=category
  sort=false
  y=pct_with_version
  yFmt=num1
  series=technology
  yAxisTitle="% of detected sites"
  title="Share of detected CMS sites that expose a version"
/>

<DataTable data={latest_coverage}>
  <Column id=technology title="Application" />
  <Column id=detected_sites title="Detected sites" fmt=num0 />
  <Column id=sites_with_version title="Version identified" fmt=num0 />
  <Column id=sites_without_version title="Version not identified" fmt=num0 />
  <Column id=pct_with_version title="% with a version identified" fmt=num1 />
</DataTable>

## How to interpret this evidence

- **A detected version is not a patch-level check.** The report groups by major/minor, so it cannot tell whether a site has the latest security patch.
- **Unknown is not old.** Sites that hide the generator tag or version header are counted as version not identified. This group is not random:
  removing version details is common hardening practice and may correlate with more actively maintained sites.
- **Detection coverage differs.** Version coverage is 63.48% for WordPress, 82.17% for Drupal and 65.16% for Magento in July 2026.
  Do not assume the visible versions perfectly represent installations whose version is hidden.
- **Scope is limited.** These are HTTP Archive mobile crawls of public home pages, not server inventories, authenticated pages or every PHP application.
- **Only two yearly snapshots are available here.** Counts can change because the crawl's site list changes. Compare version shares within each application,
  not detected site counts across crawls.

The version distributions and caveats are transcribed from the SIG research reports for [2025](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/reports/cms-versions.md)
and [2026](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/reports/cms-versions-2026.md).
The `cms_versions.csv` and `cms_version_coverage.csv` tables in this repository are published-report snapshots, not automatically
refreshed extractions.
See the [source query and methodology](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/raw-data/extractions/httparchive-cms-versions.md).
