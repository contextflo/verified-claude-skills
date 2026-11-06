-- dataset: firebase-public-project.analytics_153293282
-- Answers: daily active users and events per day, split by platform (iOS / Android).
-- One Firebase project can export several apps into one dataset. Always split or filter
-- by platform and app_info.id, or you mix apps together.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 62 rows.
--   day         platform  dau  events
--   2018-08-01  ANDROID   292  33520
--   2018-08-01  IOS       155  16480
--   2018-08-02  ANDROID   311  33503
-- Note: this dataset is capped at exactly 50,000 events per day, so daily totals are not
-- real volume.

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS day,
  platform,
  COUNT(DISTINCT user_pseudo_id) AS dau,
  COUNT(*) AS events
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
GROUP BY day, platform
ORDER BY day, platform
