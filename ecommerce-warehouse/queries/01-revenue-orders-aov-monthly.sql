-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: monthly orders, net revenue and average order value.
-- Net = excludes Cancelled and Returned items. Revenue lives on order_items.sale_price; the
-- order date comes from orders.created_at (order_items.created_at is a different
-- timestamp and puts 23% of orders on another day).
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 12 rows.
--   month       net_orders  net_revenue  aov
--   2025-01-01  1501        133587.26    89.0
--   2025-02-01  1358        119190.61    87.77
--   2025-03-01  1614        136371.16    84.49

WITH order_revenue AS (
  SELECT
    o.order_id,
    DATE_TRUNC(DATE(o.created_at), MONTH) AS month,
    SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)) AS net_revenue
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi USING (order_id)
  WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
  GROUP BY o.order_id, month
)
SELECT
  month,
  COUNTIF(net_revenue > 0) AS net_orders,
  ROUND(SUM(net_revenue), 2) AS net_revenue,
  ROUND(SUM(net_revenue) / COUNTIF(net_revenue > 0), 2) AS aov
FROM order_revenue
GROUP BY month
ORDER BY month
