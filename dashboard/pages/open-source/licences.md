---
title: Licences
sidebar_position: 2
sidebar_badge: snapshot
---

**The question:** under what terms is PHP published, and can a company pick a PHP library off the shelf without calling a lawyer?

<Alert status="info">
Snapshot of the SIG report <a href="https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/reports/php-licences.md">The licences of the PHP ecosystem</a>,
from the GitHub dataset in BigQuery (loaded 2025-10-14). Every figure is a share of <strong>licensed</strong> projects: projects without a licence are absent, not counted as zero.
</Alert>

```sql licences
select
  licence,
  family,
  php_main_language_repos as repos,
  round(100.0 * php_main_language_repos / sum(php_main_language_repos) over (), 2) as share_pct,
  contains_any_php_repos as any_php,
  round(1.0 * contains_any_php_repos / php_main_language_repos, 2) as any_php_per_main
from php.php_licences
order by php_main_language_repos desc
```

```sql families
select
  family,
  sum(repos) as repos,
  round(100.0 * sum(repos) / (select sum(repos) from ${licences}), 1) as share_pct
from ${licences}
group by family
order by family desc
```

```sql gpl_in_copyleft
select round(100.0 * sum(case when licence in ('GPL-2.0', 'GPL-3.0', 'AGPL-3.0') then repos end) / sum(repos), 1) as gpl_share
from ${licences}
where family = 'copyleft'
```

```sql licence_totals
select sum(repos) as licensed_repos from ${licences}
```

## Permissive or copyleft?

<BigValue data={licence_totals} value=licensed_repos title="Licensed PHP repositories" fmt=num0 />

<BarChart
  data={families}
  x=family
  y=repos
  yFmt=num0
  title="Licensed PHP repositories by licence family"
/>

<DataTable data={families}>
  <Column id=family title="Family" />
  <Column id=repos title="Projects" fmt=num0 />
  <Column id=share_pct title="Share (%)" fmt=num1 />
</DataTable>

**Permissive** licences (MIT, BSD, Apache, ISC, Unlicense, CC0) let others reuse the code with few conditions. **Copyleft** licences require that changes or combined works
carry the same freedoms. The copyleft group here also includes weaker licences such as LGPL and MPL, which are generally easier to use in a commercial product than the
GPL. In this data, GPL-2.0, GPL-3.0 and AGPL-3.0 make up <Value data={gpl_in_copyleft} column=gpl_share />% of the copyleft group, so the weaker licences change the picture only slightly.

## Which licences?

<BarChart
  data={licences}
  x=licence
  y=repos
  swapXY=true
  sort=false
  series=family
  yFmt=num0
  title="Licensed PHP repositories by licence (PHP is the main language)"
/>

<DataTable data={licences} rows=15>
  <Column id=licence title="Licence" />
  <Column id=family title="Family" />
  <Column id=repos title="Repos, PHP main language" fmt=num0 />
  <Column id=share_pct title="Share (%)" fmt=num1 />
  <Column id=any_php title="Repos containing any PHP" fmt=num0 />
  <Column id=any_php_per_main title="Any-PHP per main-language repo" fmt=num2 />
</DataTable>

MIT is the largest single licence, but more PHP is published under something else than under MIT. GPL-2.0 is the second-largest, and the report suggests a likely reason:
a large part of the WordPress ecosystem inherits that licence. That is a hypothesis, not something this data measures.

The last two columns show two ways of defining "a PHP project". **PHP is the main language** counts repositories where PHP is the largest language by size.
**Contains any PHP** also counts repositories where PHP is a minor part. The ratio runs from 1.3 to 2.8 across the licences and is highest for EPL-1.0 (2.8) and Apache-2.0 (2.2): for those licences, repositories that merely contain PHP outnumber
the ones where PHP is the main language by more than two to one.

## Read with care

- **Only licensed projects.** Every share is out of the projects GitHub already classified as open source; projects without a licence are not in the denominator.
- **Two definitions of "PHP project"**, as above. Which one is right depends on the question.
- **A repository is not a package.** One project can be spread over several repositories, and one repository can hold several packages.
- **A snapshot.** The data was loaded in October 2025.
