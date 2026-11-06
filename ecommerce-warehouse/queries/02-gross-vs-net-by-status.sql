-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: how much of gross revenue is in each order-item status, for one year.
-- SUM(sale_price) over all rows is gross booked revenue, including cancelled and returned
-- items. Decide which statuses count before reporting "revenue". Processing and Shipped are
-- not yet delivered and can still be returned.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 5 rows.
--   status      items  revenue    share_of_gross
--   Shipped     12517  746741.49  0.3072
--   Complete    10275  604274.79  0.2486
--   Processing  8060   480891.36  0.1978
--   Cancelled   6145   371413.85  0.1528
--   Returned    4098   227728.74  0.0937

SELECT
  oi.status,
  COUNT(*) AS items,
  ROUND(SUM(oi.sale_price), 2) AS revenue,
  ROUND(SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (), 4) AS share_of_gross
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o USING (order_id)
WHERE o.created_at >= '2025-01-01' AND o.created_at < '2026-01-01'
GROUP BY oi.status
ORDER BY revenue DESC
