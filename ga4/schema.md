# GA4 BigQuery export: schema

One dataset per property, named `analytics_<property_id>`. One row per event. Google's full reference: [BigQuery Export schema](https://support.google.com/analytics/answer/7029846).

## Tables

| table | what it is |
|---|---|
| `events_YYYYMMDD` | One table per day (property time zone). Final after about 2 days, can still change later. |
| `events_intraday_YYYYMMDD` | Streaming export only. Today's events, deleted when the daily table is complete. |
| `pseudonymous_users_YYYYMMDD`, `users_YYYYMMDD` | Optional user-level export. Not in the public sample. |

Query `events_*` with `_TABLE_SUFFIX BETWEEN 'YYYYMMDD' AND 'YYYYMMDD'`. The tables are date-sharded, not partitioned.

## Flat event columns

| column | type | notes |
|---|---|---|
| `event_date` | STRING `YYYYMMDD` | Property time zone. Same as the table suffix for daily tables. |
| `event_timestamp` | INT64 | Microseconds since epoch, UTC. `TIMESTAMP_MICROS(event_timestamp)`. |
| `event_name` | STRING | `page_view`, `session_start`, `first_visit`, `purchase`, ... |
| `user_pseudo_id` | STRING | Device/browser id (the `_ga` cookie on web). Not a person. |
| `user_id` | STRING | Only if your site sets it. NULL in the sample. |
| `user_first_touch_timestamp` | INT64 | UTC micros of the user's first visit. |
| `stream_id`, `platform` | | `WEB`, `IOS`, `ANDROID`. |
| `event_value_in_usd` | FLOAT | Usually NULL; prefer `ecommerce.*`. |
| `is_active_user` | BOOL | Current exports only, daily tables only. Not in the sample. |
| `batch_event_index`, `batch_page_id`, `batch_ordering_id` | INT64 | Current exports only. Order of events sent in one batch. |

## Repeated records (need UNNEST)

### event_params

`ARRAY<STRUCT<key STRING, value STRUCT<string_value STRING, int_value INT64, float_value FLOAT64, double_value FLOAT64>>>`

Read one param per scalar subquery:

```sql
(SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id
```

Params seen in the sample and the column they use:

| key | column | notes |
|---|---|---|
| `ga_session_id` | int | Session start, seconds. Unique only with `user_pseudo_id`. |
| `ga_session_number` | int | 1 for the user's first session. |
| `page_location` | string | Full URL including query string. |
| `page_title`, `page_referrer` | string | |
| `session_engaged` | string AND int | `'1'`/`'0'` as string on most events, `1` as int on others. |
| `engagement_time_msec` | int | Sum per session for engagement time. |
| `engaged_session_event` | int | |
| `entrances` | int | 1 on the first page_view of a session. |
| `source`, `medium`, `campaign`, `term` | string | Session acquisition, only on some events of the session. |
| `value`, `tax` | int OR double | Varies per event. Coalesce. |
| `transaction_id` | string OR int | Use `ecommerce.transaction_id` instead. |
| `currency`, `payment_type`, `shipping_tier`, `coupon` | string | |
| `percent_scrolled` | int | On `scroll`. |
| `search_term` | string | On `view_search_results`. |
| `gclid`, `dclid`, `gclsrc` | | All value columns NULL in the sample. |

Custom params you send appear here with the same structure.

### user_properties

Same shape as `event_params` plus `value.set_timestamp_micros`. In real exports `key` is STRING. The sample's schema types it INTEGER and it holds no useful data.

### items

One entry per product on ecommerce events (`view_item`, `add_to_cart`, `begin_checkout`, `purchase`, ...). Key fields: `item_id`, `item_name`, `item_brand`, `item_variant`, `item_category` to `item_category5`, `price`, `quantity`, `item_revenue`, `item_refund`, `coupon`, `item_list_name`, `promotion_name` (each money field also has an `_in_usd` version). Current exports also have `item_params`, a repeated key/value record per item.

```sql
SELECT item.item_name, SUM(item.item_revenue)
FROM `...events_*`, UNNEST(items) AS item
WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231' AND event_name = 'purchase'
GROUP BY 1
```

## Non-repeated records (dot access, no UNNEST)

| record | fields |
|---|---|
| `traffic_source` | `source`, `medium`, `name`: the user's FIRST acquisition. Same on every event of that user. Empty in intraday tables. |
| `collected_traffic_source` | Current exports: `manual_source`, `manual_medium`, `manual_campaign_name`, `gclid`, ... as collected on the event. Not in the sample. |
| `session_traffic_source_last_click` | Current exports: GA4's session attribution. Not in the sample. |
| `ecommerce` | `transaction_id`, `purchase_revenue`, `total_item_quantity`, `unique_items`, `shipping_value`, `tax_value`, `refund_value` (and `_in_usd`). |
| `device` | `category` (desktop/mobile/tablet), `operating_system`, `language`, `web_info.browser`, `mobile_brand_name`, ... |
| `geo` | `continent`, `sub_continent`, `country`, `region`, `city`, `metro`. |
| `app_info` | App streams only. See the firebase-app pack. |
| `user_ltv` | `revenue`, `currency`. |
| `privacy_info` | `analytics_storage`, `ads_storage`, `uses_transient_token` (consent state). |

## Public sample

`bigquery-public-data.ga4_obfuscated_sample_ecommerce`: Google Merchandise Store, 92 daily tables from `events_20201101` to `events_20210131`, about 4.3M events, no intraday tables, values partly obfuscated. December 2020 alone is 1,612,725 events and 133,368 sessions.
