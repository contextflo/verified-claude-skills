-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions, bounce rate, pages per session and conversion rate by default channel.
-- channelGrouping is UA's Default Channel Grouping, stored per session.
-- totals.bounces is 1 or NULL, never 0, so bounce rate is SUM(bounces) / SUM(visits).
-- AVG(totals.bounces) skips the NULLs and always returns 1.0.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 8 rows.
--   channelGrouping  sessions  bounce_rate  pages_per_session  conversion_rate
--   Organic Search   28769     0.472        4.2                0.0072
--   Direct           13381     0.4908       3.72               0.009
--   Social           10454     0.6775       1.96               0.0006
--   Referral         7648      0.2645       6.18               0.0426

SELECT
  channelGrouping,
  SUM(totals.visits) AS sessions,
  ROUND(SUM(totals.bounces) / SUM(totals.visits), 4) AS bounce_rate,
  ROUND(SUM(totals.pageviews) / SUM(totals.visits), 2) AS pages_per_session,
  ROUND(IFNULL(SUM(totals.transactions), 0) / SUM(totals.visits), 4) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY channelGrouping
ORDER BY sessions DESC
