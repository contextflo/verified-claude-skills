-- dataset: firebase-public-project.analytics_153293282
-- Answers: active users by country, platform, device category and device language.
-- In this demo dataset device.mobile_brand_name, mobile_model_name and
-- operating_system_version all read 'not available in demo dataset'. On a real export,
-- add them to the GROUP BY for device and OS breakdowns.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 20 rows.
--   country        platform  device_category  language  users
--   United States  ANDROID   mobile           en-us     1225
--   United States  IOS       tablet           en-us     800
--   United States  IOS       mobile           en-us     222

SELECT
  geo.country,
  platform,
  device.category AS device_category,
  device.language,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
GROUP BY geo.country, platform, device_category, device.language
ORDER BY users DESC
LIMIT 20
