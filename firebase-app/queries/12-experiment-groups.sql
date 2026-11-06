-- dataset: firebase-public-project.analytics_153293282
-- Answers: users and engagement per A/B Testing / Remote Config experiment variant.
-- Firebase A/B Testing stores the variant as a user property firebase_exp_<N>, with the
-- variant index as a STRING. user_properties is a repeated record like event_params and is
-- the value as of that event, so read it per event and take one value per user.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 14 rows.
--   experiment      variant  users  avg_engaged_min
--   firebase_exp_1  0        490    31.7
--   firebase_exp_1  1        459    17.4
--   firebase_exp_1  2        451    21.1
-- Users can be in several experiments, so do not add rows across experiments.

WITH user_variant AS (
  SELECT
    user_pseudo_id,
    up.key AS experiment,
    ARRAY_AGG(up.value.string_value ORDER BY event_timestamp DESC LIMIT 1)[OFFSET(0)] AS variant
  FROM `firebase-public-project.analytics_153293282.events_*`,
    UNNEST(user_properties) AS up
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND up.key LIKE 'firebase_exp_%'
  GROUP BY user_pseudo_id, experiment
),
engagement AS (
  SELECT
    user_pseudo_id,
    SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) / 60000 AS engaged_min
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
  GROUP BY user_pseudo_id
)
SELECT
  experiment,
  variant,
  COUNT(*) AS users,
  ROUND(AVG(e.engaged_min), 1) AS avg_engaged_min
FROM user_variant AS v
JOIN engagement AS e USING (user_pseudo_id)
GROUP BY experiment, variant
ORDER BY experiment, variant
