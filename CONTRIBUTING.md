# Contributing

Fixes, new queries and new packs are welcome. The one rule: everything has to be checkable.

## Adding or changing a query

1. Put it in `<pack>/queries/NN-short-name.sql`.
2. Start the file with the header the other queries use:
   - `-- dataset: <the public dataset>`
   - what the query answers and any trap it avoids
   - `-- Verified: ran on <dataset> on <YYYY-MM-DD>, returned N rows.` and the first few rows of the actual result
3. Filter date-sharded tables with `_TABLE_SUFFIX` and keep the scan under 2 GB (`bq query --dry_run` first).
4. Run `BQ_PROJECT=<your project> SHOW=1 ./verify.sh <your file>` and paste the real output into the header.

## Adding a gotcha

Each gotcha needs a wrong and a right SQL snippet where that applies, and either a number measured on the sample or a link to the vendor's documentation. If neither exists, leave it out.

## Adding a pack

A pack needs a public dataset that anyone can query, plus `SKILL.md` (with `name` matching the folder name and a `description` that says when to use it), `schema.md`, `gotchas.md` and 10 to 15 queries. Keep `SKILL.md` short; detail goes in the other files.

## Style

Plain and specific. Name the column, the number and the source. No emoji.

Open a pull request with the `verify.sh` summary line for the pack you touched.
