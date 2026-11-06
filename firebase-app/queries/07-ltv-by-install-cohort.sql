-- dataset: firebase-public-project.analytics_153293282
-- Answers: lifetime value per user by first_open month and platform.
-- user_ltv.revenue is cumulative per user and is repeated on every event of that user,
-- so take the MAX per user, never SUM it across events.
-- The sample has very little revenue (146 paying users), so treat the numbers as shape only.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 10 rows.
--   cohort_month  platform  users  paying_users  total_ltv  ltv_per_user  currency
--   2018-06-01    ANDROID   252    1             0.99       0.0039        USD
--   2018-07-01    ANDROID   813    2             3.04       0.0037        USD
--   2018-07-01    IOS       266    2             1.97       0.0074        USD

WITH cohort AS (
  SELECT user_pseudo_id, platform, DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), MONTH) AS cohort_month
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id, platform
),
ltv AS (
  SELECT user_pseudo_id, MAX(user_ltv.revenue) AS ltv_revenue, ANY_VALUE(user_ltv.currency) AS currency
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180612' AND '20181003'
  GROUP BY user_pseudo_id
)
SELECT
  c.cohort_month,
  c.platform,
  COUNT(*) AS users,
  COUNTIF(l.ltv_revenue > 0) AS paying_users,
  ROUND(SUM(IFNULL(l.ltv_revenue, 0)), 2) AS total_ltv,
  ROUND(AVG(IFNULL(l.ltv_revenue, 0)), 4) AS ltv_per_user,
  ANY_VALUE(l.currency) AS currency
FROM cohort AS c
LEFT JOIN ltv AS l USING (user_pseudo_id)
GROUP BY c.cohort_month, c.platform
ORDER BY c.cohort_month, c.platform
