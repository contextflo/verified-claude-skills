-- dataset: firebase-public-project.analytics_153293282
-- Answers: share of weekly active users on each app version, per platform.
-- app_info.version is the version that sent each event, so a user who upgrades mid-week
-- counts under both versions that week.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 12 rows.
--   week        platform  app_version  users  share_of_platform_week
--   2018-09-03  ANDROID   2.62         806    0.934
--   2018-09-03  IOS       2.6.31       1001   0.752
--   2018-09-03  IOS       2.6.27       197    0.148

WITH weekly AS (
  SELECT
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS week,
    platform,
    app_info.version AS app_version,
    COUNT(DISTINCT user_pseudo_id) AS users
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180903' AND '20180930'
  GROUP BY week, platform, app_version
)
SELECT
  week,
  platform,
  app_version,
  users,
  ROUND(users / SUM(users) OVER (PARTITION BY week, platform), 3) AS share_of_platform_week
FROM weekly
QUALIFY share_of_platform_week >= 0.05
ORDER BY week, platform, users DESC
