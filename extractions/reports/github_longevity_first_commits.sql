-- Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
-- Source: subgroup-research/raw-data/extractions/github-php-longevity.md, code block #1.
-- What it is: BigQuery: earliest credible commit per repository (input to score.php).
-- Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
-- Earliest credible commit per repository.
-- Author dates in github_repos.commits are self-reported and contain junk:
-- the Unix epoch, dates in the future, and dates before git existed.
SELECT
  repo_name,
  MIN(author_date) AS first_commit,
  MAX(author_date) AS last_commit,
  COUNT(*)         AS commits
FROM (
  SELECT
    repo_name,
    TIMESTAMP_SECONDS(author.time_sec) AS author_date
  FROM `bigquery-public-data.github_repos.commits`, UNNEST(repo_name) AS repo_name
)
WHERE author_date BETWEEN TIMESTAMP '1995-01-01' AND CURRENT_TIMESTAMP()
GROUP BY repo_name
HAVING COUNT(*) >= 10   -- a repo with a handful of commits tells us nothing
ORDER BY first_commit;
