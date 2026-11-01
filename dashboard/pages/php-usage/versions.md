---
title: CMS versions
sidebar_position: 3
sidebar_badge: report
---

Do public websites still run forgotten, long-outdated PHP applications? The HTTP Archive can sometimes read a CMS version from a
home page, which lets us check the versions that sites expose. The two snapshots below compare July 2025 with July 2026.

> **Headline:** six weeks after WordPress 7.0 shipped, 59.84% of WordPress sites that exposed a version were already on 7.0.
> This is a share of the **versioned WordPress sites**, not all WordPress sites or all websites. The crawl could identify a version for
> 63.48% of detected WordPress installations, so the 7.0 figure represents about 38% of all detected WordPress sites.

**Questions this page answers**

1. What version of WordPress, Drupal and Magento do public sites report? (distribution charts)
2. How many sites run old major versions: WordPress 4.x or 5.x, Drupal 7, Magento 1? (tables and bounds below)
3. How much of that can we actually know, given that a third of sites hide their version? (coverage, and the best-case and worst-case range)
4. Did the picture change between July 2025 and July 2026? (shares within each application)

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

```sql wordpress_age
with bucketed as (
  select
    crawl_date,
    case
      when support_status = 'Current release' then 'Current release'
      when version_group = '5.x' then 'WordPress 5.x'
      when version_group = '4.x' then 'WordPress 4.x'
      when version_group = '3.x and older' then 'WordPress 3.x and older'
      else 'Other 6.x and 7.x releases'
    end as era,
    case
      when support_status = 'Current release' then 1
      when version_group = '5.x' then 3
      when version_group = '4.x' then 4
      when version_group = '3.x and older' then 5
      else 2
    end as era_rank,
    sites
  from php.cms_versions
  where technology = 'WordPress' and share_basis = 'versioned'
)
select
  strftime(crawl_date, '%Y-%m') as crawl,
  era,
  era_rank,
  sum(sites) as sites
from bucketed
group by crawl_date, era, era_rank
order by crawl_date, era_rank
```

```sql wordpress_eras
with bucketed as (
  select
    case
      when support_status = 'Current release' then 'Current release'
      when version_group = '5.x' then 'WordPress 5.x'
      when version_group = '4.x' then 'WordPress 4.x'
      when version_group = '3.x and older' then 'WordPress 3.x and older'
      else 'Other 6.x and 7.x releases'
    end as era,
    case
      when support_status = 'Current release' then 1
      when version_group = '5.x' then 3
      when version_group = '4.x' then 4
      when version_group = '3.x and older' then 5
      else 2
    end as era_rank,
    sites
  from php.cms_versions
  where technology = 'WordPress' and share_basis = 'versioned' and crawl_date = date '2026-07-01'
)
select
  era,
  sum(sites) as sites,
  round(100.0 * sum(sites) / (select sites_with_version from php.cms_version_coverage where technology = 'WordPress' and crawl_date = date '2026-07-01'), 2) as pct_of_versioned,
  round(100.0 * sum(sites) / (select detected_sites from php.cms_version_coverage where technology = 'WordPress' and crawl_date = date '2026-07-01'), 2) as pct_of_all_detected
from bucketed
group by era, era_rank
order by era_rank
```

```sql drupal_mix
select
  strftime(crawl_date, '%Y-%m') as crawl,
  'Drupal ' || version_group as version,
  sites,
  share_pct,
  support_status
from php.cms_versions
where technology = 'Drupal'
  and share_basis = 'versioned'
  and support_status <> 'Invalid reading'
order by crawl_date, try_cast(version_group as integer)
```

```sql drupal_shift
select
  'Drupal ' || version_group as version,
  max(support_status) as status,
  max(case when crawl_date = date '2025-07-01' then share_pct end) as share_2025,
  max(case when crawl_date = date '2026-07-01' then share_pct end) as share_2026,
  max(case when crawl_date = date '2026-07-01' then share_pct end)
    - max(case when crawl_date = date '2025-07-01' then share_pct end) as change_points
from php.cms_versions
where technology = 'Drupal'
  and share_basis = 'versioned'
  and support_status <> 'Invalid reading'
group by version_group
order by try_cast(version_group as integer)
```

```sql magento_split
select
  strftime(crawl_date, '%Y-%m') as crawl,
  'Magento ' || version_group as version,
  sites,
  share_pct,
  support_status
from php.cms_versions
where technology = 'Magento' and share_basis = 'versioned'
order by crawl_date, version_group
```

```sql old_release_range
with old as (
  select crawl_date, technology, sum(sites) as old_sites
  from php.cms_versions
  where share_basis = 'versioned'
    and (
      (technology = 'WordPress' and version_group in ('5.x', '4.x', '3.x and older'))
      or (technology in ('Drupal', 'Magento') and support_status = 'End of life')
    )
  group by crawl_date, technology
)
select
  o.technology || ' ' || strftime(o.crawl_date, '%Y-%m') as label,
  strftime(o.crawl_date, '%Y-%m') as crawl,
  o.technology,
  case when o.technology = 'WordPress' then 'WordPress 5.x or older' else 'End-of-life releases' end as what_counts_as_old,
  o.old_sites,
  round(100.0 * o.old_sites / c.sites_with_version, 2) as pct_of_versioned,
  round(100.0 * o.old_sites / c.detected_sites, 2) as lower_bound_pct,
  round(100.0 * (o.old_sites + c.sites_without_version) / c.detected_sites, 2) as upper_bound_pct
from old o
join php.cms_version_coverage c on c.crawl_date = o.crawl_date and c.technology = o.technology
order by o.technology, o.crawl_date
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

Each pair compares the share of **version-reporting** WordPress sites in that version group for July 2025 and July 2026. The two crawls are one year apart,
not a continuous adoption curve.

**A missing bar does not mean no sites.** The two reports publish different groups. In 2025, 6.4 and 6.5 are listed separately; in 2026 they are folded into
"rest of 6.x", so the "rest of 6.x" bars cover different releases in the two years (6.0 to 6.3 in 2025, 6.0 to 6.5 in 2026) and should not be compared with each other.
7.0 and 6.9 are missing from 2025 simply because they did not exist yet.

<DataTable data={wordpress_comparison}>
  <Column id=crawl title="Crawl year" />
  <Column id=version_group title="WordPress version group" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
</DataTable>

### The latest crawl

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

## How many WordPress sites run an old major version?

This is the question of how much WordPress is still on 4.x or 5.x. The chart groups every versioned WordPress site by how far behind its release is.

<BarChart
  data={wordpress_age}
  x=crawl
  xType=category
  y=sites
  series=era
  type=stacked100
  sort=false
  yAxisTitle="% of versioned WordPress sites"
  title="WordPress sites by release age"
/>

<DataTable data={wordpress_eras}>
  <Column id=era title="Release group (July 2026)" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=pct_of_versioned title="% of versioned sites" fmt=num1 />
  <Column id=pct_of_all_detected title="% of all detected WordPress sites" fmt=num1 />
</DataTable>

Read the last two columns together. The first assumes that only the sites that exposed a version exist. The second keeps the sites that hid it
in the denominator, so it can never overstate the problem, but it also treats every hidden version as if it were not old. The truth for
the hidden group is somewhere between the two, and the [bounds](#how-much-can-we-know-about-hidden-versions) below give the extremes.
The group "3.x and older" contains everything the report did not break out below 4.x, including any 2.x installations; the report does not split them.

## Drupal: which major versions?

<BarChart
  data={drupal_mix}
  x=crawl
  xType=category
  y=sites
  series=version
  type=stacked100
  sort=false
  yAxisTitle="% of versioned Drupal sites"
  title="Drupal sites by major version"
/>

<DataTable data={drupal_shift}>
  <Column id=version title="Version" />
  <Column id=status title="Release status" />
  <Column id=share_2025 title="July 2025 (%)" fmt=num1 />
  <Column id=share_2026 title="July 2026 (%)" fmt=num1 />
  <Column id=change_points title="Change (points)" fmt=num1 />
</DataTable>

Percentages are among Drupal sites that exposed a version. A handful of malformed readings (15 sites in 2025, 18 in 2026) are left out.
Drupal 7 is the oldest major version the report lists. **There is no Drupal 6 row in the published tables**, so this page cannot say how many
sites still run it. Either there are none that expose a version, or the extraction folds them into a group that was not published;
that is a question for the extraction authors, not something the data settles.

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
was explicitly labelled in the source report, so older version groups remain grey rather than being guessed to be end of life.

<DataTable data={support_comparison}>
  <Column id=technology title="Application" />
  <Column id=crawl title="Crawl year" />
  <Column id=support_group title="Support status at crawl" />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
</DataTable>

In July 2026, 39.54% of versioned Drupal sites were on releases no longer receiving security fixes, down from about 51% a year earlier.
Drupal 7 alone accounted for 21.77%; Drupal 8 and 9 accounted for another 17.77%. Magento 1 was still reported by 1,322 sites
(4.58% of versioned Magento installations), despite reaching end of life in 2020.

<DataTable data={magento_split}>
  <Column id=crawl />
  <Column id=version title="Version" />
  <Column id=sites title="Sites" fmt=num0 />
  <Column id=share_pct title="% of versioned sites" fmt=num1 />
  <Column id=support_status title="Release status" />
</DataTable>

Magento 1's share edged up between the two crawls even though fewer sites reported it, because Magento 2 shrank by more. Compare shares within
an application, not site counts across crawls: the crawl's list of sites changes from year to year.

## How much can we know about hidden versions?

About a third of WordPress and Magento sites, and about a fifth of Drupal sites, do not expose a version. Sites that hide it are not random:
removing version details is common hardening practice, so hidden does not mean old, and it does not mean current either. The honest answer is a range.

- **Lower bound:** every hidden site is up to date. Only the old sites we can see are counted, out of *all* detected sites.
- **Upper bound:** every hidden site is old. All hidden sites are added to the visible old ones.

<BarChart
  data={old_release_range}
  x=label
  y={['lower_bound_pct','upper_bound_pct']}
  type=grouped
  sort=false
  yAxisTitle="% of all detected sites"
  title="Sites on old releases: best case and worst case"
/>

<DataTable data={old_release_range}>
  <Column id=technology title="Application" />
  <Column id=crawl />
  <Column id=what_counts_as_old title="Counted as old" />
  <Column id=old_sites title="Visible old sites" fmt=num0 />
  <Column id=pct_of_versioned title="% of versioned" fmt=num1 />
  <Column id=lower_bound_pct title="Lower bound (% of all)" fmt=num1 />
  <Column id=upper_bound_pct title="Upper bound (% of all)" fmt=num1 />
</DataTable>

These two numbers are extremes, not an estimate. They are useful because they show which statements the data can and cannot support: a reader who
says "most WordPress sites are current" or "a large part of Drupal is end of life" can check the claim against the range.

```sql latest_coverage
select technology, detected_sites, sites_with_version, sites_without_version, pct_with_version
from php.cms_version_coverage
where crawl_date = date '2026-07-01'
order by technology
```

## How much of each application exposes a version?

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
- **"Old" is defined per application.** For Drupal and Magento it means a release marked end of life in the report. WordPress has no end-of-life column in the
  published data, so "5.x or older" is a simple age cut-off chosen for this page, not an official support status.

The version distributions and caveats are transcribed from the SIG research reports for [2025](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/reports/cms-versions.md)
and [2026](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/reports/cms-versions-2026.md).
The `cms_versions.csv` and `cms_version_coverage.csv` tables in `data/reports/` are published-report snapshots, not automatically
refreshed extractions.
See the [source query and methodology](https://github.com/ThePHPF/SIG-ambassadors/blob/9585e1ae44816aec066f38a7f72d261a0e5099b2/subgroup-research/raw-data/extractions/httparchive-cms-versions.md).
