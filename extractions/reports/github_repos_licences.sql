-- Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
-- Source: subgroup-research/raw-data/extractions/github-repos-licences.md, code block #0.
-- What it is: BigQuery: licences of PHP repositories.
-- Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
WITH languages AS (
  SELECT
    repo_name,
    -- Linguist's own choice: the language holding the most bytes.
    (SELECT name FROM UNNEST(language) ORDER BY bytes DESC LIMIT 1) AS top_language,
    EXISTS(SELECT 1 FROM UNNEST(language) WHERE name = 'PHP')       AS contains_php
  FROM `bigquery-public-data.github_repos.languages`
)

SELECT
  l.license,
  COUNTIF(g.top_language = 'PHP') AS php_is_the_main_language,
  COUNTIF(g.contains_php)         AS contains_any_php,
  ROUND(100 * COUNTIF(g.top_language = 'PHP')
        / SUM(COUNTIF(g.top_language = 'PHP')) OVER (), 2) AS pct_of_main
FROM `bigquery-public-data.github_repos.licenses` AS l
JOIN languages AS g USING (repo_name)
WHERE g.contains_php
GROUP BY l.license
ORDER BY php_is_the_main_language DESC;
