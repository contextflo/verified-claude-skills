-- dataset: firebase-public-project.analytics_153293282
-- Answers: crash-affected users by app version (from app_exception events with fatal = 1).
-- app_exception is only logged when Crashlytics/analytics crash reporting is wired up;
-- if your export has none, use Crashlytics' own BigQuery export instead.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 8 rows.
--   platform  app_version  users  crashed_users  fatal_exceptions  crashed_user_rate
--   IOS       2.6.10       180    23             268               0.1278
--   ANDROID   2.57         148    12             49                0.0811
--   ANDROID   2.62         6591   491            2784              0.0745

WITH version_users AS (
  SELECT platform, app_info.version AS app_version, COUNT(DISTINCT user_pseudo_id) AS users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
  GROUP BY platform, app_version
),
crashes AS (
  SELECT
    platform,
    app_info.version AS app_version,
    COUNT(*) AS fatal_exceptions,
    COUNT(DISTINCT user_pseudo_id) AS crashed_users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND event_name = 'app_exception'
    AND (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'fatal') = 1
  GROUP BY platform, app_version
)
SELECT
  c.platform,
  c.app_version,
  v.users,
  c.crashed_users,
  c.fatal_exceptions,
  ROUND(c.crashed_users / v.users, 4) AS crashed_user_rate
FROM crashes AS c
JOIN version_users AS v USING (platform, app_version)
WHERE v.users >= 100
ORDER BY crashed_user_rate DESC
