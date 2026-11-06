-- dataset: bigquery-public-data.thelook_ecommerce
-- Answers: share of new customers who place a second order within 30, 90 and 180 days, by
-- month of first order.
-- Counts orders that were not fully cancelled. A customer's "second order" is their next
-- order by orders.created_at, not their second order item.
-- Verified: ran on bigquery-public-data.thelook_ecommerce on 2026-11-05, returned 4 rows.
--   cohort_month  new_customers  repeat_30d  repeat_90d  repeat_180d
--   2025-01-01    1128           0.0257      0.0585      0.1206
--   2025-02-01    1041           0.0211      0.0692      0.1258
--   2025-03-01    1241           0.025       0.0685      0.1185

WITH valid_orders AS (
  SELECT user_id, order_id, created_at
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
),
ranked AS (
  SELECT
    user_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, order_id) AS n
  FROM valid_orders
),
firsts AS (
  SELECT
    f.user_id,
    f.created_at AS first_at,
    s.created_at AS second_at
  FROM ranked AS f
  LEFT JOIN ranked AS s ON s.user_id = f.user_id AND s.n = 2
  WHERE f.n = 1
)
SELECT
  DATE_TRUNC(DATE(first_at), MONTH) AS cohort_month,
  COUNT(*) AS new_customers,
  ROUND(COUNTIF(TIMESTAMP_DIFF(second_at, first_at, DAY) <= 30) / COUNT(*), 4) AS repeat_30d,
  ROUND(COUNTIF(TIMESTAMP_DIFF(second_at, first_at, DAY) <= 90) / COUNT(*), 4) AS repeat_90d,
  ROUND(COUNTIF(TIMESTAMP_DIFF(second_at, first_at, DAY) <= 180) / COUNT(*), 4) AS repeat_180d
FROM firsts
WHERE first_at >= '2025-01-01' AND first_at < '2025-05-01'
GROUP BY cohort_month
ORDER BY cohort_month
