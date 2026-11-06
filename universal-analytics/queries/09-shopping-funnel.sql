-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: Enhanced Ecommerce shopping funnel, sessions reaching each step.
-- action_type codes (strings): '1' product list click, '2' product detail view,
-- '3' add to cart, '4' remove from cart, '5' checkout, '6' purchase.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 5 rows.
--   step               sessions  pct_of_all_sessions
--   s0_all_sessions    64694     1.0
--   s1_product_detail  9221      0.1425
--   s2_add_to_cart     3388      0.0524
--   s3_checkout        1538      0.0238
--   s4_purchase        697       0.0108

WITH session_steps AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    LOGICAL_OR(h.eCommerceAction.action_type = '2') AS viewed_product,
    LOGICAL_OR(h.eCommerceAction.action_type = '3') AS added_to_cart,
    LOGICAL_OR(h.eCommerceAction.action_type = '5') AS checkout,
    LOGICAL_OR(h.eCommerceAction.action_type = '6') AS purchased
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  GROUP BY fullVisitorId, visitStartTime
)
SELECT step, sessions, ROUND(sessions / FIRST_VALUE(sessions) OVER (ORDER BY step), 4) AS pct_of_all_sessions
FROM (
  SELECT
    COUNT(*) AS s0_all_sessions,
    COUNTIF(viewed_product) AS s1_product_detail,
    COUNTIF(added_to_cart) AS s2_add_to_cart,
    COUNTIF(checkout) AS s3_checkout,
    COUNTIF(purchased) AS s4_purchase
  FROM session_steps
)
UNPIVOT (sessions FOR step IN (s0_all_sessions, s1_product_detail, s2_add_to_cart, s3_checkout, s4_purchase))
ORDER BY step
