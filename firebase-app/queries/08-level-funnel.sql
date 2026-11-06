-- dataset: firebase-public-project.analytics_153293282
-- Answers: per-level starts, completions and fail rates in the game's progressive mode.
-- Custom params switch type: `level` is double on most events and int on others, and the
-- int-typed events carry no level_name. Grouping by level_name, or reading only
-- double_value, drops 986 of August's 20,350 level_start events. Coalesce instead.
-- Verified: ran on firebase-public-project.analytics_153293282 on 2026-11-05, returned 31 rows.
--   level  starts  completes  fails  completion_rate  players
--   1      1721    1019       2      0.592            959
--   2      1705    873        67     0.512            887
--   3      1099    753        72     0.685            739
-- (A level 0 row with 39 fail events and no starts also appears. It is in the data as
-- logged; filter it out if it means nothing in your game.)

WITH level_events AS (
  SELECT
    event_name,
    user_pseudo_id,
    CAST((SELECT COALESCE(value.double_value, value.int_value)
          FROM UNNEST(event_params) WHERE key = 'level') AS INT64) AS level
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND event_name IN ('level_start', 'level_complete', 'level_fail')
)
SELECT
  level,
  COUNTIF(event_name = 'level_start') AS starts,
  COUNTIF(event_name = 'level_complete') AS completes,
  COUNTIF(event_name = 'level_fail') AS fails,
  ROUND(COUNTIF(event_name = 'level_complete') / NULLIF(COUNTIF(event_name = 'level_start'), 0), 3) AS completion_rate,
  COUNT(DISTINCT IF(event_name = 'level_start', user_pseudo_id, NULL)) AS players
FROM level_events
WHERE level IS NOT NULL
GROUP BY level
ORDER BY level
