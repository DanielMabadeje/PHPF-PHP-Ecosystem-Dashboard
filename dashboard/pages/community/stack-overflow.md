---
title: Stack Overflow questions
sidebar_position: 1
sidebar_badge: report
---

**The question:** what share of all Stack Overflow questions are about PHP, and how has that changed since the site opened in 2008?

<Alert status="info">
Snapshot of the SIG report <a href="https://github.com/ThePHPF/SIG-ambassadors/blob/main/subgroup-research/reports/php-share-of-stackoverflow.md">PHP's share of Stack Overflow questions</a>.
The main series comes from the Stack Exchange Data Explorer (refreshed weekly); a BigQuery snapshot from 2022 is used only as a cross-check.
Not refreshed by this project's query runner.
</Alert>

```sql explorer_quarters
select
  quarter_start,
  year,
  quarter,
  php_questions,
  total_questions,
  reported_share_pct as share_pct
from php.so_questions_quarterly
where source = 'Stack Exchange Data Explorer' and partial_period = 'no'
order by quarter_start
```

```sql peak
select cast(year as varchar) || ' Q' || cast(quarter as varchar) as quarter_label, share_pct
from ${explorer_quarters}
order by share_pct desc
limit 1
```

```sql latest
select cast(year as varchar) || ' Q' || cast(quarter as varchar) as quarter_label, share_pct, php_questions, total_questions
from ${explorer_quarters}
order by quarter_start desc
limit 1
```

```sql explorer_years
select
  year,
  php_questions,
  total_questions,
  round(100.0 * php_questions / total_questions, 2) as share_pct,
  round(100.0 * (php_questions * 1.0 / lag(php_questions) over (order by year) - 1), 1) as php_change_pct,
  round(100.0 * (total_questions * 1.0 / lag(total_questions) over (order by year) - 1), 1) as total_change_pct,
  case when partial_period = 'yes' then 'partial year' else '' end as note
from php.so_questions_yearly
where source = 'Stack Exchange Data Explorer'
order by year
```

```sql source_gap
select
  s.quarter_start,
  round(100.0 * (b.total_questions * 1.0 / s.total_questions - 1), 1) as total_questions_gap_pct,
  round(100.0 * (b.php_questions * 1.0 / s.php_questions - 1), 1) as php_questions_gap_pct
from php.so_questions_quarterly s
join php.so_questions_quarterly b
  on b.quarter_start = s.quarter_start and b.source = 'BigQuery snapshot'
where s.source = 'Stack Exchange Data Explorer'
  and s.partial_period = 'no' and b.partial_period = 'no'
order by s.quarter_start
```

## PHP's share over time

<BigValue data={peak} value=share_pct title="Highest quarterly share (%)" />
<BigValue data={latest} value=share_pct title="Latest complete quarter (%)" />

PHP's share of questions peaked in <Value data={peak} column=quarter_label /> and is <Value data={latest} column=share_pct />% in the latest complete quarter, <Value data={latest} column=quarter_label />.

<LineChart
  data={explorer_quarters}
  x=quarter_start
  y=share_pct
  yFmt=num1
  yAxisTitle="% of all questions"
  title="Questions tagged php, as a share of all Stack Overflow questions"
/>

A "PHP question" is one tagged exactly `php`. Questions about a specific framework that omit the `php` tag are not counted.

## Both numbers are falling

The share fell because PHP questions fell, but all questions fell too, and faster at the end of the period. A falling share is not evidence that fewer people use PHP.

<LineChart
  data={explorer_quarters}
  x=quarter_start
  y=total_questions
  yFmt=num0
  title="All questions per quarter"
/>

<LineChart
  data={explorer_quarters}
  x=quarter_start
  y=php_questions
  yFmt=num0
  title="PHP questions per quarter"
/>

<DataTable data={explorer_years} rows=20>
  <Column id=year title="Year" fmt=id />
  <Column id=php_questions title="PHP questions" fmt=num0 />
  <Column id=php_change_pct title="Change (%)" fmt=num1 />
  <Column id=total_questions title="All questions" fmt=num0 />
  <Column id=total_change_pct title="Change (%)" fmt=num1 />
  <Column id=share_pct title="PHP share (%)" fmt=num2 />
  <Column id=note title="" />
</DataTable>

Several explanations for the recent fall in all questions are plausible, including that developers now get answers elsewhere, but nothing in this data measures why. The first and last
years are partial: the site opened in August 2008, and the latest year is still in progress.

## Do the two sources agree?

The report collects the numbers twice: from the live Data Explorer, and from a BigQuery dump of the site's data loaded in November 2022. For the quarters both cover, the dump should
count slightly more questions, because it still contains questions that were deleted later. The chart shows by how much.

<LineChart
  data={source_gap}
  x=quarter_start
  y={['total_questions_gap_pct','php_questions_gap_pct']}
  yAxisTitle="% more questions in the BigQuery dump"
  title="BigQuery dump compared with the Data Explorer, by quarter"
/>

Through the third quarter of 2021 the dump runs about 1 to 3% above the Data Explorer, as expected. From the fourth quarter of 2021 the gap widens to roughly 17 to 26%.
That is more than deletion over the following months would normally explain, and the report does not account for it, so treat the Data Explorer series as the reference
and the dump as unexplained for those quarters. This page's charts use the Data Explorer series only.

## Read with care

- **Questions, not developers.** The numbers measure how people use one help site.
- **Tag-based.** Only questions tagged exactly `php` are counted.
- **Recent quarters are less settled.** Questions can still be deleted, and the latest quarter is partial and excluded from the charts above.
- **The share is a ratio of two falling numbers**, so small absolute changes in recent quarters move it noticeably.
