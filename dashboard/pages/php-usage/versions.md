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

```sql wordpress_comparison
select
  strftime(crawl_date, '%Y') as crawl,
  version_group,
  sites,
  share_pct,
  support_status
from php.cms_versions
where technology = 'WordPress'
  and share_basis = 'versioned'
order by
  case version_group
    when '7.0' then 1
    when '6.9' then 2
    when '6.8' then 3
    when '6.7' then 4
    when '6.6' then 5
    when '6.5' then 6
    when '6.4' then 7
    when 'rest of 7.x' then 8
    when 'rest of 6.x' then 9
    when '5.x' then 10
    when '4.x' then 11
    else 12
  end,
  crawl_date
```

```sql support_comparison
select
  concat(technology, ' ', strftime(crawl_date, '%Y')) as snapshot,
  technology,
  strftime(crawl_date, '%Y') as crawl,
  case
    when support_status in ('Supported', 'Current release') then 'Supported at crawl'
    when support_status = 'End of life' then 'End of life at crawl'
    else 'Status not classified'
  end as support_group,
  sum(share_pct) as share_pct
from php.cms_versions
where share_basis = 'versioned'
group by crawl_date, technology, support_group
order by crawl_date, technology, support_group
```

## What versions do sites expose?

### WordPress version mix: 2025 vs 2026

<BarChart
  data={wordpress_comparison}
  x=version_group
  y=share_pct
  yFmt=num1
  series=crawl
  type=grouped
  swapXY=true
  sort=false
  seriesColors={{'2025':'#2563eb','2026':'#0891b2'}}
  yAxisTitle="% of versioned WordPress sites"
  title="Compare detected WordPress version groups"
/>

Each pair compares the share of **version-reporting** WordPress sites in that version group for July 2025 and July 2026. A missing bar
means the report had no sites in that group. The two crawls are one year apart, not a continuous adoption curve.

<DataTable data={wordpress_comparison}>
  <Column id=crawl title="Crawl year" />
  <Column id=version_group title="WordPress version group" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
</DataTable>

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

## Supported and end-of-life versions

<BarChart
  data={support_comparison}
  x=snapshot
  y=share_pct
  yFmt=num1
  series=support_group
  type=stacked
  swapXY=true
  sort=false
  seriesColors={{'Supported at crawl':'#2563eb','End of life at crawl':'#dc2626','Status not classified':'#9ca3af'}}
  yAxisTitle="% of versioned sites"
  title="Version support status by application and crawl"
/>

Blue marks versions the report identified as supported or current at that crawl; red marks versions it identified as end of life.
Grey means the report did not assign a support status, not that those releases are unsupported. For WordPress, only the current release
was explicitly labelled in the source report, so older version groups remain grey rather than being guessed to be EOL.

<DataTable data={support_comparison}>
  <Column id=technology title="Application" />
  <Column id=crawl title="Crawl year" />
  <Column id=support_group title="Support status at crawl" />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
</DataTable>

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
