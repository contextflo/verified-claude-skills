---
name: universal-analytics
description: Write correct BigQuery SQL against the Universal Analytics (UA / GA 360) BigQuery export (ga_sessions_YYYYMMDD tables with nested hits, product and customDimensions), and port UA queries to GA4. Use when the user mentions ga_sessions, Universal Analytics, GA360, fullVisitorId, totals.*, hits.*, or wants old UA history next to GA4 data.
---

# Universal Analytics (UA 360) export

Every query in `queries/` was run against `bigquery-public-data.google_analytics_sample` and its result is in the file header. Swap in the user's own `project.dataset.ga_sessions_*`.

UA stopped collecting data in 2023 (360: 2024). These tables are history and will not grow.

## Rules

1. **Filter `_TABLE_SUFFIX`** on `ga_sessions_*`, and answer from `totals` when possible. Unnesting `hits` costs hundreds of times more bytes.
2. **Sessions = `SUM(totals.visits)`.** Session key = `fullVisitorId` + `visitStartTime`. Not `visitId` (only unique per user) and not `fullVisitorId + visitId` (repeats across midnight splits).
3. **Money is micros.** Divide by `1e6`. Use `totals.totalTransactionRevenue`, not the deprecated `totals.transactionRevenue`.
4. **Sum each level at its own grain.** After `UNNEST(hits)` session columns repeat per hit; after `UNNEST(h.product)` hit columns repeat per product.
5. **Exclude impressions.** Most `hits.product` rows are `isImpression = TRUE`. Purchases are `eCommerceAction.action_type = '6'` (a string).
6. **`totals.bounces` / `newVisits` / `visits` are 1 or NULL.** Rates are `SUM(x) / SUM(totals.visits)`, never `AVG(x)`.
7. **`trafficSource` is session-level** (last non-direct click). GA4's `traffic_source` is first touch. Check `ua-to-ga4.md` before porting any query.
8. **`date` is the view's time zone, `visitStartTime` is UTC.** Group by `date` to match UA reports.

## Files

- `schema.md`: session columns, totals, trafficSource, hits, hits.product, action_type codes.
- `gotchas.md`: each trap with wrong vs right SQL and sample numbers.
- `ua-to-ga4.md`: the same question in UA and GA4, field by field.
- `queries/`: 13 tested queries:
  - `01` sessions/users/pageviews per day, `02` new vs returning, `03` channel bounce and conversion
  - `04` source/medium/campaign, `05` top pages, `06` landing pages
  - `07` revenue/AOV/conversion, `08` product revenue, `09` shopping funnel
  - `10` device and country, `11` custom dimensions, `12` events
  - `13` UA hits reshaped into GA4-style event rows

For GA4 itself, use the `ga4` pack.
