# Universal Analytics (UA 360) export: gotchas

Numbers come from `bigquery-public-data.google_analytics_sample` (Google Merchandise Store, `ga_sessions_20160801` to `ga_sessions_20170801`), January 2017 unless stated, run on 2026-11-05.

## 0. UA is shut down; the tables are history

Standard UA properties stopped processing data on July 1, 2023, and 360 properties on July 1, 2024. "Already exported data remains available in BigQuery", but no new data arrives and the UA UI and API are gone ([Google](https://support.google.com/analytics/answer/11583528)). Your `ga_sessions_*` tables are the only remaining copy of that history. Do not delete them when you move to GA4, and expect a hard stop in every trend at the cutover date.

## 1. One row is one session, but fullVisitorId + visitId is not unique

`visitId` is only unique per user, and UA splits sessions at midnight while keeping the same `visitId`.

| key | distinct values (full year) |
|---|---|
| rows (sessions) | 903,653 |
| fullVisitorId + visitId | 902,755 |
| visitId alone | 886,303 |

The 898 colliding pairs all span two dates with two different `visitStartTime` values: one session cut in two at midnight. Wrong:

```sql
COUNT(DISTINCT visitId)                               -- 886,303
COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING)))  -- 902,755
```

Right, matches UA's session count:

```sql
SUM(totals.visits)                                     -- 903,653
-- or, as a row key:
CONCAT(fullVisitorId, '-', CAST(visitStartTime AS STRING))
```

`totals.visits` is NULL for sessions with only non-interaction hits, so on other properties `COUNT(*)` can be higher than `SUM(totals.visits)`.

## 2. Money is stored times one million, and one revenue field is deprecated

Every money field (`totals.totalTransactionRevenue`, `hits.transaction.transactionRevenue`, `hits.product.productRevenue`, `productPrice`, ...) is the real value times 10^6. Divide by `1e6`.

`totals.transactionRevenue` is deprecated in favour of `totals.totalTransactionRevenue` ([UA export schema](https://support.google.com/analytics/answer/3437719)). They differ in the sample:

```sql
SUM(totals.transactionRevenue) / 1e6        -- 97,877.79   (deprecated)
SUM(totals.totalTransactionRevenue) / 1e6   -- 106,248.15
```

## 3. Unnesting product multiplies hit-level and session-level values

`hits` is repeated, and `hits.product` is repeated inside it. After `UNNEST(hits), UNNEST(h.product)`, every hit and session column repeats once per product.

Wrong:

```sql
-- 609,528.58
SELECT SUM(h.transaction.transactionRevenue) / 1e6
FROM `...ga_sessions_*`, UNNEST(hits) AS h, UNNEST(h.product) AS p
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
```

Right, sum each level at its own grain:

```sql
-- 106,320.15  (hit-level transaction revenue)
SELECT SUM(h.transaction.transactionRevenue) / 1e6
FROM `...ga_sessions_*`, UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
```

Use `p.productRevenue` only for product-level revenue.

## 4. Most product rows are impressions

Of 1,163,110 product rows in January, 1,080,825 (93%) are list impressions (`isImpression = TRUE`, `eCommerceAction.action_type = '0'`). Counting "products" without filtering counts every product that appeared in a list. Purchases are `action_type = '6'`. Note `action_type` is a STRING: `= 6` fails to compile, `= '6'` is right.

## 5. Bounces and new visits are 1 or NULL, never 0

`totals.bounces`, `totals.newVisits` and `totals.visits` hold 1 or NULL. `AVG(totals.bounces)` ignores the NULLs and returns 1.0. Bounce rate is `SUM(totals.bounces) / SUM(totals.visits)` (47.2% for Organic Search in January). Likewise `IF(totals.newVisits = 1, 'new', 'returning')`, not `= 0`.

## 6. date is the view's time zone; visitStartTime is UTC

`date` and the table suffix follow the reporting view's time zone. `visitStartTime` is POSIX seconds (UTC), and `hits.time` is milliseconds since the session started. In the sample, the first hit in `ga_sessions_20170101` is at 2017-01-01 08:00:23 UTC, so the view is on Pacific time. Group by `date` to match UA reports; convert with the view's zone if you compute days from `visitStartTime`.

## 7. Answer from totals when you can; hits are almost all the bytes

Dry runs for January 2017:

| columns | bytes scanned |
|---|---|
| `totals.visits` | 0.5 MB |
| `fullVisitorId, hits` | 338 MB |
| `SELECT *` over all 366 days | 5.77 GB |

Sessions, users, bounces, pageviews, transactions and revenue are all in `totals`. Only unnest `hits` for page, event or product detail. Always filter `_TABLE_SUFFIX`.

## 8. trafficSource is per session, unlike GA4

UA's `trafficSource` is the session's campaign source after UA's last non-direct click rules, so a returning direct visit can carry the previous campaign. `trafficSource.isTrueDirect` marks sessions that were actually direct. GA4's `traffic_source` is the user's first touch and never changes. Porting a UA "sessions by source" query to GA4's `traffic_source` silently changes the question. See `ua-to-ga4.md`.

## 9. Custom dimensions are index numbers

`customDimensions` (session or user scope) and `hits.customDimensions` (hit scope) are repeated `(index, value)` records. The index only means something in the property's admin settings, which are gone with UA's UI. Write down what each index meant before you lose access to anyone who knows. The sample has one session-level index, 4, holding a region (`North America`, `EMEA`, ...).

## 10. The public sample is not your property

- It covers one year, August 2016 to August 2017, at about 2,500 sessions a day.
- Some fields are redacted to `not available in demo dataset`: in January, 61.6% of sessions for `geoNetwork.city` and 100% for `device.browserVersion`.
- It has no `ga_sessions_intraday_*` tables. Real 360 exports did: intraday tables were replaced by the daily table, so never union both for the same date.
