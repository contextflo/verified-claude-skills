-- dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- Answers: sessions by SESSION-LEVEL source / medium / campaign.
-- source, medium and campaign live in event_params and are only set on some events of a
-- session, so take the first non-null value in the session. Sessions with none are shown
-- as (direct)/(none) here, which is a simplification of GA4's last non-direct click rules.
-- Newer exports also have session_traffic_source_last_click and collected_traffic_source;
-- this 2020 sample does not.
-- Verified: ran on bigquery-public-data.ga4_obfuscated_sample_ecommerce on 2026-11-05, returned 20 rows.
--   session_source                   session_medium  session_campaign  sessions
--   (direct)                         (none)          (direct)          49616
--   google                           organic         (organic)         34214
--   shop.googlemerchandisestore.com  referral        (referral)        19219
--   <Other>                          <Other>         <Other>           10295

WITH events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source') AS source,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium') AS medium,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign') AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
),
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    ARRAY_AGG(source IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS source,
    ARRAY_AGG(medium IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS medium,
    ARRAY_AGG(campaign IGNORE NULLS ORDER BY event_timestamp LIMIT 1)[SAFE_OFFSET(0)] AS campaign
  FROM events
  GROUP BY user_pseudo_id, session_id
)
SELECT
  IFNULL(source, '(direct)') AS session_source,
  IFNULL(medium, '(none)') AS session_medium,
  IFNULL(campaign, '(direct)') AS session_campaign,
  COUNT(*) AS sessions
FROM sessions
GROUP BY session_source, session_medium, session_campaign
ORDER BY sessions DESC
LIMIT 20
