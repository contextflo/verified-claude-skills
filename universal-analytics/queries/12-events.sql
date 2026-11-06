-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: top events by category / action with total and unique events.
-- UA events are hits with type = 'EVENT' and the hits.eventInfo record. Unique events =
-- sessions with the event at least once.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 7 rows.
--   eventCategory       eventAction      total_events  unique_events
--   Enhanced Ecommerce  Quickview Click  25477         9221
--   Enhanced Ecommerce  Add to Cart      7341          3388
--   Enhanced Ecommerce  Product Click    5423          3121

SELECT
  h.eventInfo.eventCategory,
  h.eventInfo.eventAction,
  COUNT(*) AS total_events,
  COUNT(DISTINCT CONCAT(fullVisitorId, '-', CAST(visitStartTime AS STRING))) AS unique_events
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  AND h.type = 'EVENT'
GROUP BY h.eventInfo.eventCategory, h.eventInfo.eventAction
ORDER BY total_events DESC
LIMIT 20
