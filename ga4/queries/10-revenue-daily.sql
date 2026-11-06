-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: daily revenue, transactions and average order value.
-- Uses ecommerce.purchase_revenue (a typed FLOAT column) rather than the `value` param,
-- which arrives as int on some events and double on others.
-- Purchases are de-duplicated by transaction_id because the same transaction can be
-- sent more than once. '(not set)' ids are kept as separate orders, one per event.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 31 rows.
--   day         orders  revenue  aov
--   2020-12-01  106     6203.0   58.52
--   2020-12-02  81      5144.0   63.51
--   2020-12-03  89      4277.0   48.06

WITH purchases AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS day,
    IF(ecommerce.transaction_id = '(not set)',
       CONCAT('not_set-', user_pseudo_id, '-', CAST(event_timestamp AS STRING)),
       ecommerce.transaction_id) AS order_id,
    ecommerce.purchase_revenue AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'purchase'
),
orders AS (
  SELECT day, order_id, MAX(revenue) AS revenue
  FROM purchases
  GROUP BY day, order_id
)
SELECT
  day,
  COUNT(*) AS orders,
  ROUND(SUM(revenue), 2) AS revenue,
  ROUND(SUM(revenue) / COUNT(*), 2) AS aov
FROM orders
GROUP BY day
ORDER BY day
