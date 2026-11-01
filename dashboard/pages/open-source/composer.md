---
title: Composer adoption
sidebar_position: 1
sidebar_badge: report
---

**The question:** of the public repositories that contain PHP, how many take part in the Composer ecosystem, and how do they lay their projects out?

<Alert status="info">
Snapshot of the SIG report <a href="https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/reports/composer-adoption.md">Composer adoption across public PHP repositories</a>,
from the GitHub dataset in BigQuery (loaded 2025-10-14). Not refreshed by this project's query runner.
</Alert>

```sql adoption
with m as (
  select
    max(case when metric = 'PHP repositories (total)' then repositories end) as total,
    max(case when metric = 'Ships a composer.json' then repositories end) as with_manifest,
    max(case when metric = 'No composer.json' then repositories end) as without_manifest,
    max(case when metric = 'Manifest at repository root' then repositories end) as at_root,
    max(case when metric = 'Manifest outside the root' then repositories end) as outside_root,
    max(case when metric = 'vendor/ committed to Git' then repositories end) as vendor_all,
    max(case when metric = 'vendor/ committed, no manifest' then repositories end) as vendor_no_manifest
  from php.composer_adoption
)
select
  *,
  round(100.0 * with_manifest / total, 2) as pct_with_manifest,
  round(100.0 * at_root / with_manifest, 2) as pct_root_of_manifest,
  round(100.0 * (vendor_all - vendor_no_manifest) / with_manifest, 2) as pct_vendor_of_manifest
from m
```

```sql layout_groups
select 'No composer.json' as layout, without_manifest as repositories, 1 as ord from ${adoption}
union all
select 'composer.json at the repository root', at_root, 2 from ${adoption}
union all
select 'composer.json in a subdirectory', outside_root, 3 from ${adoption}
order by ord
```

```sql vendor_rows
select 'vendor/ committed, and the repo ships a manifest' as what,
       vendor_all - vendor_no_manifest as repositories,
       round(100.0 * (vendor_all - vendor_no_manifest) / with_manifest, 2) as pct,
       'of repos that ship a manifest' as out_of,
       1 as ord
from ${adoption}
union all
select 'vendor/ committed, no manifest',
       vendor_no_manifest,
       round(100.0 * vendor_no_manifest / without_manifest, 2),
       'of repos without a manifest',
       2
from ${adoption}
order by ord
```

## How many PHP repositories use Composer?

<BigValue data={adoption} value=total title="PHP repositories" fmt=num0 />
<BigValue data={adoption} value=pct_with_manifest title="Ship their own composer.json (%)" />
<BigValue data={adoption} value=pct_root_of_manifest title="Manifest at the repo root, of those (%)" />

A repository counts here when GitHub's language detection finds PHP in it, **including repositories where PHP is only a minor part of the code**.
A JavaScript project with one stray `.php` file is in the total, which pushes up the share without a `composer.json`.

<BarChart
  data={layout_groups}
  x=layout
  y=repositories
  swapXY=true
  sort=false
  yFmt=num0
  title="PHP repositories by Composer layout"
/>

Of the repositories that ship a manifest, the conventional layout (`composer.json` next to the README) is overwhelmingly the norm. The subdirectory group mixes two
different situations: monorepos, where it is deliberate, and projects whose PHP code ended up under `src/`, `api/` or `web/`. The paths alone cannot tell them apart.

## Dependencies committed to Git

Some projects commit their `vendor/` directory instead of installing dependencies from the lock file.

<DataTable data={vendor_rows}>
  <Column id=what title="Group" />
  <Column id=repositories title="Repositories" fmt=num0 />
  <Column id=pct title="Share (%)" fmt=num1 />
  <Column id=out_of title="Out of" />
</DataTable>

**A note on the denominator.** The SIG report lists `vendor/` committed as 17,443 repositories and 10.95% "of Composer users". That 17,443 includes the 2,067 repositories
with no manifest at all, so dividing it by the repositories that ship one mixes two groups. The table above splits them: among repositories that ship a manifest, 9.66% commit
`vendor/`. The second row is the group the report calls "invisible to any manifest-based search": they use the ecosystem without the file that describes it.

## Read with care

- **A snapshot, not a live count.** The dataset behind this was last loaded in October 2025.
- **Not all of GitHub.** It only covers repositories GitHub classifies as open source through its licence API, and file contents only for text files under 10 MB.
- **Presence of a manifest is not adoption.** A manifest in a test fixture or an example directory counts the same as a project's own.
- **Shares have different denominators.** Each row of the table above says what it is a share of.
