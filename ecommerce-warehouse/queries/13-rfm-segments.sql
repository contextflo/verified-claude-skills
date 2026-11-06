-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: RFM (recency, frequency, monetary) segments of customers as of a fixed date.
-- Pin the "as of" date. Using CURRENT_DATE() makes the result change every day, and this
-- dataset keeps adding rows.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 5 rows.
--   segment                 customers  avg_recency_days  avg_orders  avg_net_revenue
--   cooling                 15160      445               1.55        117.02
--   lapsed                  10706      1236              1.2         50.54
--   new or one-time recent  8164       114               1.0         84.82
--   loyal                   6996       110               2.47        166.21
--   lapsed high value       4454       1185              1.55        229.57

WITH params AS (SELECT TIMESTAMP '2026-01-01' AS as_of),
order_net AS (
  SELECT
    o.user_id,
    o.order_id,
    o.created_at,
    SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)) AS net_revenue
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi USING (order_id)
  WHERE o.created_at < (SELECT as_of FROM params)
  GROUP BY o.user_id, o.order_id, o.created_at
),
customers AS (
  SELECT
    user_id,
    TIMESTAMP_DIFF((SELECT as_of FROM params), MAX(created_at), DAY) AS recency_days,
    COUNT(*) AS frequency,
    SUM(net_revenue) AS monetary
  FROM order_net
  GROUP BY user_id
  HAVING SUM(net_revenue) > 0
),
scored AS (
  SELECT
    *,
    NTILE(3) OVER (ORDER BY recency_days DESC) AS r,
    CASE WHEN frequency >= 3 THEN 3 WHEN frequency = 2 THEN 2 ELSE 1 END AS f,
    NTILE(3) OVER (ORDER BY monetary) AS m
  FROM customers
)
SELECT
  CASE
    WHEN r = 3 AND f >= 2 THEN 'loyal'
    WHEN r = 3 AND f = 1 THEN 'new or one-time recent'
    WHEN r = 2 THEN 'cooling'
    WHEN r = 1 AND m = 3 THEN 'lapsed high value'
    ELSE 'lapsed'
  END AS segment,
  COUNT(*) AS customers,
  ROUND(AVG(recency_days), 0) AS avg_recency_days,
  ROUND(AVG(frequency), 2) AS avg_orders,
  ROUND(AVG(monetary), 2) AS avg_net_revenue
FROM scored
GROUP BY segment
ORDER BY customers DESC
