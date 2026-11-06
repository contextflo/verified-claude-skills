-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: customers, net revenue and AOV by customer country.
-- Country comes from users (the customer's address); orders have no ship-to address here.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 14 rows.
--   country        customers  net_orders  net_revenue  aov
--   China          8305       7275        631452.02    86.8
--   United States  5386       4768        408120.58    85.6
--   Brasil         3531       3140        261748.52    83.36

WITH order_net AS (
  SELECT
    o.order_id,
    o.user_id,
    SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)) AS net_revenue
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi USING (order_id)
  WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
  GROUP BY o.order_id, o.user_id
)
SELECT
  u.country,
  COUNT(DISTINCT n.user_id) AS customers,
  COUNTIF(n.net_revenue > 0) AS net_orders,
  ROUND(SUM(n.net_revenue), 2) AS net_revenue,
  ROUND(SUM(n.net_revenue) / NULLIF(COUNTIF(n.net_revenue > 0), 0), 2) AS aov
FROM order_net AS n
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u ON u.id = n.user_id
GROUP BY u.country
ORDER BY net_revenue DESC
