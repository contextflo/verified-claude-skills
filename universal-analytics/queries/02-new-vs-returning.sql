-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions, transactions and revenue for new vs returning visitors.
-- totals.newVisits is 1 on the user's first session and NULL otherwise (not 0).
-- visitNumber = 1 is the same thing.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 2 rows.
--   visitor_type  sessions  users  transactions  revenue   conversion_rate
--   new           48502     48459  282           27672.35  0.0058
--   returning     16192     9744   431           78575.8   0.0266

SELECT
  IF(totals.newVisits = 1, 'new', 'returning') AS visitor_type,
  SUM(totals.visits) AS sessions,
  COUNT(DISTINCT fullVisitorId) AS users,
  SUM(totals.transactions) AS transactions,
  ROUND(SUM(totals.totalTransactionRevenue) / 1e6, 2) AS revenue,
  ROUND(SUM(totals.transactions) / SUM(totals.visits), 4) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY visitor_type
ORDER BY sessions DESC
