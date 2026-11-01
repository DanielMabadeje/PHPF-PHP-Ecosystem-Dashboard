---
title: LICENSE file vs composer.json
sidebar_position: 3
sidebar_badge: report
---

**The question:** a PHP project can state its licence in two places. GitHub reads the licence file; Packagist reads the `license` key in `composer.json`.
How often do the two agree, and what do counts based on one place miss?

<Alert status="info">
Snapshot of the SIG report <a href="https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/reports/licence-file-vs-composer.md">LICENSE against composer.json</a>,
a sample of 4,964 repositories drawn from the GitHub API and weighted back to a population of 918,553. Percentages are estimates with sampling error, and the study is
not refreshed by this project's query runner.
</Alert>

```sql outcomes
select outcome, reported_share_pct as share_pct, row_number() over () as ord
from php.licence_vs_composer_outcomes
order by ord
```

```sql by_stars
select
  case stars_band
    when '100 or more' then 1 when '10 to 99' then 2 when '1 to 9' then 3 else 4 end as band_rank,
  case stars_band when 'none' then '0 stars' else stars_band || ' stars' end as band,
  population,
  agree_pct,
  disagree_pct,
  no_composer_json_pct,
  no_license_key_pct,
  round(100.0 * no_license_key_pct / (100 - no_composer_json_pct), 1) as no_key_among_packages_pct
from php.licence_vs_composer_by_stars
order by band_rank
```

```sql by_stars_long
select band, band_rank, 'Both name the same licence family' as outcome, 1 as o, agree_pct as pct from ${by_stars}
union all select band, band_rank, 'Both name a licence, but different families', 2, disagree_pct from ${by_stars}
union all select band, band_rank, 'No composer.json (not a Composer package)', 3, no_composer_json_pct from ${by_stars}
union all select band, band_rank, 'composer.json has no license key', 4, no_license_key_pct from ${by_stars}
order by band_rank, o
```

```sql by_licence
select
  licence, population, sampled, agree_pct, disagree_pct, no_composer_json_pct, no_license_key_pct, not_spdx_pct
from php.licence_vs_composer_by_licence
order by population desc
```

```sql by_licence_long
select licence, population, 'Both name the same licence family' as outcome, 1 as o, agree_pct as pct from ${by_licence}
union all select licence, population, 'Both name a licence, but different families', 2, disagree_pct from ${by_licence}
union all select licence, population, 'No composer.json (not a Composer package)', 3, no_composer_json_pct from ${by_licence}
union all select licence, population, 'composer.json has no license key', 4, no_license_key_pct from ${by_licence}
union all select licence, population, 'License is free text, not an SPDX identifier', 5, not_spdx_pct from ${by_licence}
order by population desc, o
```

```sql headline
select
  max(case when outcome = 'the two sources agree' then reported_share_pct end) as agree,
  max(case when outcome = 'they disagree' then reported_share_pct end) as disagree
from php.licence_vs_composer_outcomes
```

## What does the whole population look like?

<BarChart
  data={outcomes}
  x=outcome
  y=share_pct
  swapXY=true
  sort=false
  yFmt=num1
  title="Share of PHP repositories with a detected licence, by outcome (%)"
/>

<Value data={headline} column=agree />% of PHP repositories with a detected licence have a `composer.json` that names the same licence family as the licence file, and
<Value data={headline} column=disagree />% contradict it. Most of the rest are simply **absent from Packagist-style counts**: they have no `composer.json` at all, or one without a `license` key.
A count of PHP licences built on `composer.json` and a count built on the licence file therefore describe different populations, one roughly two fifths the size of the other.

## Does popularity change the answer?

<BarChart
  data={by_stars_long}
  x=band
  y=pct
  series=outcome
  type=stacked100
  sort=false
  yAxisTitle="% of repositories in the band"
  title="Outcome by number of GitHub stars"
/>

<DataTable data={by_stars}>
  <Column id=band title="Stars" />
  <Column id=population title="Population" fmt=num0 />
  <Column id=agree_pct title="Agree (%)" fmt=num1 />
  <Column id=disagree_pct title="Disagree (%)" fmt=num1 />
  <Column id=no_composer_json_pct title="No composer.json (%)" fmt=num1 />
  <Column id=no_license_key_pct title="No license key (%)" fmt=num1 />
  <Column id=no_key_among_packages_pct title="No license key, among Composer packages (%)" fmt=num1 />
</DataTable>

The last column divides by the repositories that actually are Composer packages (everything except "No composer.json"). Among popular projects almost every `composer.json` states a licence;
among projects with no stars, a large share of the packages that exist declare nothing.

## Which licences disagree most?

<BarChart
  data={by_licence_long}
  x=licence
  y=pct
  series=outcome
  type=stacked100
  sort=false
  yAxisTitle="% of repositories with that licence"
  title="Outcome by licence on GitHub"
/>

<DataTable data={by_licence} rows=15>
  <Column id=licence title="Licence (GitHub)" />
  <Column id=population title="Population" fmt=num0 />
  <Column id=sampled title="Sampled" fmt=num0 />
  <Column id=agree_pct title="Agree (%)" fmt=num1 />
  <Column id=disagree_pct title="Disagree (%)" fmt=num1 />
  <Column id=no_composer_json_pct title="No composer.json (%)" fmt=num1 />
  <Column id=no_license_key_pct title="No license key (%)" fmt=num1 />
  <Column id=not_spdx_pct title="Not SPDX (%)" fmt=num1 />
</DataTable>

## Read with care

- **A sample, not a census.** Each licence is sampled across four star bands, up to 100 repositories per band, then weighted back to the population. A single licence-and-band cell
  has a wide margin of error; the aggregate rows are more reliable than the small cells.
- **The comparison reduces both sides to a licence family.** `GPL-2.0` and `GPL-3.0` therefore count as agreeing, so "disagree" is a lower bound on real differences in the exact version.
- **Several licences in one `composer.json`.** Where `composer.json` lists more than one licence, the script picks one rather than checking whether any of them matches, so a project that offers
  both MIT and Apache-2.0 can be counted as disagreeing with a licence file that says Apache-2.0. The report estimates this at under 1% of disagreements, but a re-check of the script suggests it can matter more among the largest projects.
- **"Not SPDX" means the string was not a plain identifier.** Composer also accepts expressions such as `(MIT or Apache-2.0)`, which this script's check does not recognise, so some of that group
  may be valid expressions rather than free text.
- **Absent is not the same as failed.** A `composer.json` that could not be downloaded is treated as a missing file, so the "No composer.json" share may include some failed downloads.
