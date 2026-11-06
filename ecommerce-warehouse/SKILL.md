---
name: ecommerce-warehouse
description: Write correct SQL for ecommerce metrics in a warehouse - net revenue, AOV, margin, returns, LTV, cohort repeat rate, new vs repeat revenue, RFM - on orders / order items / products / customers tables. Use when the user asks about store or DTC metrics from warehouse tables (thelook_ecommerce, a Shopify/WooCommerce sync, or similar), not from GA4.
---

# Ecommerce warehouse metrics

Tested on `bigquery-public-data.thelook_ecommerce`, a synthetic Shopify-style store. It is not Shopify's schema: map table and column names to the user's own data before running anything (`gotchas.md` ends with a mapping table). Every query in `queries/` ran on the sample and its result is in the header.

## Rules

1. **Define revenue explicitly.** Gross booked, net of cancels, net of returns, delivered: pick one, say which, and exclude statuses in SQL. In the sample, gross is 33% higher than net of cancels and returns.
2. **One order date.** Use the order's own timestamp for every metric. Item and order timestamps disagree (23% of orders fall on another day in the sample).
3. **Orders come from the orders table**, not analytics purchase events (one event per item in the sample, and in real stores they miss and duplicate orders).
4. **Know the grain.** One row per unit vs per line with a quantity changes what `COUNT(*)` means.
5. **Fixed windows for LTV and repeat rate** (90 / 365 days after first order). Cohorts too young for the window return NULL.
6. **"New customer" is decided over all history**, then filtered to the reporting period.
7. **Return rate divides by items that could have been returned** (delivered or returned), not all items.
8. **Pin "as of" dates** instead of `CURRENT_DATE()`.

## Files

- `schema.md`: tables, grain, joins, columns, what is missing.
- `gotchas.md`: the traps with wrong vs right SQL and sample numbers, plus a Shopify-style mapping.
- `queries/`: 13 tested queries:
  - `01` monthly orders, net revenue, AOV; `02` gross vs net by status; `03` margin by category
  - `04` returns by category; `05` LTV at 90/365 days; `06` cohort repeat rate; `07` new vs repeat revenue
  - `08` top products; `09` acquisition source; `10` fulfillment times; `11` web funnel from events
  - `12` revenue by country; `13` RFM segments

Sample numbers drift as Google regenerates the dataset, and the synthetic data has no discounts, tax or shipping. Use it to check SQL shape, not to benchmark.
