-- dataset: firebase-public-project.analytics_153293282
-- Answers: sessions, sessions per user and engagement time per user, by platform.
-- This 2018 export has no ga_session_id param (it was added to app exports in Dec 2018),
-- so sessions are counted from session_start events. On a current export, count
-- user_pseudo_id + ga_session_id instead, the same as the ga4 pack.
-- Engagement time is the sum of engagement_time_msec, which apps send mostly on
-- user_engagement events.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 2 rows.
--   platform  users  sessions  sessions_per_user  engagement_min_per_user
--   ANDROID   2982   11191     3.75               29.3
--   IOS       1685   8386      4.98               46.6

SELECT
  platform,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNTIF(event_name = 'session_start') AS sessions,
  ROUND(COUNTIF(event_name = 'session_start') / COUNT(DISTINCT user_pseudo_id), 2) AS sessions_per_user,
  ROUND(SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec'))
        / COUNT(DISTINCT user_pseudo_id) / 60000, 1) AS engagement_min_per_user
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
GROUP BY platform
ORDER BY users DESC
