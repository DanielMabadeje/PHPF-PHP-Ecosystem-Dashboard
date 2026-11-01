-- Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
-- Source: subgroup-research/raw-data/extractions/stackoverflow-sede.md, code block #0.
-- What it is: T-SQL for data.stackexchange.com (run by hand in the browser).
-- Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
WITH Totals AS (
  SELECT
    DATEADD(QUARTER, DATEDIFF(QUARTER, 0, CreationDate), 0) AS Quarter,
    COUNT(*) AS Total
  FROM Posts
  WHERE PostTypeId = 1
  GROUP BY DATEADD(QUARTER, DATEDIFF(QUARTER, 0, CreationDate), 0)
),

Php AS (
  SELECT
    DATEADD(QUARTER, DATEDIFF(QUARTER, 0, p.CreationDate), 0) AS Quarter,
    COUNT(*) AS PhpQuestions
  FROM Posts p
  INNER JOIN PostTags pt ON pt.PostId = p.Id
  INNER JOIN Tags t      ON t.Id = pt.TagId
  WHERE p.PostTypeId = 1
    AND t.TagName = ##TagName:string?php##
  GROUP BY DATEADD(QUARTER, DATEDIFF(QUARTER, 0, p.CreationDate), 0)
)

SELECT
  CONVERT(date, t.Quarter) AS [Quarter],
  p.PhpQuestions,
  t.Total,
  ROUND(100.0 * p.PhpQuestions / t.Total, 2) AS SharePct
FROM Totals t
INNER JOIN Php p ON p.Quarter = t.Quarter
WHERE t.Quarter >= '2000-01-01'
ORDER BY t.Quarter;

