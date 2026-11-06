-- dataset: bigquery-public-data.google_analytics_sample
-- Answers: landing pages with sessions, bounce rate and transactions.
-- The landing page is the hit with isEntrance = TRUE. Join session totals from the same row,
-- and keep exactly one entrance hit per session so totals are not repeated.
-- Verified: ran on bigquery-public-data.google_analytics_sample on 2026-11-05, returned 20 rows.
--   landing_page                             sessions  bounce_rate  transactions
--   /home                                    38434     0.5048       330
--   /google+redesign/shop+by+brand/youtube   7429      0.5025       26
--   /signin.html                             3307      0.3366       11

WITH landing AS (
  SELECT
    (SELECT h.page.pagePath FROM UNNEST(hits) AS h
     WHERE h.isEntrance = TRUE ORDER BY h.hitNumber LIMIT 1) AS landing_page,
    totals.visits,
    totals.bounces,
    totals.transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
)
SELECT
  landing_page,
  SUM(visits) AS sessions,
  ROUND(SUM(bounces) / SUM(visits), 4) AS bounce_rate,
  IFNULL(SUM(transactions), 0) AS transactions
FROM landing
WHERE landing_page IS NOT NULL
GROUP BY landing_page
ORDER BY sessions DESC
LIMIT 20
