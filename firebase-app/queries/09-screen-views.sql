-- dataset: firebase-public-project.analytics_153293282
-- Answers: top screens by views and users.
-- Apps log screen_view with firebase_screen_class (the view controller / activity) and,
-- when set by the app, firebase_screen (a readable name). Current exports may use
-- screen_class / screen_name instead.
-- firebase_screen_id switches between int and double, so do not group by it.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 20 rows.
--   platform  screen_class          views   users
--   ANDROID   game_board            108396  2228
--   IOS       FIRootViewController  81700   1627
--   ANDROID   game_over             64507   1906

SELECT
  platform,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'firebase_screen_class') AS screen_class,
  COUNT(*) AS views,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
  AND event_name = 'screen_view'
GROUP BY platform, screen_class
ORDER BY views DESC
LIMIT 20
