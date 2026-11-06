-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: top pages by views and users.
-- page_location is the full URL including query string, so strip it or one page splits
-- into many rows.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 20 rows.
--   page                                                        views  users
--   https://shop.googlemerchandisestore.com/                    53807  32395
--   https://shop.googlemerchandisestore.com/basket.html         30841  8599
--   https://shop.googlemerchandisestore.com/Google+Redesign/Apparel  28575  21336

SELECT
  REGEXP_REPLACE(
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
    r'[?#].*$', '') AS page,
  COUNT(*) AS views,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  AND event_name = 'page_view'
GROUP BY page
ORDER BY views DESC
LIMIT 20
