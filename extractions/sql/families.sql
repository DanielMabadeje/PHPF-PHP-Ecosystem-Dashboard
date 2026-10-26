-- Query 3: core vs derivatives per crawl. Parameter: @crawl_date (DATE). Self-contained (no preamble).
-- To add a family, add one STRUCT line below; the watched list is derived from it.
WITH families AS (
  SELECT * FROM UNNEST([
    STRUCT('WordPress'   AS parent, ['WooCommerce', 'EasyDigitalDownloads'] AS children),
    STRUCT('Weebly',      ['Square Online']),
    STRUCT('Webflow',     ['Webflow Ecommerce']),
    STRUCT('Magento',     ['Hyva Themes']),
    STRUCT('Wix',         ['Wix eCommerce']),
    STRUCT('Squarespace', ['Squarespace Commerce'])
  ])
),
watched AS (
  SELECT ARRAY_AGG(DISTINCT name) AS names
  FROM families, UNNEST(ARRAY_CONCAT([parent], children)) AS name
),
sites AS (
  SELECT root_page, ARRAY_AGG(DISTINCT t.technology) AS techs
  FROM `httparchive.crawl.pages`, UNNEST(technologies) AS t, watched
  WHERE date = @crawl_date
    AND client = 'mobile'
    AND is_root_page
    AND t.technology IN UNNEST(watched.names)
  GROUP BY root_page
)
SELECT
  @crawl_date AS crawl_date,
  f.parent AS family,
  COUNTIF(f.parent IN UNNEST(s.techs)) AS parent_sites,
  COUNTIF(f.parent IN UNNEST(s.techs)
          AND EXISTS(SELECT 1 FROM UNNEST(f.children) AS c WHERE c IN UNNEST(s.techs))) AS with_derivative,
  COUNTIF(f.parent IN UNNEST(s.techs)
          AND NOT EXISTS(SELECT 1 FROM UNNEST(f.children) AS c WHERE c IN UNNEST(s.techs))) AS core_only,
  COUNTIF(f.parent NOT IN UNNEST(s.techs)
          AND EXISTS(SELECT 1 FROM UNNEST(f.children) AS c WHERE c IN UNNEST(s.techs))) AS derivative_without_parent,
  ROUND(100 * COUNTIF(f.parent IN UNNEST(s.techs)
                      AND EXISTS(SELECT 1 FROM UNNEST(f.children) AS c WHERE c IN UNNEST(s.techs)))
        / NULLIF(COUNTIF(f.parent IN UNNEST(s.techs)), 0), 2) AS pct_with_derivative
FROM sites AS s CROSS JOIN families AS f
GROUP BY f.parent
ORDER BY parent_sites DESC