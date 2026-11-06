-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: web sessions by furthest funnel step (product > cart > purchase), by traffic source.
-- In this dataset a `purchase` event is logged once per order ITEM (180,746 purchase events
-- vs 124,452 orders), so never count purchase events as orders. Count sessions instead.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 5 rows.
--   traffic_source  sessions  product_sessions  cart_sessions  purchase_sessions  session_conversion
--   Email           47259     47204             32803          18527              0.392
--   Adwords         31501     31478             21729          12200              0.3873
--   Facebook        10634     10628             7323           4116               0.3871
-- A 39% session conversion rate is not realistic; the events table is synthetic.

WITH sessions AS (
  SELECT
    session_id,
    ANY_VALUE(traffic_source) AS traffic_source,
    LOGICAL_OR(event_type = 'product') AS saw_product,
    LOGICAL_OR(event_type = 'cart') AS saw_cart,
    LOGICAL_OR(event_type = 'purchase') AS purchased
  FROM `bigquery-public-data.thelook_ecommerce.events`
  WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01'
  GROUP BY session_id
)
SELECT
  traffic_source,
  COUNT(*) AS sessions,
  COUNTIF(saw_product) AS product_sessions,
  COUNTIF(saw_cart) AS cart_sessions,
  COUNTIF(purchased) AS purchase_sessions,
  ROUND(COUNTIF(purchased) / COUNT(*), 4) AS session_conversion
FROM sessions
GROUP BY traffic_source
ORDER BY sessions DESC
