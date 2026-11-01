---
title: Long-running PHP projects
sidebar_position: 4
sidebar_badge: snapshot
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

```sql score_example
select
  rank,
  project,
  stars,
  months_running,
  round(log10(stars), 2) as log10_stars,
  round(months_running * log10(stars), 0) as recomputed,
  score
from ${projects}
where rank <= 5
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

## How the score works

**Score = months running × log₁₀(stars).** Two things go in:

- **Months running** is how long the project has existed, counted from its start date to the day the data was collected. It counts linearly: a project twice as old scores twice as much.
- **log₁₀(stars)** turns the star count into a small weight. It is roughly the number of digits: 1,000 stars gives 3, 10,000 gives 4, 100,000 gives 5.
  So ten times the stars multiplies a project's score by only 4/3, and a hundred times the stars by 5/3.

In the top hundred the stars range from about 1,100 to 74,000, so the star weight stays between about 3 and 4.9 and **age does most of the sorting**. Stars act as a modest
tie-breaker that lets a widely followed project edge ahead of an equally old, less followed one.

<DataTable data={score_example}>
  <Column id=rank title="#" />
  <Column id=project title="Project" />
  <Column id=months_running title="Months running" fmt=num0 />
  <Column id=stars title="Stars" fmt=num0 />
  <Column id=log10_stars title="log₁₀(stars)" fmt=num2 />
  <Column id=recomputed title="Months × log₁₀(stars)" fmt=num0 />
  <Column id=score title="Published score" fmt=num0 />
</DataTable>

The recomputed column uses the whole months shown in the table, so it can differ from the published score by a few points because of rounding.

**Who is in the ranking.** Only public PHP repositories with at least 1,000 stars, a push within the last 12 months, and no archive flag. Anything else is not scored at all.

**Why a logarithm.** Stars alone would put a young, hyped project above a long-running one, and age alone would put an old, abandoned one first. The report multiplies the two and
takes the logarithm of the stars so that a project with ten times the stars does not simply score ten times as much.

**What the score does not measure.** It does not measure how widely a project is installed, how actively it is developed, or how important it is. It is a way to order
projects that have lasted and are still noticed.

## What the columns mean

- **Stars:** GitHub stars when the data was collected. A measure of attention, not use.
- **Started:** the project's start date, to the month.
- **Date from:** where that date comes from. `commit` is the project's first commit in the BigQuery commit history, which can reach back before GitHub existed. `GitHub` is the date the repository
  was created on GitHub, used when the commit history has nothing for the project.
- **Months:** months from the start date to the collection date.
- **Last push:** the month of the most recent push. Every project in the list was pushed in the last 12 months.
- **Score:** as above.

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
