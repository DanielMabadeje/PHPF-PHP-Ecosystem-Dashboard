# PHP ecosystem dashboard

A public, free-to-host dashboard answering questions about the PHP ecosystem, such as how much of the web runs on PHP applications. It is built for the PHP Foundation SIG research effort.

- **No server and no database.** The site is static files.
- **No paid services.** Data comes from public sources, the pipeline runs on GitHub Actions, and the site can be hosted on GitHub Pages or any web server.
- **Reproducible.** Every number on the dashboard comes from a SQL query in this repo, run against a stated crawl date.

## How it works

```
BigQuery (HTTP Archive public dataset)
        |  scripts/run_httparchive.sh   (GitHub Actions: "Refresh data")
        v
data/httparchive/<query>/<crawl-date>.csv     committed to the repo, opened as a PR
        |  scripts/combine.sh
        v
dashboard/sources/php/<table>.csv             merged per query (not committed)
        |  Evidence.dev (DuckDB at build time)
        v
dashboard/build/                              static HTML/JS  ->  GitHub Pages or any web host
```

Why it is built this way:
- **Queries run on a schedule, not per visitor.** The underlying data changes monthly or annually, and visitors never need a Google account or API key.
- **Each query returns a small aggregate**, so the repo stays small and the site is fast.
- **Results are committed as CSV through a PR.** Reviewers can see exactly how the numbers changed before they go live.

For what each query answers, which chart it feeds and what to be careful about, see [`extractions/README.md`](extractions/README.md).

## Repository layout

```
extractions/sql/        BigQuery SQL, one file per query (+ _preamble.sql shared declarations)
scripts/
  queries.sh            registry of queries: the one file to edit when adding a query
  run_httparchive.sh    runs the queries for a set of crawl dates (dry or real)
  combine.sh            merges per-date CSVs into one table per query for the dashboard
data/
  httparchive/<query>/  one CSV per crawl date (committed output of each refresh)
  metadata.json         when the last refresh ran, which crawl dates, scope
dashboard/              Evidence.dev project
  pages/                markdown pages with SQL + charts
  sources/php/          Evidence data source (generated CSVs land here)
.github/workflows/
  refresh.yml           "Refresh data": runs the queries, opens a PR with new CSVs
  deploy.yml            "Deploy dashboard": builds Evidence and publishes to GitHub Pages
```

## Setup

### Prerequisites
- Node.js 20+ and npm (for the dashboard)
- A GitHub repository (this one)
- A Google account (for BigQuery; the free tier is enough)
- Optional, for running queries locally: the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud` and `bq`)

### 1. Dashboard dependencies

```bash
cd dashboard
npm install
npm install -D typescript@5     # see Troubleshooting: npm may otherwise pick TypeScript 7
npm run sources
```

`npm run sources` should finish with "Done". It will say there is no data until you have run a refresh (step 3).

Evidence project files that must exist in `dashboard/` and be committed (including `package-lock.json`, because CI uses `npm ci`):

`package.json`: Evidence 39.x, with the `@evidence-dev/csv`, `@evidence-dev/duckdb` and `@evidence-dev/core-components` packages.

`evidence.plugins.yaml`:
```yaml
components:
  "@evidence-dev/core-components": {}
datasources:
  "@evidence-dev/csv": {}
  "@evidence-dev/duckdb": {}
```

`evidence.config.yaml` (replace the path with this repo's name; the path is case-sensitive; use `/` if hosting at a domain root):
```yaml
deployment:
  basePath: /PHPF-PHP-Ecosystem-Dashboard
```

### 2. Google Cloud (for the data refresh)

1. Create a project at <https://console.cloud.google.com> and make sure the BigQuery API is enabled. Note the **project ID** (e.g. `phpf-ecosystem-dashboard`), not the display name and not an email.
2. **IAM & Admin -> Service Accounts -> Create service account** (e.g. `github-actions-bigquery`) and give it the role **BigQuery Job User**. That is the only role needed: the HTTP Archive data is public.
3. Open the account, go to **Keys -> Add key -> Create new key -> JSON**, and download the key file.
4. In the GitHub repo, open **Settings -> Secrets and variables -> Actions**:
   - Secret `GCP_SA_KEY`: paste the **entire contents** of the JSON file.
   - Variable `GCP_PROJECT`: the project ID from step 1.
   - Variable `MAX_BYTES_BILLED` (recommended): a per-query ceiling in bytes, e.g. `20000000000` (20 GB). A query that would scan more fails without charging you.
   - Variable `CRAWL_DATES` (optional): space-separated crawl dates to use for scheduled runs.
5. Delete the downloaded JSON key from your computer.

If key creation is blocked by an organisation policy (`iam.disableServiceAccountKeyCreation`), you will need Workload Identity Federation instead; see the `google-github-actions/auth` documentation.

### 3. GitHub settings

- **Settings -> Actions -> General -> Workflow permissions:** "Read and write permissions", and tick **"Allow GitHub Actions to create and approve pull requests"**. Without it the refresh opens no PR.
- **Settings -> Pages -> Source:** GitHub Actions.
- **Pages and private repos:** on GitHub Free, Pages only works for **public** repositories. A private repo needs a paid plan, and even then the published site is public. Either make the repo public (all data is from public sources) or host the build elsewhere; see "Hosting".

### 4. First data refresh

1. **Actions -> Refresh data -> Run workflow**, leaving **dry_run ticked**. The log prints "will process N bytes" for every query and date. For the PHP applications queries this is roughly 4 to 8 GB each, about 100 GB for all five default dates, against the free 1 TB per month.
2. Run it again with **dry_run unticked**. It writes the CSVs to a branch `data-refresh` and opens a PR.
3. Review the PR. In `data/httparchive/totals/<date>.csv` check that `total_sites` is in the millions and that the percentage columns look plausible against the published Web Almanac figures.
4. Merge. The push to `main` triggers **Deploy dashboard**.

## Day-to-day use

### Refreshing the data
- **Manual:** Actions -> Refresh data -> Run workflow. Use the `crawl_dates` input to add or update specific crawls, e.g. `2026-06-01`. Existing dates are left untouched unless you re-run them.
- **Scheduled:** the workflow also runs quarterly (1st of Jan/Apr/Jul/Oct). Set the `CRAWL_DATES` repository variable to control which dates it queries.
- **Locally** (needs `gcloud auth login`, the `bq` CLI and a billing project):
  ```bash
  export GCP_PROJECT=<project-id>
  ./scripts/run_httparchive.sh dry                       # cost estimate only
  CRAWL_DATES="2026-06-01" ./scripts/run_httparchive.sh run
  ```

### Previewing the dashboard locally
```bash
./scripts/combine.sh          # needs data/ to exist (run or merge a refresh first)
cd dashboard
npm run sources
npm run dev                   # http://localhost:3000, with the base path from evidence.config.yaml
```

### Hosting
- **GitHub Pages (public repo):** handled by `deploy.yml` on every push to `main` that touches `dashboard/`, `data/` or `scripts/combine.sh`. Site URL: `https://<user>.github.io/<repo>/`.
- **Any static host (Netlify, Cloudflare Pages, nginx, an S3 bucket, the foundation's own server):** run `./scripts/combine.sh` then `cd dashboard && npm ci && npm run sources && npm run build` and upload `dashboard/build/`. Set `basePath` in `evidence.config.yaml` to match where it is served from.

## Adding or changing queries

### Add a new BigQuery query (same HTTP Archive source)

1. **Write the SQL** in `extractions/sql/<name>.sql`.
   - Filter on `date = @crawl_date`, `client = 'mobile'` and `is_root_page`, as in the existing queries, so the same query can run for every crawl date.
   - Include `@crawl_date AS crawl_date` as the first output column. The dashboard uses it as the time axis.
   - Return a **small aggregate** (tens to hundreds of rows), never raw rows. Add a `LIMIT` where the output could grow.
   - **Write a single statement.** Do not use `DECLARE`, `CREATE TEMP ...` or multiple statements. BigQuery treats those as a *script*, and `bq` does not hand back a script's final `SELECT` as the CSV we need. Use CTEs (`WITH ... AS`) for lists and intermediate steps instead. The runner rejects any output whose first column is not `crawl_date`, so this fails loudly rather than committing a broken file.
   - If you need the shared PHP application list, register the query with preamble flag `1` (see next step). The preamble is a `WITH params AS (...)` clause, so your query either starts with `, name AS (` to continue the WITH, or starts directly with `SELECT`. Reference the lists by joining `params` in your `FROM` (`FROM ..., params`) and using `params.php_apps`, `params.not_a_platform` or `params.builder_commerce`. See `totals.sql` and `platforms.sql`.
   - Otherwise (flag `0`) the file must be complete on its own; see `families.sql`.
2. **Register it** with one line in `scripts/queries.sh`:
   ```bash
   "php_versions|0|php_versions"
   #  ^ SQL file name  ^ uses _preamble.sql (1/0)  ^ table name pages will query
   ```
3. **Estimate the cost:** run the workflow with dry_run on. Check the bytes for the new query and raise `MAX_BYTES_BILLED` if needed.
4. **Run the refresh** (dry_run off), review the PR, merge.
5. **Add charts:** in a page under `dashboard/pages/`, query the table as `php.<table>`:
   ````markdown
   ```sql versions
   select * from php.php_versions order by crawl_date
   ```

   <LineChart data={versions} x=crawl_date y=share />
   ````
   Preview with `./scripts/combine.sh && cd dashboard && npm run dev`.
6. **Explain every chart.** Each section of a page should say, in plain language: *the question it answers*, *what the chart shows and how to read it*, and *caveats* (what it does not mean, known detection gaps, double counting). A heading alone, such as "WordPress family", does not tell a reader what they are looking at. `dashboard/pages/php-applications.md` is the pattern to copy.
7. Commit the SQL, `queries.sh` and page. Data and deploy follow from the merged PR.

Notes:
- Queries must be written so that the same file works for every crawl date. If a query needs a different shape per date, split it into two queries.
- Technology names come from the Wappalyzer definitions used by HTTP Archive and change between crawls. State this on the chart if it affects the trend.
- Keep scripts compatible with bash 3.2 (macOS default): no associative arrays.

### Add a new crawl date
Re-run **Refresh data** with `crawl_dates` set to the new date(s). New CSVs are added alongside the existing ones, and charts pick up the new point automatically.

### Add a different kind of source (GitHub API, Packagist, ecosyste.ms)
These do not go through BigQuery, so they need their own script and workflow:
1. Write a script under `extractions/` that outputs a **small aggregated CSV** (for sampling studies, publish the aggregation, not thousands of raw series), and keep API keys in repository secrets.
2. Write results to `data/<source>/<name>.csv` and record collection date and sampling details in `data/metadata.json`.
3. Add a workflow like `refresh.yml` (manual and/or scheduled, opening a PR). Sampling scripts should seed their randomness and store the seed so results can be reproduced.
4. Add a second Evidence source folder (e.g. `dashboard/sources/github/`) with `connection.yaml` of `type: csv`, and a page that queries it.

## Branding

The header shows the title and repository link set in `dashboard/pages/+layout.svelte`. Without that file Evidence shows its own logo. To use an image logo instead, put the file in `dashboard/static/` and pass it to the layout, for example `logo="/my-logo.png"` (or `lightLogo` / `darkLogo` for separate light and dark versions). An image overrides the text title. The browser tab title comes from the `title:` line at the top of each page.

## Data conventions

- The queries cover **mobile client, root pages only**. Counts are sites, not pages.
- Every chart should state its **source, crawl date and known limitations** next to the chart.
- HTTP Archive technology detection can differ from other sources. The `PHP` flag and named-application detections do not always agree; the dashboard shows both.
- All output CSVs are reviewed in a PR before merging. Treat a sharp jump between crawls as something to explain before publishing.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `npm install` fails with `ERESOLVE ... typescript@7` | npm picked TypeScript 7, which Evidence's `svelte2tsx` does not accept. Run `npm install -D typescript@5`. Fallback: `echo "legacy-peer-deps=true" > dashboard/.npmrc` and commit it. |
| `evidence: command not found` | The install failed. Fix the install first. |
| `bq` crashes with `RecursionError` in `get_flag_suggestions` | The SQL was passed to `bq` as an argument and its leading `--` comment was parsed as a flag. `run_httparchive.sh` pipes SQL on stdin; make sure you are on a version that does. |
| Dashboard charts show `Binder Error: Referenced column "crawl_date" not found`, with a column named like `WITH sites AS (` | The committed CSV does not contain the query result. This happened when queries used `DECLARE`, which makes BigQuery run them as scripts. Rewrite the query as a single statement (CTEs, no `DECLARE`), re-run the refresh and merge the new data PR. The runner now rejects such output. |
| Workflow authenticates but queries fail on the project | `GCP_PROJECT` must be the **project ID** (`phpf-ecosystem-dashboard`), not the service account email. |
| Queries stop with "bytes billed exceeds limit" | `MAX_BYTES_BILLED` is lower than the query's scan size. Raise it after checking a dry run. |
| Refresh succeeds but no PR appears | Enable "Allow GitHub Actions to create and approve pull requests" in Settings -> Actions -> General. The `data-refresh` branch already exists; open the PR from it manually. |
| `combine.sh`: "no data for ..." | No refresh has been merged yet, or a new query in `queries.sh` has not been run. Run Refresh data first. |
| Deploy step fails with `HttpError: Not Found` / "Ensure GitHub Pages has been enabled" | Pages is not enabled, or the repo is private on a plan without Pages. Make the repo public (or upgrade), set Pages source to GitHub Actions, and re-run Deploy dashboard. |
| Charts render empty or the page 404s under Pages | `basePath` in `evidence.config.yaml` does not match the repo name (case-sensitive). |
| Build fails on a chart component | Check the Evidence docs for the component's props. `npm run dev` shows the error with line numbers. |

## Cost and quotas

- BigQuery: the free tier covers 1 TB of scanned data per month. A full refresh of the default five crawl dates is roughly 100 GB. Always dry-run a new query first, and keep `MAX_BYTES_BILLED` set.
- GitHub Actions: free for public repositories. Private repositories have a monthly minutes allowance on the Free plan; a refresh takes a few minutes.
- Hosting: GitHub Pages is free for public repositories. Any static host works.

## Roadmap

- [ ] Licence declared in `LICENSE` vs `composer.json` (GitHub API, quarterly)
- [ ] First two years of a Packagist package: publish weekly percentiles per adoption grade rather than raw series
- [ ] Derive the PHP application list from Wappalyzer `implies`/`requires` rather than a hand-written list