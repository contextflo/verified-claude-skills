-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: top products by revenue and quantity from purchase events.
-- items is a REPEATED record, one entry per product in the event. UNNEST it, and never
-- SUM(ecommerce.purchase_revenue) after unnesting items: that repeats the order total
-- once per item.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 20 rows.
--   item_name                      item_category  quantity  item_revenue  orders
--   Google Zip Hoodie F/C          Apparel        110       5496.0        99
--   Super G Unisex Joggers         Shop by Brand  139       4307.0        128
--   Google Men's Tech Fleece Grey  Apparel        56        4139.0        43

SELECT
  item.item_name,
  item.item_category,
  SUM(item.quantity) AS quantity,
  ROUND(SUM(item.item_revenue), 2) AS item_revenue,
  COUNT(DISTINCT ecommerce.transaction_id) AS orders
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  AND event_name = 'purchase'
GROUP BY item.item_name, item.item_category
ORDER BY item_revenue DESC
LIMIT 20
