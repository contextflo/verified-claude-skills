# GA4 BigQuery export: gotchas

Every number below comes from `bigquery-public-data.ga4_obfuscated_sample_ecommerce`, December 2020 (`_TABLE_SUFFIX BETWEEN '20201201' AND '20201231'`) unless stated, run on 2026-11-05. Claims about how the export behaves cite Google's docs; anything we could not support was left out.

## 1. event_params is an array, and values switch type

`event_params` is `REPEATED RECORD<key, value<string_value, int_value, float_value, double_value>>`. Each param fills one of the value columns, and the same key can use different columns on different events. In this sample:

| key | string_value | int_value | double_value |
|---|---|---|---|
| session_engaged | 3,682,921 events (`'1'`, `'0'`) | 313,391 events (`1`) | 0 |
| value | 0 | 1,832 | 3,410 |
| tax | 0 | 455 | 4,787 |
| transaction_id | 4,786 | 456 | 0 |

(Counts over the full Nov 2020 to Jan 2021 range. Both types appear on the same days, so this is not a one-time tracking change.)

Wrong, reads one column and silently drops the rest:

```sql
-- 72,239 engaged sessions
COUNT(DISTINCT IF(
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1',
  session_key, NULL))
```

Right, coalesce across the columns the key uses:

```sql
-- 117,633 engaged sessions (63% more)
COUNT(DISTINCT IF(
  (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
   FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1',
  session_key, NULL))
```

Same trap with revenue. Summing the `value` param from `double_value` only gives 110,042.55 for December purchases; `COALESCE(value.double_value, value.int_value)` gives 160,559.55. Prefer the typed column `ecommerce.purchase_revenue` (160,555.00) when it exists.

Before using a param, check which columns it fills:

```sql
SELECT ep.key,
  COUNTIF(ep.value.string_value IS NOT NULL) AS s,
  COUNTIF(ep.value.int_value IS NOT NULL) AS i,
  COUNTIF(ep.value.double_value IS NOT NULL) AS d,
  COUNTIF(ep.value.float_value IS NOT NULL) AS f
FROM `project.analytics_XXXX.events_*`, UNNEST(event_params) AS ep
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'
GROUP BY ep.key
```

## 2. Use a scalar subquery per param, not a cross join

Wrong, the comma join creates one row per param, so any count over the result is inflated and filtering on two keys at once returns nothing:

```sql
SELECT COUNT(*)
FROM `...events_*`, UNNEST(event_params) AS ep
WHERE ep.key = 'page_location' AND ep.key = 'ga_session_id'   -- always 0 rows
```

Right, one subquery per param keeps one row per event:

```sql
SELECT
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS page_location,
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id
FROM `...events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
```

## 3. A session is user_pseudo_id + ga_session_id

`ga_session_id` is the session start time in seconds, so different users collide on it.

Wrong:

```sql
-- 129,376 "sessions"
COUNT(DISTINCT (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))
```

Right:

```sql
-- 133,368 sessions
COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(
  (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)))
```

Counting `session_start` events is also off: 131,836 in December, because some sessions have no `session_start` row in the export.

## 4. Unnesting items repeats the order total

`items` is a repeated record. After `UNNEST(items)`, event-level columns repeat once per item.

Wrong:

```sql
-- 711,567.00, 4.4x the real number
SELECT SUM(ecommerce.purchase_revenue)
FROM `...events_*`, UNNEST(items)
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231' AND event_name = 'purchase'
```

Right: sum `ecommerce.purchase_revenue` without unnesting (160,555.00), or sum `item.item_revenue` after unnesting when you want product-level revenue.

## 5. Purchases repeat; de-duplicate by transaction_id

December has 2,434 purchase events but 2,311 distinct `ecommerce.transaction_id` values, and 94 of those events have `transaction_id = '(not set)'`. Count orders with `COUNT(DISTINCT transaction_id)` and take one revenue per id. Do not merge all `(not set)` rows into one order. See `queries/10-revenue-daily.sql`.

## 6. Filter on _TABLE_SUFFIX, not event_date

The export is date-sharded tables (`events_YYYYMMDD`), not a partitioned table. Only `_TABLE_SUFFIX` prunes shards. Dry runs for the same week, two columns:

| filter | bytes scanned |
|---|---|
| `WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201207'` | 15.0 MB |
| `WHERE event_date BETWEEN '20201201' AND '20201207'` | 187.7 MB (all 92 tables) |
| `SELECT *` over `events_*`, no filter | 3.58 GB |

On a real property with years of data the gap is the difference between cents and a large bill. Select only the columns you need: `event_params` is most of the bytes.

`events_*` also matches `events_intraday_*` tables. To read only daily tables use `_TABLE_SUFFIX BETWEEN '20240101' AND '20241231'` (intraday suffixes start with `intraday_`, which sorts after digits and so falls outside that range).

## 7. Intraday tables are temporary and overlap the daily table

With streaming export on, today's data goes to `events_intraday_YYYYMMDD`. Google: it is "an internal staging table" and "this table is deleted when `events_YYYYMMDD` is complete" ([BigQuery Export schema](https://support.google.com/analytics/answer/9358801)). Do not union intraday with the daily table for the same date, and do not build reports that depend on the intraday table staying around. Use the daily tables for anything older than today. Some columns are empty in intraday tables: `traffic_source` and `is_active_user` are only populated in the daily tables ([schema](https://support.google.com/analytics/answer/7029846)). (The public sample has no intraday tables.)

## 8. Daily tables change after the fact, and days can go missing

- Google "will update daily tables for up to 2 calendar days, plus today" for late events such as Measurement Protocol or Firebase SDK bundles, and "on occasion" after that window ([schema doc](https://support.google.com/analytics/answer/9358801)). A dashboard that materializes yesterday's numbers once will drift from the source.
- Standard (non-360) properties have a daily export limit of 1 million events. A property that keeps exceeding it has its daily export paused, and "previous days' exports will not be reprocessed" ([set up export](https://support.google.com/analytics/answer/9823238)). Billing problems and deleted service accounts also stop exports, and those days cannot be re-exported.
- A missing day looks exactly like a traffic drop. Run `queries/15-export-health.sql` before reading a trend.

## 9. event_timestamp is UTC; event_date and table dates are in the property time zone

`event_timestamp` is microseconds since epoch, UTC. Table shards and `event_date` follow the property's time zone (Google: exports "are governed by the time zone of the Analytics property"). The GA4 UI reports in the property time zone.

Wrong, buckets by UTC day:

```sql
DATE(TIMESTAMP_MICROS(event_timestamp)) AS day
```

Right, use `event_date`, or convert with the property's zone:

```sql
PARSE_DATE('%Y%m%d', event_date) AS day
-- or
DATE(TIMESTAMP_MICROS(event_timestamp), 'America/Los_Angeles') AS day
```

In this sample `event_date` equals the UTC date for all 1,612,725 December events, so the sample property appears to be on UTC and the bug stays hidden. Converting the same events to `America/Los_Angeles` moves 551,416 of them (34%) to a different day, which is roughly what happens to a US property queried with UTC days. Also note a property time zone change shifts the export window for a day.

## 10. Your numbers will not match the GA4 UI exactly, and that is expected

- **Estimates in the UI.** GA4 reports count users and sessions with HyperLogLog++ estimation; BigQuery gives exact counts, so "you may notice small differences" ([Google](https://support.google.com/analytics/answer/9191807)).
- **Thresholding.** Reports and explorations may withhold rows that include demographics or search queries when there are too few users ([Google](https://support.google.com/analytics/answer/9383630)). The export does not threshold.
- **Google signals.** "Analytics doesn't export data from Google signals to BigQuery", so per-user counts can differ (same page).
- **Consent mode modeling.** With behavioral modeling, report users and sessions include modeled data; BigQuery export does not support modeled data ([Google](https://support.google.com/analytics/answer/11161109)). Cookieless pings are present in the export as raw events, so the export and the modeled report count different things.
- **Reporting identity.** The UI dedupes users by the property's reporting identity (Blended, Observed, Device-based). `user_pseudo_id` is per device/browser. Use `user_id` where your site sets it.
- **Definitions.** GA4 "active users" counts users with engagement; `COUNT(DISTINCT user_pseudo_id)` counts anyone with an event. Current exports have an `is_active_user` column (daily tables only) for this. Channel groupings and attribution in the UI are computed, not stored in this sample.

Aim for a few percent agreement on users and sessions. Revenue and event counts should be close to exact.

## 11. GA4 retention vs the export: no backfill

- GA4's data retention setting (2 or 14 months for standard properties, longer for 360) "only affects explorations and funnel reports", not standard reports ([Google](https://support.google.com/analytics/answer/7667196)). Event-level history beyond that lives only in BigQuery.
- The export starts when you link the property. Google documents data flowing "within 24 hours" of linking and offers no way to export earlier dates ([set up export](https://support.google.com/analytics/answer/9823238)). If you need history, link now; every month you wait is gone from event-level data.
- When asked for data before the first table, say it does not exist in the export rather than returning zeros. Check `MIN(_TABLE_SUFFIX)` first.

## 12. Storage: physical billing is often much cheaper for these tables

Event tables compress well. For `events_20201201` in the sample, BigQuery reports 64.9 MB logical vs 3.46 MB physical (5.3%). The dataset storage billing model defaults to logical (uncompressed) bytes; switching the export dataset to physical bills compressed bytes. Caveats from [BigQuery docs](https://docs.cloud.google.com/bigquery/docs/datasets-intro): time travel and fail-safe storage are billed separately under physical, a change takes 24 hours to apply, and you must wait 14 days before changing again. Physical rates per GB are higher, so compare with `INFORMATION_SCHEMA.TABLE_STORAGE` on your own project before switching. This is storage cost only; query cost depends on bytes scanned.

## 13. The public sample is obfuscated

Things that are true of `ga4_obfuscated_sample_ecommerce` but not of your export:

- Many dimension values are replaced with `<Other>` or `(data deleted)`. In December, 19,119 users have first-touch source `<Other>`, and 6,551 have `(data deleted)`.
- `gclid`, `gclsrc` and `dclid` keys exist but every value column is NULL.
- `user_id` is never set, and `privacy_info` is empty.
- `user_properties` has `key` typed INTEGER in the sample schema; in real exports it is STRING.
- Newer columns are missing: `collected_traffic_source`, `session_traffic_source_last_click`, `is_active_user`, `batch_event_index` and others. Check your own schema before assuming any of them exist.

Queries in this pack work on a real export, but results on the sample should not be read as realistic benchmarks.
