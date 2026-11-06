-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: engaged sessions, engagement rate and average engagement time per session, by week.
-- session_engaged arrives as string '1' on most events and as int 1 on others,
-- so read both columns. On December 2020, string_value alone finds 72,239 engaged sessions;
-- reading both finds 117,633 (the five weekly rows below sum to that).
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 5 rows.
--   week        sessions  engaged_sessions  engagement_rate  avg_engagement_sec
--   2020-11-30  26522     22837             0.861            88.9
--   2020-12-07  38729     33843             0.874            80.4
--   2020-12-14  33411     29439             0.881            75.0

WITH sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS day,
    MAX((SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
         FROM UNNEST(event_params) WHERE key = 'session_engaged')) = '1' AS engaged,
    SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS engagement_msec
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  GROUP BY user_pseudo_id, session_id
)
SELECT
  DATE_TRUNC(day, WEEK(MONDAY)) AS week,
  COUNT(*) AS sessions,
  COUNTIF(engaged) AS engaged_sessions,
  ROUND(COUNTIF(engaged) / COUNT(*), 3) AS engagement_rate,
  ROUND(AVG(IFNULL(engagement_msec, 0)) / 1000, 1) AS avg_engagement_sec
FROM sessions
GROUP BY week
ORDER BY week
