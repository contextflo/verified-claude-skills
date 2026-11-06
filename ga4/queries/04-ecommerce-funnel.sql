-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: ordered user funnel view_item > add_to_cart > begin_checkout > purchase.
-- Each step only counts if it happened after the user's first time at the previous step.
-- Without the ordering you count users who purchased without ever viewing an item in the window.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 4 rows.
--   step               users  pct_of_step1
--   s1_view_item       22906  1.0
--   s2_add_to_cart     6261   0.2733
--   s3_begin_checkout  2372   0.1036
--   s4_purchase        1355   0.0592

WITH firsts AS (
  SELECT
    user_pseudo_id,
    MIN(IF(event_name = 'view_item', event_timestamp, NULL)) AS t_view,
    MIN(IF(event_name = 'add_to_cart', event_timestamp, NULL)) AS t_cart,
    MIN(IF(event_name = 'begin_checkout', event_timestamp, NULL)) AS t_checkout,
    MIN(IF(event_name = 'purchase', event_timestamp, NULL)) AS t_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY user_pseudo_id
),
steps AS (
  SELECT
    COUNTIF(t_view IS NOT NULL) AS s1_view_item,
    COUNTIF(t_cart > t_view) AS s2_add_to_cart,
    COUNTIF(t_checkout > t_cart AND t_cart > t_view) AS s3_begin_checkout,
    COUNTIF(t_purchase > t_checkout AND t_checkout > t_cart AND t_cart > t_view) AS s4_purchase
  FROM firsts
)
SELECT step, users, ROUND(users / FIRST_VALUE(users) OVER (ORDER BY step), 4) AS pct_of_step1
FROM steps
UNPIVOT (users FOR step IN (s1_view_item, s2_add_to_cart, s3_begin_checkout, s4_purchase))
ORDER BY step
