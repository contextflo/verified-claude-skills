-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: monthly net revenue split into first orders vs repeat orders.
-- "New" is decided by the customer's first order ever, computed over all history, not
-- only over the reporting window (otherwise every customer looks new in January).
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 12 rows.
--   month       first_order_revenue  repeat_revenue  repeat_share
--   2025-01-01  81997.36             51589.9         0.3862
--   2025-02-01  78598.61             40592.0         0.3406
--   2025-03-01  86731.58             49639.58        0.364

WITH order_net AS (
  SELECT
    o.user_id,
    o.order_id,
    o.created_at,
    SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)) AS net_revenue
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi USING (order_id)
  GROUP BY o.user_id, o.order_id, o.created_at
),
flagged AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, order_id) = 1 AS is_first_order
  FROM order_net
)
SELECT
  DATE_TRUNC(DATE(created_at), MONTH) AS month,
  ROUND(SUM(IF(is_first_order, net_revenue, 0)), 2) AS first_order_revenue,
  ROUND(SUM(IF(NOT is_first_order, net_revenue, 0)), 2) AS repeat_revenue,
  ROUND(SUM(IF(NOT is_first_order, net_revenue, 0)) / SUM(net_revenue), 4) AS repeat_share
FROM flagged
WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01'
GROUP BY month
ORDER BY month
