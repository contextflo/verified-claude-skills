# Same question in UA vs GA4

For porting `ga_sessions_*` queries to the GA4 `events_*` export. The UA column refers to queries in this pack, the GA4 column to the `ga4` pack. The two models are different: UA stores one row per session with hits nested inside, GA4 stores one row per event with sessions implied by a param. Expect numbers to move after a port even when both queries are right.

| question | UA 360 (`ga_sessions_*`) | GA4 (`events_*`) | what changes |
|---|---|---|---|
| Sessions | `SUM(totals.visits)` | `COUNT(DISTINCT user_pseudo_id + ga_session_id)` | GA4 does not split sessions at midnight, and has no non-interaction hits. |
| Users | `COUNT(DISTINCT fullVisitorId)` | `COUNT(DISTINCT user_pseudo_id)` | Both per browser. GA4 UI "active users" counts engaged users only. |
| New users | `totals.newVisits = 1` | `event_name = 'first_visit'` (web), `'first_open'` (app) | |
| Session key | `fullVisitorId + visitStartTime` | `user_pseudo_id + ga_session_id` | `visitId` and `ga_session_id` are both only unique per user. |
| Pageviews | `UNNEST(hits)`, `type = 'PAGE'` | `event_name = 'page_view'` | |
| Page path | `hits.page.pagePath` | `page_location` param (full URL, strip host and query) | |
| Landing page | `hits.isEntrance = TRUE` | first `page_view` of the session, or `entrances` param = 1 | |
| Events | `hits.eventInfo.eventCategory / eventAction / eventLabel` | `event_name` plus `event_params` | GA4 has no category/action/label; teams usually map action to `event_name`. |
| Bounce rate | `SUM(totals.bounces) / SUM(totals.visits)` | `1 - engaged_sessions / sessions` | Different definitions. GA4 bounce = not engaged (under 10 s, 1 page, no key event). Do not compare directly. |
| Time on site | `totals.timeOnSite` (seconds) | `SUM(engagement_time_msec)` per session | UA measured time between hits; GA4 measures foreground time. |
| Source / medium (session) | `trafficSource.source / medium / campaign` | `source / medium / campaign` params, or `session_traffic_source_last_click` | UA is session-level. |
| Source / medium (first touch) | not stored per user | `traffic_source.source / medium / name` | GA4's `traffic_source` is first touch. A common porting bug. |
| Channel | `channelGrouping` | not in the export (sample); compute from source/medium | |
| Transactions | `SUM(totals.transactions)` | `COUNT(DISTINCT ecommerce.transaction_id)` on `purchase` | De-duplicate in GA4. |
| Revenue | `SUM(totals.totalTransactionRevenue) / 1e6` | `SUM(ecommerce.purchase_revenue)` | UA is micros; GA4 is the real value. |
| Product revenue | `UNNEST(hits), UNNEST(h.product)`, `action_type = '6'`, `productRevenue / 1e6` | `UNNEST(items)` on `purchase`, `item_revenue` | One level of nesting in GA4, two in UA. |
| Funnel steps | `hits.eCommerceAction.action_type` '2', '3', '5', '6' | `view_item`, `add_to_cart`, `begin_checkout`, `purchase` | |
| Custom dimension | `customDimensions` / `hits.customDimensions` by `index` | `event_params` / `user_properties` by `key` | Index numbers become names. |
| Device / geo | `device.deviceCategory`, `geoNetwork.country` | `device.category`, `geo.country` | |
| Day | `date` (view time zone) | `event_date` (property time zone) | Check both zones match before comparing a cutover period. |
| Table filter | `_TABLE_SUFFIX` on `ga_sessions_*` | `_TABLE_SUFFIX` on `events_*` | Same rule. |
| Intraday | `ga_sessions_intraday_*` | `events_intraday_*` | Both replaced by the daily table. |

To run one model over both, reshape UA into GA4-style event rows (`queries/13-flatten-to-ga4-shape.sql`) and union with GA4 events, keeping a `source_system` column so a reader can see where the cutover is.
