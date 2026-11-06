-- dataset: firebase-public-project.analytics_153293282
-- Answers: classic day-N retention (D1, D7, D30) for users by first_open week and platform.
-- Day N = the user had any event exactly N days after their first_open day.
-- Cohorts are defined by first_open, never by "first event in the export": most users in a
-- dataset installed before the export window and would be miscounted as new.
-- Cohorts too young to have a day 30 show NULL instead of 0.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 34 rows.
--   cohort_week  platform  cohort_users  d1_retention  d7_retention  d30_retention
--   2018-06-11   ANDROID   77            0.312         0.052         0.0
--   2018-06-18   ANDROID   129           0.302         0.062         0.031
--   2018-06-25   ANDROID   46            0.283         0.087         0.043
-- (The 2018-06-11 week starts on 2018-06-12, the first day of data.)

WITH cohort AS (
  SELECT user_pseudo_id, platform, MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id, platform
),
active AS (
  SELECT DISTINCT user_pseudo_id, PARSE_DATE('%Y%m%d', event_date) AS day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
),
per_user AS (
  SELECT
    c.user_pseudo_id,
    c.platform,
    DATE_TRUNC(c.first_day, WEEK(MONDAY)) AS cohort_week,
    MAX(c.first_day) AS first_day,
    LOGICAL_OR(DATE_DIFF(a.day, c.first_day, DAY) = 1) AS d1,
    LOGICAL_OR(DATE_DIFF(a.day, c.first_day, DAY) = 7) AS d7,
    LOGICAL_OR(DATE_DIFF(a.day, c.first_day, DAY) = 30) AS d30
  FROM cohort AS c
  LEFT JOIN active AS a USING (user_pseudo_id)
  GROUP BY c.user_pseudo_id, c.platform, cohort_week
)
SELECT
  cohort_week,
  platform,
  COUNT(*) AS cohort_users,
  ROUND(COUNTIF(d1) / COUNT(*), 3) AS d1_retention,
  IF(MAX(first_day) > DATE '2018-09-26', NULL, ROUND(COUNTIF(d7) / COUNT(*), 3)) AS d7_retention,
  IF(MAX(first_day) > DATE '2018-09-03', NULL, ROUND(COUNTIF(d30) / COUNT(*), 3)) AS d30_retention
FROM per_user
GROUP BY cohort_week, platform
ORDER BY cohort_week, platform
