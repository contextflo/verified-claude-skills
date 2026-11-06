-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: landing pages (first page of each session), with sessions and purchase rate.
-- The landing page is the page_location of the session's first page_view, ordered by
-- event_timestamp. The `entrances` param (int 1) also marks it.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 20 rows.
--   landing_page                                                 sessions  purchase_sessions  purchase_rate
--   https://shop.googlemerchandisestore.com/                     30219     1003               0.0332
--   https://shop.googlemerchandisestore.com/Google+Redesign/Apparel  17315  58               0.0033
--   https://googlemerchandisestore.com/                          13574     89                 0.0066

WITH events AS (
  SELECT
    user_pseudo_id,
    event_name,
    event_timestamp,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    REGEXP_REPLACE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
      r'[?#].*$', '') AS page
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name IN ('page_view', 'purchase')
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    ARRAY_AGG(IF(event_name = 'page_view', page, NULL) IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS landing_page,
    LOGICAL_OR(event_name = 'purchase') AS purchased
  FROM events
  GROUP BY user_pseudo_id, session_id
)
SELECT
  landing_page,
  COUNT(*) AS sessions,
  COUNTIF(purchased) AS purchase_sessions,
  ROUND(COUNTIF(purchased) / COUNT(*), 4) AS purchase_rate
FROM sessions
WHERE landing_page IS NOT NULL
GROUP BY landing_page
ORDER BY sessions DESC
LIMIT 20
