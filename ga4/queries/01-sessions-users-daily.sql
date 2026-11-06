-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: sessions, users and events per day.
-- A session is user_pseudo_id + ga_session_id. ga_session_id alone is not unique.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 31 rows.
--   day         sessions  users  events
--   2020-12-01  5000      4308   71804
--   2020-12-02  4814      4101   66832
--   2020-12-03  5200      4464   71689

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-',
    CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING))) AS sessions,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(*) AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
GROUP BY day
ORDER BY day
