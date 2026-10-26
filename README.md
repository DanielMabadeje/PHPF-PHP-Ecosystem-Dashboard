# PHP ecosystem dashboard

Free to run, free to host. No server, no database.

```
BigQuery (HTTP Archive) --bq--> data/httparchive/<query>/<date>.csv   (committed)
                                      |
                              scripts/combine.sh
                                      |
                           Evidence.dev (DuckDB at build time)
                                      |
                            static site -> GitHub Pages (or any web server)
```

## One-time setup

1. Create the Evidence project base (gives you a correct package.json and lockfile):
   ```
   npx degit evidence-dev/template dashboard-base
   cp dashboard-base/package.json dashboard-base/evidence.config.yaml dashboard-base/evidence.plugins.yaml dashboard/
   rm -rf dashboard-base
   ```
   Then in `dashboard/`:
   - make sure `evidence.plugins.yaml` lists the CSV source plugin: `@evidence-dev/csv: {}`
     (add `@evidence-dev/csv` to the dependencies if the template doesn't have it)
   - set the Pages base path in `evidence.config.yaml`:
     ```yaml
     deployment:
       basePath: /<repo-name>
     ```
   - `npm install` and commit `package-lock.json` (the deploy workflow uses `npm ci`)
2. GitHub repo settings: Pages -> Source: **GitHub Actions**.
3. Refresh needs a Google Cloud project (the BigQuery sandbox is enough, no card):
   - service account with `BigQuery Job User`
   - repo secret `GCP_SA_KEY` (JSON key), repo variable `GCP_PROJECT`
   - optional variables: `MAX_BYTES_BILLED`, `CRAWL_DATES`

## Refreshing data

1. Actions -> **Refresh data** -> run with `dry_run = true`. The log shows the bytes each query would scan. Set `MAX_BYTES_BILLED` above the largest.
2. Run again with `dry_run = false`. A PR with the new CSVs opens. Merge it and the dashboard redeploys.

Locally: `./scripts/run_httparchive.sh dry` or `run` (needs `gcloud auth login` and the `bq` CLI).

## Local preview

```
./scripts/combine.sh
cd dashboard && npm run sources && npm run dev
```

## Self-hosting

`npm run build` in `dashboard/` produces static files in `dashboard/build/`. Copy them to any web server.

## Roadmap

- [ ] licence-file-vs-composer extraction (GitHub API, quarterly)
- [ ] package-first-two-years extraction (publish weekly percentiles per grade, not raw series)
