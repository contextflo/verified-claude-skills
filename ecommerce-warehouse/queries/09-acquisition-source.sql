-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: customers, orders and net revenue per customer by acquisition source.
-- users.traffic_source is the source at signup (one per user). events.traffic_source is
-- per web event and can differ for the same user. Use users.* for acquisition questions.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 5 rows.
--   traffic_source  signed_up_users  customers  signup_to_customer  orders_per_customer  net_revenue_per_customer
--   Search          70294            56031      0.7971              1.56                 101.47
--   Organic         14692            11735      0.7987              1.56                 102.59
--   Facebook        6034             4791       0.794               1.56                 99.91
-- The near-identical rows across sources are a property of this synthetic data.

WITH customer_value AS (
  SELECT
    o.user_id,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(IF(oi.status NOT IN ('Cancelled', 'Returned'), oi.sale_price, 0)) AS net_revenue
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi USING (order_id)
  GROUP BY o.user_id
)
SELECT
  u.traffic_source,
  COUNT(*) AS signed_up_users,
  COUNT(cv.user_id) AS customers,
  ROUND(COUNT(cv.user_id) / COUNT(*), 4) AS signup_to_customer,
  ROUND(AVG(cv.orders), 2) AS orders_per_customer,
  ROUND(AVG(cv.net_revenue), 2) AS net_revenue_per_customer
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN customer_value AS cv ON cv.user_id = u.id
GROUP BY u.traffic_source
ORDER BY signed_up_users DESC
