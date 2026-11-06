-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: sessions by a session-scoped custom dimension.
-- customDimensions is a repeated record of (index, value). Index numbers are only meaningful
-- in the property's admin settings, so ask what each index means. Hit-scoped dimensions live
-- in hits.customDimensions instead. This sample has one session-level index (4).
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 6 rows.
--   cd4            sessions  transactions
--   North America  30945     697
--   EMEA           13405     2
--   NULL           10809     7
--   APAC           7723      5

SELECT
  (SELECT value FROM UNNEST(customDimensions) WHERE index = 4) AS cd4,
  SUM(totals.visits) AS sessions,
  IFNULL(SUM(totals.transactions), 0) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY cd4
ORDER BY sessions DESC
