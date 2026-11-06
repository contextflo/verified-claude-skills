# Firebase / GA4 for apps: schema

Same `events_YYYYMMDD` tables and event schema as GA4 web: see [`../ga4/schema.md`](../ga4/schema.md) for `event_params`, `user_properties`, `items`, `ecommerce`, `traffic_source`, `device`, `geo` and the table layout. This file lists what is specific to app streams.

## Columns that matter more for apps

| column | notes |
|---|---|
| `platform` | `IOS` or `ANDROID`. Always split or filter. |
| `app_info.id` | Bundle id / package name. One dataset can contain several apps. |
| `app_info.version` | App version that sent the event. |
| `app_info.install_source` | e.g. `com.android.vending`, `iTunes`. NULL is common. |
| `app_info.firebase_app_id` | Firebase app id. |
| `user_pseudo_id` | App instance id. |
| `user_first_touch_timestamp` | UTC micros of the user's first open. |
| `user_ltv.revenue`, `user_ltv.currency` | Cumulative per user, repeated on every event. Take MAX per user. |
| `device.category` | `mobile`, `tablet`. |
| `device.mobile_brand_name`, `mobile_model_name`, `operating_system_version` | Redacted in the public demo. |
| `device.language`, `device.time_zone_offset_seconds` | Device locale and UTC offset, useful for the user's local hour. |
| `device.advertising_id`, `is_limited_ad_tracking` | Ad identifiers, often empty. |
| `traffic_source` | First-touch acquisition (`google-play / organic`, `(direct) / (none)`, campaign links). |

## Automatically collected app events

| event | meaning |
|---|---|
| `first_open` | First launch after install or reinstall. |
| `session_start` | SDK-defined session start. |
| `user_engagement` | App in foreground; carries `engagement_time_msec`. |
| `screen_view` | Carries `firebase_screen_class`, `firebase_screen_id`, `firebase_previous_class`, ... |
| `app_update`, `os_update` | Carry `previous_app_version` / `previous_os_version`. |
| `app_remove` | Uninstall, Android only. |
| `app_exception` | Crash or exception (with Crashlytics); `fatal` param. |
| `in_app_purchase` | Store purchase; `event_value_in_usd`, `product_id`, `price`, `currency`. |
| `firebase_campaign`, `dynamic_link_*` | Campaign and deep link attribution. |

Custom events (`level_start`, `post_score`, `spend_virtual_currency`, ...) carry custom params in `event_params`.

## Session params

Current app exports carry `ga_session_id` (int) and `ga_session_number` (int) in `event_params`, the same as web. Exports from before December 2018, including the public Flood-It dataset, do not.

## User properties

`user_properties` (repeated key/value, plus `set_timestamp_micros`) holds properties your app sets and some Firebase ones:

| key | notes |
|---|---|
| `first_open_time` | int, epoch millis of first open. |
| `firebase_exp_<N>` | A/B Testing variant index, string. |
| `firebase_last_notification` | Last FCM notification id. |
| `_ltv_<CURRENCY>` | Lifetime value per currency, int. |

Each row carries the value as of that event, so take one value per user (latest, or as of a date).

## Public sample

`firebase-public-project.analytics_153293282`: Flood-It, iOS (`com.google.flood2`) and Android (`com.labpixies.flood`), 114 daily tables from `events_20180612` to `events_20181003`, exactly 50,000 events per day, 15,175 users, 2018 schema.
