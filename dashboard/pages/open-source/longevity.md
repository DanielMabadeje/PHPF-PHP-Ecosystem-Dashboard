---
title: Long-running PHP projects
sidebar_position: 4
sidebar_badge: report
---

**The question:** which public PHP projects have been running the longest and are still being maintained?

<Alert status="info">
Snapshot of the SIG report <a href="https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/reports/top-long-running-php.md">The PHP projects that have run longest</a>,
collected from the GitHub API and the BigQuery commit history. The study is not refreshed by this project's query runner.
</Alert>

```sql projects
select
  rank, project, url, stars, started, start_source, months_running, last_push, score, what_it_is,
  cast(left(started, 4) as integer) as start_year
from php.top_long_running_php
order by rank
```

```sql top_ten
select rank, project, url, stars, started, months_running, what_it_is
from ${projects}
where rank <= 10
order by rank
```

```sql oldest
select project, months_running, start_source
from ${projects}
order by months_running desc, rank
limit 15
```

```sql by_start_year
select start_year, count(*) as projects
from ${projects}
group by start_year
order by start_year
```

```sql by_source
select
  case start_source when 'commit' then 'First commit in the commit history' else 'GitHub creation date' end as date_source,
  count(*) as projects
from ${projects}
group by start_source
order by projects desc
```

## The ten

<DataTable data={top_ten}>
  <Column id=rank title="#" />
  <Column id=url contentType=link linkLabel=project openInNewTab=true title="Project" />
  <Column id=stars title="Stars" fmt=num0 />
  <Column id=started title="Started" />
  <Column id=months_running title="Months" fmt=num0 />
  <Column id=what_it_is title="What it is" />
</DataTable>

The ranking multiplies how long a project has been running by the logarithm of its stars. A project that began in 2001 with a modest following can therefore outrank one that began in 2021 with a huge one.
Only projects with at least 1,000 stars, a push in the last 12 months, and no archive flag are considered.

## When were they started?

<BarChart
  data={by_start_year}
  x=start_year
  xType=category
  y=projects
  sort=false
  title="Start year of the 100 highest-ranked projects"
/>

<BarChart
  data={oldest}
  x=project
  y=months_running
  swapXY=true
  sort=false
  series=start_source
  title="The 15 longest-running projects (months since the start date)"
/>

## Where the start date comes from

<DataTable data={by_source}>
  <Column id=date_source title="Start date taken from" />
  <Column id=projects title="Projects" fmt=num0 />
</DataTable>

GitHub only opened in 2008, so for a project that existed before it moved there, the GitHub creation date understates its age. Where the commit history is available the report uses
the date of the first commit instead. Coverage of that history is incomplete: a project missing from it keeps its GitHub date, so the ranking is biased against projects that are
both old and absent from the commit dataset.

## All hundred

<DataTable data={projects} rows=20 search=true>
  <Column id=rank title="#" />
  <Column id=url contentType=link linkLabel=project openInNewTab=true title="Project" />
  <Column id=stars title="Stars" fmt=num0 />
  <Column id=started title="Started" />
  <Column id=start_source title="Date from" />
  <Column id=months_running title="Months" fmt=num0 />
  <Column id=last_push title="Last push" />
  <Column id=score title="Score" fmt=num0 />
</DataTable>

## Read with care

- **Not one hundred independent projects.** Several rows belong to the same project. For example, many `symfony/*` rows are individual components of Symfony, each with its own repository.
  Counting them separately lengthens the list but does not add independent projects.
- **Recently pushed is not recently developed.** The filter checks the date of the last push. Repositories that receive automated updates pass it without anyone working on them.
- **Stars measure attention, not use.** A heavily installed library can have few stars, and a popular tool can have many without being widely deployed.
- **Whether every row is a PHP project** depends on GitHub's language detection, which counts bytes of code. Repositories with large non-code content can be classified by a small amount of PHP.
