# Ecommerce warehouse: gotchas

Numbers come from `bigquery-public-data.thelook_ecommerce`, run on 2026-11-05. All-time figures cover orders from January 2019 to 2026-11-01.

**This is a synthetic, Shopify-style sample, not Shopify's schema.** Google generates `thelook_ecommerce` and keeps adding rows; the `order_items` table we queried was last modified on 2026-10-29 and holds orders up to 2026-11-01. Your store's data (Shopify, WooCommerce, BigCommerce, a custom backend, or a Fivetran/Airbyte sync of any of them) will have different tables and columns. The traps below are about ecommerce data in general; the SQL shows them on thelook. See the mapping at the end.

## 1. Gross revenue includes cancelled and returned items

| | revenue (all time) |
|---|---|
| `SUM(sale_price)` over every order item | 10,769,445 |
| excluding `Cancelled` and `Returned` | 8,098,918 |

45,116 of 180,746 items (25%) are cancelled or returned. Wrong:

```sql
SELECT SUM(sale_price) FROM `bigquery-public-data.thelook_ecommerce.order_items`
```

Right, say which statuses count:

```sql
SELECT SUM(IF(status NOT IN ('Cancelled', 'Returned'), sale_price, 0))
FROM `bigquery-public-data.thelook_ecommerce.order_items`
```

`Processing` and `Shipped` items can still be returned, so revenue for recent weeks keeps falling for a while after you report it. Agree on a definition (booked, net of cancels, net of returns, delivered) and put it in the query name.

## 2. The same order has two different dates

`orders.created_at` and `order_items.created_at` disagree for 124,448 of 124,452 orders. The item timestamp is usually 1.5 to 4 hours earlier. 28,961 orders (23%) land on a different day and 1,381 in a different month depending on which you use.

Wrong, mixes the two:

```sql
-- daily revenue keyed on the item timestamp, daily orders keyed on the order timestamp
```

Right: pick one order date for everything. These queries use `orders.created_at` and join items to it.

In real stores the same thing happens with created vs processed vs paid timestamps, and with time zones: Shopify reports in the shop's time zone while warehouse syncs usually store UTC.

## 3. Web events are not orders

The `events` table logs one `purchase` event per order item: 180,746 purchase events against 124,452 orders. Counting purchase events counts units. Count orders from `orders`, and use events only for sessions and funnels (`queries/11-web-funnel-events.sql`). On real stores, analytics purchase events also miss orders (blockers, consent, offline and POS) and double-fire on reloads, so the order table is the source of truth for revenue.

## 4. One row is one unit

`order_items` has no quantity column: each row is one physical unit (`orders.num_of_item` matches the row count for every order). `COUNT(*)` is units. Shopify-style line items have a `quantity`; there, units are `SUM(quantity)` and `COUNT(*)` is lines.

## 5. inventory_items.sold_at is always NULL

All 180,746 inventory items attached to an order item have `sold_at IS NULL`. Do not use it to find sold units or sale dates; use `order_items`. Columns that look authoritative and are never filled are common in real exports too: check `COUNTIF(col IS NULL)` before relying on one.

## 6. Return rate needs the right denominator

Dividing returns by all items understates the rate, because cancelled, processing and shipped items could not have been returned yet. `queries/04-returns-by-category.sql` divides by items that were delivered or returned. Recent periods still look better than they will end up, since late returns have not happened yet.

## 7. LTV and repeat rate need fixed windows

"Revenue per customer so far" favours old cohorts: a 2019 customer has had seven years to buy again. Measure every cohort over the same window after its first order (90 days, 365 days) and return NULL for cohorts that have not had the full window yet (`queries/05`, `queries/06`).

## 8. "New customer" must be decided over all history

If you find each customer's first order inside the reporting window only, everyone who orders in January looks new. Rank orders over all history, then filter to the window (`queries/07-new-vs-repeat-revenue.sql`).

## 9. Two different traffic sources

`users.traffic_source` is the source at signup, with values `Search`, `Organic`, `Facebook`, `Email`, `Display`. `events.traffic_source` is per event, with a different value set (`Email`, `Adwords`, `Facebook`, `YouTube`, `Organic`). They answer different questions (acquisition vs visit) and cannot be joined on value.

## 10. Pin "as of" dates

The dataset keeps growing, and `CURRENT_DATE()` in a recency or "last 30 days" query changes the answer daily. Pin the date in a `params` CTE (`queries/13-rfm-segments.sql`). This also means the sample numbers recorded in our query headers will drift as Google regenerates the data; `verify.sh` checks that queries run and return rows, not that numbers stay fixed.

## 11. The synthetic data is too clean

No discounts (`sale_price` always equals `products.retail_price`), no tax, shipping or fees, unit cost always equals product cost, and acquisition sources perform almost identically. Real margin queries need discounts, refunds, shipping, payment fees and COGS changes over time. Treat results here as a check that the SQL is shaped right, not as benchmarks.

## Mapping to a Shopify-style store

Rough equivalents, for porting these queries. Check the actual table and column names in your sync (Shopify's API, Fivetran and Airbyte all name them differently).

| concept | thelook | typical Shopify-style source |
|---|---|---|
| order | `orders` | orders |
| order line | `order_items` (one row per unit) | order line items (with `quantity`) |
| line price | `order_items.sale_price` | line item price, minus line discounts |
| order status | `orders.status`, `order_items.status` | separate financial status (paid, refunded, ...) and fulfillment status |
| returns | `status = 'Returned'`, `returned_at` | refunds and refund line items, often in their own tables |
| cancellations | `status = 'Cancelled'` | cancelled timestamp on the order |
| unit cost | `inventory_items.cost` | inventory item cost (often missing or not historical) |
| discounts, tax, shipping | not present | order-level and line-level discount, tax and shipping fields |
| customer | `users` | customers |
| acquisition source | `users.traffic_source` | not stored by default; comes from analytics, UTMs or an attribution tool |
