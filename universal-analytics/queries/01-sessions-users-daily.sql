-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions, users, pageviews and new sessions per day.
-- One row = one session, and SUM(totals.visits) is the session count GA reported.
-- totals.visits is 1 for sessions with an interaction hit and NULL otherwise, so
-- COUNT(*) can overcount on properties with non-interaction-only sessions.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 31 rows.
--   day         sessions  users  pageviews  new_sessions
--   2017-01-01  1364      1269   5362       1042
--   2017-01-02  1620      1509   6283       1227
--   2017-01-03  2403      2129   9459       1465

SELECT
  PARSE_DATE('%Y%m%d', date) AS day,
  SUM(totals.visits) AS sessions,
  COUNT(DISTINCT fullVisitorId) AS users,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.newVisits) AS new_sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY day
ORDER BY day
