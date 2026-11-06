---
name: firebase-app
description: Write correct BigQuery SQL against the Firebase Analytics / GA4 for apps export (analytics_<id>.events_* with platform IOS or ANDROID). Use when the user asks about app analytics in BigQuery - DAU, sessions, installs (first_open), day-N retention, app versions, crashes, uninstalls, LTV, in-app purchases, A/B test variants - or about a Firebase project's analytics dataset.
---

# Firebase / GA4 for apps

Same events schema as GA4 web. Read the `ga4` skill's rules first (`../ga4/SKILL.md`, install both packs): `_TABLE_SUFFIX` filtering, one scalar subquery per param, type-switching params, time zones, no backfill. Every query in `queries/` here was run against `firebase-public-project.analytics_153293282` with results recorded in the header.

## Rules for apps

1. **Split by `platform` and `app_info.id`.** One dataset can hold several apps; iOS and Android send different events.
2. **Sessions:** `user_pseudo_id` + `ga_session_id` where the param exists. Exports from before December 2018 lack it, so count `session_start` events. Do not rebuild sessions from event-time gaps.
3. **Cohorts come from `first_open`**, never from a user's first event in the export. `first_open` includes reinstalls and will not match store install counts.
4. **`user_ltv.revenue` is cumulative and repeated on every event.** Take `MAX` per user, never `SUM` over events (1,000x too high in the sample).
5. **Coalesce custom params** (`COALESCE(value.double_value, value.int_value)`); in the sample `level`, `score`, `value` and `time` switch type, and the int-typed events are missing other params.
6. **`app_remove` is Android only.** Don't report iOS uninstalls from it.
7. **Crashes:** `app_exception` with `fatal = 1`, and only if Crashlytics is integrated.
8. **Day-N retention cells that the data cannot reach yet are NULL, not 0.**

## Files

- `schema.md`: app-specific columns, automatic events, session params, user properties.
- `gotchas.md`: the app-specific traps with wrong vs right SQL and sample numbers.
- `queries/`: 12 tested queries:
  - `01` DAU by platform, `02` sessions and engagement time, `03` first opens by source
  - `04` D1/D7/D30 retention by install week, `05` app version adoption, `06` crash rate by version
  - `07` LTV by install cohort, `08` level funnel (custom events), `09` top screens
  - `10` uninstalls by user age, `11` country and device, `12` A/B test variants

The public dataset is capped at 50,000 events per day and redacts device models; treat its numbers as shape, not benchmarks.
