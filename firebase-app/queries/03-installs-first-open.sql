-- dataset: firebase-public-project.analytics_153293282
-- Answers: new installs (first_open) per week by platform and acquisition source.
-- first_open fires the first time the app is opened after install or reinstall, so it is
-- "first opens", not store installs. traffic_source is the user's first-touch acquisition.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 87 rows.
--   week        platform  source       medium   new_users
--   2018-06-11  IOS       (direct)     (none)   99
--   2018-06-11  ANDROID   google-play  organic  48
--   2018-06-11  ANDROID   (direct)     (none)   28

SELECT
  DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS week,
  platform,
  IFNULL(traffic_source.source, '(unknown)') AS source,
  IFNULL(traffic_source.medium, '(unknown)') AS medium,
  COUNT(DISTINCT user_pseudo_id) AS new_users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180611' AND '20181003'
  AND event_name = 'first_open'
GROUP BY week, platform, source, medium
ORDER BY week, new_users DESC
