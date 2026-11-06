-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: daily active users with trailing 7-day and 28-day active users, and stickiness.
-- Rolling counts need distinct users over a window, which you cannot get by summing DAU.
-- The window reads 27 extra days before the reporting range.
-- "Active user" in GA4 reports is a user with an engaged session or engagement time; here
-- it is any user with an event. Newer exports have an is_active_user column for this.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 31 rows.
--   day         dau   wau_7d  mau_28d  dau_over_mau
--   2020-12-01  4308  23132   74363    0.058
--   2020-12-02  4101  23233   74639    0.055
--   2020-12-03  4464  23978   75715    0.059

WITH daily AS (
  SELECT DISTINCT PARSE_DATE('%Y%m%d', event_date) AS day, user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201104' AND '20201231'
),
days AS (
  SELECT day FROM UNNEST(GENERATE_DATE_ARRAY('2020-12-01', '2020-12-31')) AS day
)
SELECT
  d.day,
  COUNT(DISTINCT IF(u.day = d.day, u.user_pseudo_id, NULL)) AS dau,
  COUNT(DISTINCT IF(u.day > DATE_SUB(d.day, INTERVAL 7 DAY), u.user_pseudo_id, NULL)) AS wau_7d,
  COUNT(DISTINCT u.user_pseudo_id) AS mau_28d,
  ROUND(COUNT(DISTINCT IF(u.day = d.day, u.user_pseudo_id, NULL)) / COUNT(DISTINCT u.user_pseudo_id), 3) AS dau_over_mau
FROM days AS d
JOIN daily AS u
  ON u.day BETWEEN DATE_SUB(d.day, INTERVAL 27 DAY) AND d.day
GROUP BY d.day
ORDER BY d.day
