# Verified Claude skill packs

Claude skills that teach Claude how to query a specific data source correctly: the schema, the traps, and a set of working queries. Point Claude at your GA4 export and it already knows that `ga_session_id` is not a session, that `event_params` values switch type, and that filtering on `event_date` scans every table you have.

Verified by Contextflo, not affiliated with or endorsed by Anthropic.

## What "verified" means here

Most skill and prompt collections are untested tips. Every query in these packs ships with:

- the public dataset it ran on,
- the date it ran,
- how many rows it returned, and the first few rows of the result,

in the header of the `.sql` file. `verify.sh` re-runs every query against BigQuery and fails on any error or empty result, so you can check the claim yourself, or point it at your own dataset.

Claims in `gotchas.md` are either measured on the sample (with the number) or cite Google's documentation. Anything we could not support was left out.

## Packs

| pack | data source | tested on | queries |
|---|---|---|---|
| [`ga4/`](ga4/) | GA4 BigQuery export (web) | `bigquery-public-data.ga4_obfuscated_sample_ecommerce` | 15 |
| [`firebase-app/`](firebase-app/) | GA4 for apps / Firebase Analytics export | `firebase-public-project.analytics_153293282` | 12 |
| [`universal-analytics/`](universal-analytics/) | Universal Analytics 360 export (`ga_sessions_*`), plus a UA to GA4 mapping | `bigquery-public-data.google_analytics_sample` | 13 |
| [`ecommerce-warehouse/`](ecommerce-warehouse/) | Orders / order items / customers warehouse tables (Shopify-style, not Shopify's schema) | `bigquery-public-data.thelook_ecommerce` | 13 |

Each pack has:

- `SKILL.md`: when to use it and the rules that matter most. Claude reads this first.
- `schema.md`: tables, columns, nested and repeated fields.
- `gotchas.md`: each trap with wrong and right SQL and the numbers from the sample.
- `queries/`: tested queries to start from.

## Install

**Claude Code:** copy a pack folder into `~/.claude/skills/` (all projects) or `.claude/skills/` in your project.

```bash
git clone https://github.com/contextflo/verified-claude-skills
cp -r verified-claude-skills/ga4 ~/.claude/skills/
```

**claude.ai:** zip a pack folder (keep the folder name, it must match the skill name) and upload it under Customize > Skills > Create skill > Upload a skill. Code execution needs to be on.

```bash
cd verified-claude-skills && zip -r ga4.zip ga4
```

The `firebase-app` pack builds on `ga4`; install both.

## Run the checks

You need the `bq` CLI (Google Cloud SDK), `jq`, and a GCP project to run the jobs in. Reading the public datasets counts against BigQuery's free query tier; each query is kept small and `verify.sh` caps every query at 2 GB scanned.

```bash
BQ_PROJECT=your-gcp-project ./verify.sh              # all packs
BQ_PROJECT=your-gcp-project ./verify.sh ga4          # one pack
BQ_PROJECT=your-gcp-project SHOW=1 ./verify.sh ga4   # also print the first rows

# run a pack against your own data instead of the public sample
BQ_PROJECT=your-gcp-project DATASET=your-project.analytics_123456789 ./verify.sh ga4
```

Queries reference the public dataset by name, so they also paste straight into the BigQuery console. `DATASET` swaps the dataset named in each file's `-- dataset:` header for yours. Date ranges in the queries match the sample, so change them for your data.

## Caveats

- The public samples are old (2016 to 2021 for the analytics packs) and partly obfuscated. Newer export columns are missing, and the sample numbers are not benchmarks. The packs say where your export will differ.
- `thelook_ecommerce` is synthetic and Google keeps regenerating it, so the numbers in those query headers will drift. `verify.sh` checks the queries run and return rows, not that the numbers stay fixed.
- A skill is a set of files. It knows the data source, not your business: which revenue definition your team uses, which events are your conversions, what broke in your tracking last March.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). New packs need a public dataset to verify against.

---

Want your team's own skills and context kept current, shared and permissioned? That is what Contextflo does: https://contextflo.com/?utm_source=github&utm_campaign=verified-skills

## License

MIT. See [LICENSE](LICENSE).
