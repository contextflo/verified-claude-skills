-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: top products by net revenue, with units, margin and return rate.
-- One order_items row is one unit (there is no quantity column), so COUNT(*) is units.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 20 rows.
--   product_id  product                     brand          category             net_units  net_revenue  gross_margin  return_rate
--   8721        Nobis Merideth Parka        Nobis          Outerwear & Coats    5          3975.0       2063.03       0.0
--   20420       Paul Fredrick Herringbone   Paul Fredrick  Suits & Sport Coats  8          3396.0       2020.62       0.0
--               Wool Blend Double-Breasted Suit

SELECT
  p.id AS product_id,
  p.name AS product,
  p.brand,
  p.category,
  COUNTIF(oi.status NOT IN ('Cancelled', 'Returned')) AS net_units,
  ROUND(SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)), 2) AS net_revenue,
  ROUND(SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price - p.cost, 0)), 2) AS gross_margin,
  ROUND(COUNTIF(oi.status = 'Returned') / NULLIF(COUNTIF(oi.status IN ('Complete', 'Returned')), 0), 3) AS return_rate
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o USING (order_id)
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p ON p.id = oi.product_id
WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
GROUP BY product_id, product, p.brand, p.category
ORDER BY net_revenue DESC
LIMIT 20
