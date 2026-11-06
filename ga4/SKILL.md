---
name: ga4
description: Write correct BigQuery SQL against the Google Analytics 4 (GA4) BigQuery export (analytics_<id>.events_YYYYMMDD tables). Use when the user asks about GA4, Google Analytics 4, or an analytics_ dataset in BigQuery - sessions, users, engagement, conversions, funnels, traffic source, landing pages, revenue, items, retention - or wonders why BigQuery numbers differ from the GA4 UI.
---

# GA4 BigQuery export

Every query in `queries/` was run against `bigquery-public-data.ga4_obfuscated_sample_ecommerce` and its result is recorded in the file header. Swap in the user's own `project.analytics_XXXX` dataset and date range.

## Rules

1. **Always filter with `_TABLE_SUFFIX`** on `events_*`, never only `event_date`. The tables are date-sharded; `event_date` filters scan every table (12x the bytes in our test). Dry-run (`bq query --dry_run`) anything over a long range, and select only the columns you need.
2. **Read event_params with one scalar subquery per key**: `(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')`. Do not cross join `UNNEST(event_params)` and then count.
3. **Check the value type before using a param.** Some keys switch between `string_value`, `int_value` and `double_value` across events (`session_engaged`, `value`, `tax`, `transaction_id`). Coalesce the columns, or prefer a typed column like `ecommerce.purchase_revenue`.
4. **Session = `user_pseudo_id` + `ga_session_id`.** `ga_session_id` alone collides across users.
5. **`traffic_source` is first-touch per user, not per session.** For session source/medium/campaign use the `source`/`medium`/`campaign` event_params (or `session_traffic_source_last_click` in newer exports).
6. **Never sum event-level money after `UNNEST(items)`**; it repeats per item. De-duplicate purchases by `ecommerce.transaction_id`.
7. **Days are in the property time zone.** Group by `event_date`, not `DATE(TIMESTAMP_MICROS(event_timestamp))`, which is UTC. Do not union intraday tables with daily tables for the same date.
8. **Expect small gaps vs the GA4 UI** (estimation, thresholding, Google signals, consent modeling). Say so instead of forcing a match. Check export completeness (`queries/15-export-health.sql`) before reading a trend, and check `MIN(_TABLE_SUFFIX)`: the export has no data from before it was linked.

## Files

- `schema.md`: tables, columns, nested and repeated fields, which param uses which value column.
- `gotchas.md`: each trap with wrong vs right SQL and the numbers from the sample.
- `queries/`: 15 tested queries. Start from the closest one:
  - `01` sessions/users/events per day, `02` new vs returning, `03` engagement rate
  - `04` ordered funnel, `05` event counts (pick key events)
  - `06` first-touch traffic, `07` session-level source/medium/campaign
  - `08` top pages, `09` landing pages
  - `10` revenue/orders/AOV, `11` top products from items
  - `12` device and country, `13` DAU/WAU/MAU, `14` weekly retention cohorts
  - `15` export health (missing days, intraday tables)

For app streams (Firebase), also see the `firebase-app` pack.
