-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: users by FIRST-TOUCH source / medium / campaign (how each user was first acquired).
-- traffic_source.* is the user's first acquisition and never changes for that user.
-- It is not the source of the current session. For that use 07-traffic-session-source.sql.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 13 rows.
--   first_source  first_medium  first_campaign  users
--   google        organic       (organic)       39172
--   (direct)      (none)        (direct)        28526
--   <Other>       <Other>       <Other>         19119
--   <Other>       referral      (referral)      12322

SELECT
  traffic_source.source AS first_source,
  traffic_source.medium AS first_medium,
  traffic_source.name AS first_campaign,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY first_source, first_medium, first_campaign
ORDER BY users DESC
LIMIT 20
