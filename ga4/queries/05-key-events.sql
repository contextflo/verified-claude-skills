-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: event counts and users per event name (to see which events exist and pick conversions).
-- The export has no "is conversion / key event" flag. Which events count as key events is a
-- property setting in the GA4 UI, so list them explicitly in your queries.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 17 rows.
--   event_name       events  users
--   page_view        477520  104062
--   user_engagement  401428  81819
--   scroll           183220  49273
--   view_item        150458  22906

SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY event_name
ORDER BY events DESC
