-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: top products by revenue and quantity purchased.
-- Products are a second level of nesting: UNNEST(hits), then UNNEST(h.product).
-- Purchases are eCommerceAction.action_type = '6' (a STRING). Most product rows are list
-- impressions (isImpression = TRUE, action_type '0'), which must never be counted as sales.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 20 rows.
--   product                     category  quantity  product_revenue  transactions
--   Leatherette Journal         Office    309       3048.74          21
--   Google Men's  Zip Hoodie    Apparel   57        2884.47          43
--   Google Rucksack             Bags      38        2623.32          9

SELECT
  p.v2ProductName AS product,
  p.v2ProductCategory AS category,
  SUM(p.productQuantity) AS quantity,
  ROUND(SUM(p.productRevenue) / 1e6, 2) AS product_revenue,
  COUNT(DISTINCT h.transaction.transactionId) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h,
  UNNEST(h.product) AS p
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  AND h.eCommerceAction.action_type = '6'
  AND p.productRevenue IS NOT NULL
GROUP BY product, category
ORDER BY product_revenue DESC
LIMIT 20
