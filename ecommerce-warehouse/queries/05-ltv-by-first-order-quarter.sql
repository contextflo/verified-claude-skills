-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: customer lifetime value at 90 and 365 days, by quarter of first order.
-- LTV is measured over a fixed window after each customer's first order, so older cohorts
-- are not favoured just for having had more time. Cohorts too young for the full window
-- show NULL. Net revenue excludes cancelled and returned items.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 12 rows.
--   cohort_quarter  customers  ltv_90d  ltv_365d
--   2023-01-01      2233       67.8     77.59
--   2023-04-01      2293       67.55    77.41
--   2024-01-01      2844       70.3     81.16

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
customers AS (
  SELECT user_id, MIN(created_at) AS first_order_at
  FROM order_net
  GROUP BY user_id
),
data_end AS (
  SELECT MAX(created_at) AS last_order_at FROM order_net
)
SELECT
  DATE_TRUNC(DATE(c.first_order_at), QUARTER) AS cohort_quarter,
  COUNT(DISTINCT c.user_id) AS customers,
  ROUND(SUM(IF(TIMESTAMP_DIFF(n.created_at, c.first_order_at, DAY) < 90, n.net_revenue, 0))
    / COUNT(DISTINCT c.user_id), 2) AS ltv_90d,
  IF(TIMESTAMP_ADD(MAX(c.first_order_at), INTERVAL 365 DAY) > (SELECT last_order_at FROM data_end), NULL,
    ROUND(SUM(IF(TIMESTAMP_DIFF(n.created_at, c.first_order_at, DAY) < 365, n.net_revenue, 0))
      / COUNT(DISTINCT c.user_id), 2)) AS ltv_365d
FROM customers AS c
JOIN order_net AS n USING (user_id)
WHERE c.first_order_at >= '2023-01-01' AND c.first_order_at < '2026-01-01'
GROUP BY cohort_quarter
ORDER BY cohort_quarter
