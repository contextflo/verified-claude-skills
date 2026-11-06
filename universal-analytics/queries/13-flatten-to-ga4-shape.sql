-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: UA hits reshaped into GA4-style event rows, so one downstream model can read
-- both exports (for example a UA history table unioned with GA4 events).
-- Maps PAGE hits to page_view, EVENT hits to their action, and purchases to purchase.
-- Session key is fullVisitorId + visitStartTime; event_timestamp is UTC micros like GA4.
-- The output here is aggregated to keep the check small; drop the final GROUP BY to get rows.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 9 rows.
--   event_name       events  sessions  first_event_utc
--   page_view        56519   13795     2017-01-01 08:00:23
--   quickview_click  5410    1919      2017-01-01 08:00:23
--   add_to_cart      1558    707       2017-01-01 08:42:01
-- first_event_utc of 08:00 shows the tables are cut on Pacific time (UTC-8), not UTC.
-- EVENT hits with no eventAction come out with a NULL event_name; name them before use.

WITH events AS (
  SELECT
    date AS event_date,
    (visitStartTime * 1000000) + (h.time * 1000) AS event_timestamp,
    CASE
      WHEN h.eCommerceAction.action_type = '6' THEN 'purchase'
      WHEN h.type = 'PAGE' THEN 'page_view'
      WHEN h.type = 'EVENT' THEN LOWER(REPLACE(h.eventInfo.eventAction, ' ', '_'))
      ELSE LOWER(h.type)
    END AS event_name,
    fullVisitorId AS user_pseudo_id,
    visitStartTime AS ga_session_id,
    CONCAT(h.page.hostname, h.page.pagePath) AS page_location,
    trafficSource.source AS session_source,
    trafficSource.medium AS session_medium
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170107'
)
SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))) AS sessions,
  MIN(TIMESTAMP_MICROS(event_timestamp)) AS first_event_utc
FROM events
GROUP BY event_name
ORDER BY events DESC
LIMIT 15
