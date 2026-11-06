# Firebase / GA4 for apps: gotchas

App exports use the same `events_*` schema as GA4 web, so every rule in [`../ga4/gotchas.md`](../ga4/gotchas.md) applies: `_TABLE_SUFFIX` filtering, one scalar subquery per param, type-switching params, intraday vs daily tables, time zones, no backfill, UI mismatch. This file covers what is different for apps.

Numbers come from `firebase-public-project.analytics_153293282` (Flood-It, iOS and Android, 2018-06-12 to 2018-10-03), run on 2026-11-05. August 2018 unless stated.

## 1. Old app exports have no ga_session_id

Google added `ga_session_id` and `ga_session_number` to app events in December 2018 ([Firebase blog](https://firebase.blog/posts/2018/12/new-changes-sessions-user-engagement)). This dataset predates that, and so does any app export you have from before then.

- On data with `ga_session_id`: session = `user_pseudo_id` + `ga_session_id`, same as web.
- On data without it: count `session_start` events (19,577 in August).

Wrong, rebuilding sessions from 30-minute event gaps:

```sql
-- 22,396 "sessions", 14% more than the SDK's own session_start count
COUNTIF(prev_ts IS NULL OR event_timestamp - prev_ts > 30 * 60 * 1000000)
```

The SDK decides sessions from foreground and background time on the device, which event gaps in the export do not show. Use `session_start`.

## 2. user_ltv is a running total repeated on every event

`user_ltv.revenue` is the user's lifetime revenue as of that event, copied onto every event they send.

Wrong:

```sql
-- 252,871.08
SELECT SUM(user_ltv.revenue) FROM `...events_*`
```

Right, one value per user:

```sql
-- 220.96
SELECT SUM(ltv) FROM (
  SELECT user_pseudo_id, MAX(user_ltv.revenue) AS ltv
  FROM `...events_*` GROUP BY user_pseudo_id)
```

That is over 1,000x. The `_ltv_<CURRENCY>` user properties (`_ltv_USD`, `_ltv_JPY`, ...) behave the same way.

## 3. Custom params switch type, and the switch can hide other params

Game params in this dataset arrive as int on some events and double on others: `level`, `score`, `value`, `time`, and even the automatic `firebase_screen_id`. Worse, the int-typed `level` events carry no `level_name` at all.

| event (August) | level as double | level as int | has level_name |
|---|---|---|---|
| level_start | 19,364 | 986 | only the double ones |

Wrong, loses 986 of 20,350 level starts (4.8%):

```sql
(SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'level_name') AS level
```

Right:

```sql
CAST((SELECT COALESCE(value.double_value, value.int_value)
      FROM UNNEST(event_params) WHERE key = 'level') AS INT64) AS level
```

Run the type-check query from the ga4 gotchas on any custom param before using it.

## 4. Cohorts must come from first_open, not first event seen

The dataset has 15,175 users but only 4,319 of them have a `first_open` in range. The rest installed before the export window. Treating each user's first event in the export as their install date makes all of them "new" in week one and wrecks retention curves. Define cohorts by `first_open` (see `queries/04-day-n-retention.sql`).

`first_open` fires "the first time a user launches an app after installing or re-installing it" ([Google](https://support.google.com/analytics/answer/9234069)), so it counts first opens including reinstalls, not store installs. Store install counts come from App Store Connect and Play Console and will not match.

## 5. app_remove is Android only

Google lists `app_remove` as "Android only" (same page). All 1,532 uninstalling users in `queries/10-uninstalls-by-age.sql` are Android. Never report iOS churn from `app_remove`; use inactivity (no events for N days) for both platforms if you need one definition.

## 6. One dataset can hold several apps

A Firebase project exports every linked app into one `analytics_<id>` dataset. Here iOS (`com.google.flood2`) and Android (`com.labpixies.flood`) share it. Split by `platform` and `app_info.id`, or filter to one, before computing any rate. iOS and Android also differ in what they send (screen class names, uninstalls), so a blended number hides that.

## 7. app_exception needs Crashlytics, and fatal is a param

`app_exception` is sent when the app integrates Firebase Crashlytics (same Google page). Filter on the `fatal` param (int) rather than assuming every `app_exception` is a crash. In this dataset all 5,156 `app_exception` events have `fatal = 1`; in yours, check the distribution first. If your export has no `app_exception` rows, use Crashlytics' own BigQuery export.

## 8. This public dataset is a capped demo

- Every daily table has exactly 50,000 events (114 days, min = max = 50,000). Volumes are not real, and users are partially observed, which pushes retention and LTV numbers down.
- `device.mobile_brand_name`, `mobile_model_name` and `operating_system_version` read `not available in demo dataset`.
- Only 27 `in_app_purchase` events and 146 users with LTV above zero across the whole dataset.
- The schema is the 2018 version: no `ga_session_id`, no `is_active_user`, no `collected_traffic_source`, no `items` or `ecommerce` records. Check your own schema first.

The queries run on a current app export (swap session counting for `ga_session_id` where noted). The numbers from this dataset are not benchmarks.
