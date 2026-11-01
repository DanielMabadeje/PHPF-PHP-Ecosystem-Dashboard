-- Vendored verbatim from ThePHPF/SIG-ambassadors, PR #40 (commit unrecorded).
-- Source: subgroup-research/raw-data/extractions/github-repos.md, code block #0.
-- What it is: BigQuery: Composer adoption across public PHP repositories.
-- Written by the study's author (credit: GianfriAur). Not modified or run by this project's pipeline; see extractions/reports/README.md.
WITH
-- All repos GitHub Linguist tags as containing PHP.
php_repos AS (
  SELECT DISTINCT repo_name
  FROM `bigquery-public-data.github_repos.languages`, UNNEST(language) AS lang
  WHERE lang.name = 'PHP'
),

-- Single scan of the files table: keep only Composer-related paths.
-- vendor/autoload.php is the reliable marker of a committed vendor directory.
composer_files AS (
  SELECT
    repo_name,
    path,
    (path = 'composer.json' OR ENDS_WITH(path, '/composer.json')) AS is_manifest,
    (STARTS_WITH(path, 'vendor/') OR CONTAINS_SUBSTR(path, '/vendor/')) AS is_in_vendor
  FROM `bigquery-public-data.github_repos.files`
  WHERE path = 'composer.json'
     OR ENDS_WITH(path, '/composer.json')
     OR ENDS_WITH(path, 'vendor/autoload.php')
),

-- Collapse to one row per repo with the three signals we care about.
repo_signals AS (
  SELECT
    repo_name,
    LOGICAL_OR(path = 'composer.json')             AS has_root_manifest,
    LOGICAL_OR(is_manifest AND NOT is_in_vendor)   AS has_own_manifest,
    LOGICAL_OR(is_in_vendor)                       AS has_vendor_committed
  FROM composer_files
  GROUP BY repo_name
),

-- Left join so repos with no Composer footprint at all survive as NULLs,
-- then normalise those NULLs to FALSE so every repo lands on one side.
classified AS (
  SELECT
    p.repo_name,
    IFNULL(s.has_root_manifest,    FALSE) AS has_root_manifest,
    IFNULL(s.has_own_manifest,     FALSE) AS has_own_manifest,
    IFNULL(s.has_vendor_committed, FALSE) AS has_vendor_committed
  FROM php_repos AS p
  LEFT JOIN repo_signals AS s ON s.repo_name = p.repo_name
)

SELECT
  COUNT(*) AS total_php_repos,

  -- Bottom line: does the project ship a manifest of its own?
  COUNTIF(has_own_manifest)       AS uses_composer,
  COUNTIF(NOT has_own_manifest)   AS no_composer,

  -- Manifest present but not at the repo root: likely a layout problem,
  -- or a legitimate monorepo. Cannot be told apart from paths alone.
  COUNTIF(has_own_manifest AND NOT has_root_manifest) AS manifest_not_at_root,

  -- The classic mistake: vendor/ committed to version control.
  COUNTIF(has_vendor_committed)                          AS vendor_committed,
  COUNTIF(has_vendor_committed AND NOT has_own_manifest) AS vendor_committed_without_manifest,

  ROUND(100 * COUNTIF(has_own_manifest) / COUNT(*), 2)                          AS pct_uses_composer,
  ROUND(100 * COUNTIF(has_vendor_committed) / NULLIF(COUNTIF(has_own_manifest), 0), 2)
                                                                                AS pct_vendor_among_users
FROM classified
