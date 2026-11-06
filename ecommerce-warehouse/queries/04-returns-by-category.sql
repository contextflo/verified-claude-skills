-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: return rate and returned revenue by category, and how long returns take.
-- The denominator is items that could have been returned (delivered or returned), not all
-- items: Processing, Shipped and Cancelled items were never in the customer's hands.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 26 rows.
--   category   delivered_items  returned_items  return_rate  returned_revenue  avg_days_delivered_to_return
--   Leggings   244              84              0.3443       2706.23           1.6
--   Plus       334              106             0.3174       3315.63           1.5
--   Suits      82               25              0.3049       2846.51           1.3

SELECT
  ii.product_category AS category,
  COUNTIF(oi.delivered_at IS NOT NULL OR oi.returned_at IS NOT NULL) AS delivered_items,
  COUNTIF(oi.status = 'Returned') AS returned_items,
  ROUND(COUNTIF(oi.status = 'Returned')
    / COUNTIF(oi.delivered_at IS NOT NULL OR oi.returned_at IS NOT NULL), 4) AS return_rate,
  ROUND(SUM(IF(oi.status = 'Returned', oi.sale_price, 0)), 2) AS returned_revenue,
  ROUND(AVG(IF(oi.status = 'Returned', TIMESTAMP_DIFF(oi.returned_at, oi.delivered_at, HOUR) / 24, NULL)), 1) AS avg_days_delivered_to_return
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o USING (order_id)
JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii ON ii.id = oi.inventory_item_id
WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
GROUP BY category
ORDER BY return_rate DESC
