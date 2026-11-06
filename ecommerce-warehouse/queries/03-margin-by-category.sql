-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: gross margin by product category (net of cancelled and returned items).
-- Cost is per physical unit in inventory_items.cost, joined by inventory_item_id. In this
-- sample it always equals products.cost, but on real data the unit cost is the one to use.
-- No shipping, discounts, fees or tax exist in this dataset, so this is product margin only.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 26 rows.
--   category             units  revenue    cost       gross_margin  margin_pct
--   Outerwear & Coats    1540   226146.43  100757.92  125388.51     0.5545
--   Jeans                2215   214347.73  114750.18  99597.55      0.4647
--   Sweaters             1850   137903.33  66424.85   71478.48      0.5183

SELECT
  ii.product_category AS category,
  COUNT(*) AS units,
  ROUND(SUM(oi.sale_price), 2) AS revenue,
  ROUND(SUM(ii.cost), 2) AS cost,
  ROUND(SUM(oi.sale_price - ii.cost), 2) AS gross_margin,
  ROUND(SUM(oi.sale_price - ii.cost) / SUM(oi.sale_price), 4) AS margin_pct
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o USING (order_id)
JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii ON ii.id = oi.inventory_item_id
WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
  AND oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY category
ORDER BY gross_margin DESC
