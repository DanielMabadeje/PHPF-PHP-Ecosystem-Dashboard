-- Query 2: platform breakdown per crawl. Parameter: @crawl_date (DATE). Needs _preamble.sql.
SELECT
  @crawl_date AS crawl_date,
  t.technology AS platform,
  t.technology IN UNNEST(params.php_apps) AS is_php,
  COUNT(DISTINCT p.root_page) AS sites
FROM `httparchive.crawl.pages` AS p, UNNEST(p.technologies) AS t, UNNEST(t.categories) AS cat, params
WHERE p.date = @crawl_date
  AND p.client = 'mobile'
  AND p.is_root_page
  AND cat IN ('CMS', 'Ecommerce')
  AND t.technology NOT IN UNNEST(params.not_a_platform)
GROUP BY platform, is_php
ORDER BY sites DESC
LIMIT 100