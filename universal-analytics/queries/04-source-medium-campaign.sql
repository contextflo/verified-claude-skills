-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions, transactions and revenue by source / medium / campaign.
-- UA's trafficSource is SESSION-level (last non-direct click), unlike GA4's traffic_source
-- which is the user's first touch. trafficSource.isTrueDirect marks real direct sessions.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 20 rows.
--   source       medium    campaign          sessions  transactions  revenue
--   (direct)     (none)    (not set)         46795     647           96134.16
--   youtube.com  referral  (not set)         9709      4             164.88
--   google       organic   (not set)         2381      20            2207.29
--   Partners     affiliate Data Share Promo  1243      0             0.0

SELECT
  trafficSource.source,
  trafficSource.medium,
  trafficSource.campaign,
  SUM(totals.visits) AS sessions,
  IFNULL(SUM(totals.transactions), 0) AS transactions,
  ROUND(IFNULL(SUM(totals.totalTransactionRevenue), 0) / 1e6, 2) AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY trafficSource.source, trafficSource.medium, trafficSource.campaign
ORDER BY sessions DESC
LIMIT 20
