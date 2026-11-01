-- Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
-- Source: subgroup-research/raw-data/extractions/stackoverflow-bigquery.md, code block #0.
-- What it is: BigQuery: PHP share of Stack Overflow questions by quarter.
-- Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
WITH totals AS (
  -- Denominator: all questions. Normalising matters, site-wide volume
  -- shifted a lot over the years, so absolute counts mislead.
  SELECT DATE_TRUNC(DATE(creation_date), QUARTER) AS quarter,
         COUNT(*) AS total_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  GROUP BY quarter  -- DATE() needed: creation_date is a TIMESTAMP
),

php AS (
  -- Numerator: questions tagged 'php'.
  SELECT DATE_TRUNC(DATE(q.creation_date), QUARTER) AS quarter,
         COUNT(*) AS php_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q,
       -- tags is a '|'-joined string, not an ARRAY
       UNNEST(SPLIT(q.tags, '|')) AS tag
  WHERE tag = 'php'  -- exact match: LIKE '%php%' would catch 'phpunit'
  GROUP BY quarter
)

SELECT
  t.quarter,
  p.php_questions,
  t.total_questions,
  ROUND(100 * p.php_questions / t.total_questions, 2) AS share_pct
FROM totals AS t
JOIN php AS p USING (quarter)  -- INNER: fine for a common tag, not a rare one
WHERE t.quarter >= DATE '2012-01-01'  -- early years are noisy
ORDER BY t.quarter;
