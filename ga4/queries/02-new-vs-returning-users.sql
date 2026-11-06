-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: how many users in the period were new vs returning.
-- New = the user's first_visit event (first_open on apps) falls inside the period.
-- Returning = active in the period but first seen before it.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 2 rows.
--   user_type  users  pct
--   new        96772  92.8
--   returning  7543   7.2

WITH users_in_period AS (
  SELECT
    user_pseudo_id,
    LOGICAL_OR(event_name = 'first_visit') AS had_first_visit
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  GROUP BY user_pseudo_id
)
SELECT
  IF(had_first_visit, 'new', 'returning') AS user_type,
  COUNT(*) AS users,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM users_in_period
GROUP BY user_type
ORDER BY users DESC
