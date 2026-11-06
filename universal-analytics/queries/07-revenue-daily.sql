-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: daily revenue, transactions, ecommerce conversion rate and AOV.
-- Money fields are stored multiplied by 10^6: divide by 1e6.
-- totals.transactionRevenue is deprecated; use totals.totalTransactionRevenue. In January
-- 2017 they differ: 97,877.79 vs 106,248.15.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 31 rows.
--   day         sessions  transactions  revenue  conversion_rate  aov
--   2017-01-01  1364      11            993.01   0.0081           90.27
--   2017-01-02  1620      18            1027.6   0.0111           57.09
--   2017-01-03  2403      32            4574.74  0.0133           142.96

SELECT
  PARSE_DATE('%Y%m%d', date) AS day,
  SUM(totals.visits) AS sessions,
  IFNULL(SUM(totals.transactions), 0) AS transactions,
  ROUND(IFNULL(SUM(totals.totalTransactionRevenue), 0) / 1e6, 2) AS revenue,
  ROUND(IFNULL(SUM(totals.transactions), 0) / SUM(totals.visits), 4) AS conversion_rate,
  ROUND(SAFE_DIVIDE(SUM(totals.totalTransactionRevenue) / 1e6, SUM(totals.transactions)), 2) AS aov
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY day
ORDER BY day
