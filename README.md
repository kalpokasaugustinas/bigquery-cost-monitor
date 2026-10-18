# BigQuery cost monitor

One HTML page that shows who and what drives your BigQuery bill, and where to cut.

**[Open the live page](https://kalpokasaugustinas.github.io/bigquery-cost-monitor/)** and click **sample data** to see a report for a made-up company.

## What you get

| Section | Answers |
|---|---|
| Cost by user and source | Who spends the most, and through what: Data Studio, Looker, Power BI, Tableau, Pigment, scheduled queries, dbt or people |
| Most expensive queries | Which query patterns cost the most |
| Cost by table | Which tables drive query cost |
| Unused tables | Which tables older than 90 days nobody used in that time, and their storage cost |

## How to use

1. Open the [live page](https://kalpokasaugustinas.github.io/bigquery-cost-monitor/), or download `bigquery-cost-report.html` and open it in your browser.
2. Optionally enter your region and projects on the page (empty means automatic). Click **Copy script**, paste it into the BigQuery console and click **Run**.
   - The console shows several steps. Use the result of the last step.
3. Click **Save results → CSV (local file)** and drop the file onto the page.

The report runs fully in your browser, and the downloaded file also works offline. Your data is never uploaded anywhere: the live page is a static file, with no server, no tracking and no cookies.

## Region

BigQuery keeps job history per region, and one run covers one region. The script uses the region it runs in, which is your project's default.

- **Report is empty, or your data is in another region?** Enter your region in the **Region** field on the page, for example `EU` or `europe-west1`, and copy the script again.
- **Data in several regions?** Run the script once per region and drop all files onto the page. It merges them into one report.
- **Several projects?** List them in the **Projects** field on the page, comma separated (same region only).

## Good to know

- The script only reads metadata (job history and table storage). It doesn't read your table data or change anything.
- It costs a few cents to run on most projects.
- To see everyone's queries, not just your own, you need `bigquery.jobs.listAll` (for example the BigQuery Resource Viewer role).
- Costs are estimates: on-demand pricing ($6.25 per TiB) and logical storage at US list prices. Free tier, discounts and regional prices are not included.
- On capacity pricing (editions, reserved slots) the report shows the share of queries that ran on a reservation; their dollar figures are on-demand equivalents, not your bill.
- Cost by table splits multi-table queries by table size, so the column adds up to total query cost. Unused tables flag snapshots (dbt or "snapshot" in the name).
