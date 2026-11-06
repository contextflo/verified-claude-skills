-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: sessions and users by device category and country.
-- device.* and geo.* are on every event. Within one session they almost never change,
-- so take them from any event of the session.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 20 rows.
--   device_category  country        sessions  users
--   desktop          United States  33865     26717
--   mobile           United States  23211     18329
--   desktop          India          7113      5655

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    ANY_VALUE(device.category) AS device_category,
    ANY_VALUE(geo.country) AS country
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  GROUP BY user_pseudo_id, session_id
)
SELECT
  device_category,
  country,
  COUNT(*) AS sessions,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM sessions
GROUP BY device_category, country
ORDER BY sessions DESC
LIMIT 20
