# Universal Analytics (UA 360) export: schema

One dataset per view, one table per day: `ga_sessions_YYYYMMDD` (plus `ga_sessions_intraday_YYYYMMDD` while the export was live). One row per session. Google's reference: [UA BigQuery Export schema](https://support.google.com/analytics/answer/3437719).

## Session columns

| column | type | notes |
|---|---|---|
| `fullVisitorId` | STRING | Browser/device id. Users = distinct values. |
| `visitorId` | INT64 | Legacy, usually NULL. Use `fullVisitorId`. |
| `userId` | STRING | Only if the site set it. |
| `visitId` | INT64 | Unique per user only; repeats across a midnight split. |
| `visitNumber` | INT64 | 1 = first session. |
| `visitStartTime` | INT64 | POSIX seconds, UTC. With `fullVisitorId`, a safe session key. |
| `date` | STRING `YYYYMMDD` | View time zone. |
| `channelGrouping` | STRING | Default Channel Grouping. |
| `socialEngagementType` | STRING | |

## totals (one record per session)

| field | notes |
|---|---|
| `visits` | 1 or NULL (NULL = only non-interaction hits). |
| `hits`, `pageviews`, `screenviews` | Counts in the session. |
| `bounces` | 1 or NULL. |
| `newVisits` | 1 or NULL. |
| `timeOnSite` | Seconds. NULL for bounces. |
| `transactions` | Count. |
| `totalTransactionRevenue` | Micros (x 10^6). Use this one. |
| `transactionRevenue` | Micros. Deprecated. |
| `sessionQualityDim`, `timeOnScreen`, `uniqueScreenviews` | Less used. |

## trafficSource (session level)

`source`, `medium`, `campaign`, `keyword`, `adContent`, `referralPath`, `isTrueDirect`, `campaignCode`, and `adwordsClickInfo.*` (`gclId`, `campaignId`, `adGroupId`, ...).

## device, geoNetwork

`device.deviceCategory`, `browser`, `operatingSystem`, `isMobile`, `language`, ... and `geoNetwork.continent`, `subContinent`, `country`, `region`, `metro`, `city`, `networkDomain`.

## customDimensions (repeated)

`ARRAY<STRUCT<index INT64, value STRING>>`. Session- and user-scoped custom dimensions. Read with:

```sql
(SELECT value FROM UNNEST(customDimensions) WHERE index = 4)
```

## hits (repeated, one per hit)

| field | notes |
|---|---|
| `hitNumber` | Order within the session, from 1. |
| `time` | Milliseconds since `visitStartTime`. |
| `hour`, `minute` | View time zone. |
| `type` | `PAGE`, `EVENT`, `TRANSACTION`, `ITEM`, `SOCIAL`, `EXCEPTION`, `TIMING`, ... |
| `isInteraction`, `isEntrance`, `isExit` | BOOL. |
| `page.pagePath`, `page.hostname`, `page.pageTitle` | |
| `eventInfo.eventCategory`, `eventAction`, `eventLabel`, `eventValue` | For `type = 'EVENT'`. |
| `transaction.transactionId`, `transactionRevenue`, `transactionTax`, `transactionShipping` | Micros. |
| `eCommerceAction.action_type` | STRING code: '0' none/impression, '1' list click, '2' detail view, '3' add to cart, '4' remove, '5' checkout, '6' purchase, '7' refund, '8' checkout options. |
| `eCommerceAction.step` | Checkout step. |
| `customDimensions`, `customMetrics` | Hit-scoped, repeated (index, value). |
| `promotion` | Repeated, internal promotions. |
| `product` | Repeated, see below. |

### hits.product (repeated inside hits)

`productSKU`, `v2ProductName`, `v2ProductCategory`, `productVariant`, `productBrand`, `productPrice` (micros), `productQuantity`, `productRevenue` (micros), `isImpression`, `isClick`, `productListName`, `productListPosition`, `customDimensions`, `customMetrics`.

```sql
FROM `...ga_sessions_*`, UNNEST(hits) AS h, UNNEST(h.product) AS p
```

## Public sample

`bigquery-public-data.google_analytics_sample`: Google Merchandise Store, 366 daily tables from `ga_sessions_20160801` to `ga_sessions_20170801`, 903,653 sessions, 714,167 users, no intraday tables, partly redacted. Tables are cut on Pacific time.
