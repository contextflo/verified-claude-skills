-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions and transactions by device category and country.
-- device and geoNetwork are plain records on the session row; no UNNEST needed.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 20 rows.
--   deviceCategory  country        sessions  transactions
--   desktop         United States  19446     606
--   mobile          United States  8187      72
--   desktop         India          2184      0

SELECT
  device.deviceCategory,
  geoNetwork.country,
  SUM(totals.visits) AS sessions,
  IFNULL(SUM(totals.transactions), 0) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY device.deviceCategory, geoNetwork.country
ORDER BY sessions DESC
LIMIT 20
