-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: is the export complete? Daily tables present vs expected per month, intraday
-- tables still lying around, and the date range covered.
-- Run this before trusting a trend: a missing day looks exactly like a traffic drop.
-- Reads only metadata, so it scans 0 bytes.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 3 rows.
--   month       daily_tables  days_spanned  missing_days_inside_span  intraday_tables_in_dataset
--   2020-11-01  30            30            0                         0
--   2020-12-01  31            31            0                         0
--   2021-01-01  31            31            0                         0

WITH shards AS (
  SELECT
    PARSE_DATE('%Y%m%d', REGEXP_EXTRACT(table_name, r'^events_(\d{8})$')) AS day,
    table_name LIKE 'events_intraday_%' AS is_intraday
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.INFORMATION_SCHEMA.TABLES`
  WHERE table_name LIKE 'events_%'
),
months AS (
  SELECT DATE_TRUNC(day, MONTH) AS month, COUNT(*) AS daily_tables, MIN(day) AS first_day, MAX(day) AS last_day
  FROM shards
  WHERE day IS NOT NULL
  GROUP BY month
)
SELECT
  month,
  daily_tables,
  DATE_DIFF(last_day, first_day, DAY) + 1 AS days_spanned,
  DATE_DIFF(last_day, first_day, DAY) + 1 - daily_tables AS missing_days_inside_span,
  (SELECT COUNTIF(is_intraday) FROM shards) AS intraday_tables_in_dataset
FROM months
ORDER BY month
