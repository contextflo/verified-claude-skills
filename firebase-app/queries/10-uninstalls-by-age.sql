-- dataset: firebase-public-project.analytics_153293282
-- Answers: how soon after first open users uninstall (app_remove), by platform.
-- app_remove is Android only. iOS does not report uninstalls, so an iOS churn number from
-- app_remove is always zero, not good news.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 4 rows
-- (all ANDROID, as expected).
--   platform  age_at_uninstall  users
--   ANDROID   a: same day       858
--   ANDROID   b: 1-7 days       389
--   ANDROID   c: 8-30 days      208
--   ANDROID   d: 31+ days       77

WITH first_open AS (
  SELECT user_pseudo_id, MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),
removes AS (
  SELECT user_pseudo_id, platform, MIN(PARSE_DATE('%Y%m%d', event_date)) AS remove_day
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id, platform
)
SELECT
  r.platform,
  CASE
    WHEN DATE_DIFF(r.remove_day, f.first_day, DAY) = 0 THEN 'a: same day'
    WHEN DATE_DIFF(r.remove_day, f.first_day, DAY) <= 7 THEN 'b: 1-7 days'
    WHEN DATE_DIFF(r.remove_day, f.first_day, DAY) <= 30 THEN 'c: 8-30 days'
    ELSE 'd: 31+ days'
  END AS age_at_uninstall,
  COUNT(*) AS users
FROM removes AS r
JOIN first_open AS f USING (user_pseudo_id)
WHERE r.remove_day >= f.first_day
GROUP BY r.platform, age_at_uninstall
ORDER BY r.platform, age_at_uninstall
