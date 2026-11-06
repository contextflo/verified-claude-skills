-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: weekly retention by first-visit cohort (share of each cohort active N weeks later).
-- The cohort is the week of the user's first_visit event, not their first event in the
-- export: users first seen before the export started have no first_visit in range and are
-- excluded instead of being mislabelled as new.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 13 rows.
--   cohort_week  cohort_users  w1      w2      w4      w8
--   2020-11-02   16500         0.0425  0.0194  0.0116  0.0016
--   2020-11-09   14590         0.0568  0.0235  0.0175  0.0036
--   2020-11-16   16906         0.0525  0.0277  0.0147  0.0031

WITH first_visit AS (
  SELECT user_pseudo_id, DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'first_visit'
  GROUP BY user_pseudo_id
),
activity AS (
  SELECT DISTINCT user_pseudo_id, DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS active_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
joined AS (
  SELECT f.cohort_week, DATE_DIFF(a.active_week, f.cohort_week, WEEK) AS week_n, a.user_pseudo_id
  FROM first_visit AS f
  JOIN activity AS a USING (user_pseudo_id)
  WHERE a.active_week >= f.cohort_week
    -- 2020-10-26 is a partial week (data starts Sunday 2020-11-01), so skip it
    AND f.cohort_week >= '2020-11-02'
),
-- a retention week that ends after the last day of data is unknown, not zero
last_full_week AS (SELECT DATE '2021-01-25' AS wk)
SELECT
  cohort_week,
  COUNT(DISTINCT IF(week_n = 0, user_pseudo_id, NULL)) AS cohort_users,
  IF(DATE_ADD(cohort_week, INTERVAL 1 WEEK) > (SELECT wk FROM last_full_week), NULL,
    ROUND(COUNT(DISTINCT IF(week_n = 1, user_pseudo_id, NULL)) / COUNT(DISTINCT IF(week_n = 0, user_pseudo_id, NULL)), 4)) AS w1,
  IF(DATE_ADD(cohort_week, INTERVAL 2 WEEK) > (SELECT wk FROM last_full_week), NULL,
    ROUND(COUNT(DISTINCT IF(week_n = 2, user_pseudo_id, NULL)) / COUNT(DISTINCT IF(week_n = 0, user_pseudo_id, NULL)), 4)) AS w2,
  IF(DATE_ADD(cohort_week, INTERVAL 4 WEEK) > (SELECT wk FROM last_full_week), NULL,
    ROUND(COUNT(DISTINCT IF(week_n = 4, user_pseudo_id, NULL)) / COUNT(DISTINCT IF(week_n = 0, user_pseudo_id, NULL)), 4)) AS w4,
  IF(DATE_ADD(cohort_week, INTERVAL 8 WEEK) > (SELECT wk FROM last_full_week), NULL,
    ROUND(COUNT(DISTINCT IF(week_n = 8, user_pseudo_id, NULL)) / COUNT(DISTINCT IF(week_n = 0, user_pseudo_id, NULL)), 4)) AS w8
FROM joined
GROUP BY cohort_week
ORDER BY cohort_week
