-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: hours from order to ship and ship to delivery, by distribution center.
-- Use percentiles, not only averages: delivery times have long tails.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 10 rows.
--   distribution_center  delivered_items  avg_hours_to_ship  avg_hours_ship_to_deliver  p90_hours_order_to_deliver
--   Chicago IL           1934             35.2               60.5                       150
--   Los Angeles CA       1361             35.8               61.3                       152
--   Mobile AL            1379             35.9               61.8                       152

SELECT
  dc.name AS distribution_center,
  COUNT(*) AS delivered_items,
  ROUND(AVG(TIMESTAMP_DIFF(oi.shipped_at, o.created_at, MINUTE)) / 60, 1) AS avg_hours_to_ship,
  ROUND(AVG(TIMESTAMP_DIFF(oi.delivered_at, oi.shipped_at, MINUTE)) / 60, 1) AS avg_hours_ship_to_deliver,
  APPROX_QUANTILES(TIMESTAMP_DIFF(oi.delivered_at, o.created_at, HOUR), 100)[OFFSET(90)] AS p90_hours_order_to_deliver
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o USING (order_id)
JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii ON ii.id = oi.inventory_item_id
JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc ON dc.id = ii.product_distribution_center_id
WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
  AND oi.delivered_at IS NOT NULL
GROUP BY distribution_center
ORDER BY avg_hours_to_ship
