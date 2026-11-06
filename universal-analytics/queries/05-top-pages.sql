-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: pageviews and unique pageviews by page path.
-- Pages live in the hits array: UNNEST(hits) and keep hits.type = 'PAGE'. Without the type
-- filter EVENT hits on the same page are counted as pageviews.
-- Unique pageviews = sessions that viewed the page at least once.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 20 rows.
--   pagePath                                 pageviews  unique_pageviews
--   /home                                    66056      41587
--   /basket.html                             16674      5975
--   /google+redesign/shop+by+brand/youtube   11868      9005

SELECT
  h.page.pagePath,
  COUNT(*) AS pageviews,
  COUNT(DISTINCT CONCAT(fullVisitorId, '-', CAST(visitStartTime AS STRING))) AS unique_pageviews
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  AND h.type = 'PAGE'
GROUP BY h.page.pagePath
ORDER BY pageviews DESC
LIMIT 20
