-- test data setup: builds a small set of tables from the public ga4 sample
-- run once in a personal project. scans about 3.4 gib (free tier is 1 tib per month)
-- setup: dataset `test_data` must exist in the us region
-- expected result for the cost scripts:
--   used tables:   events_all, events_20210131, purchases
--   unused tables: events_20201101_unused, old_backup_unused (never queried after creation)

-- all 92 daily ga4 tables in one table, partitioned by day
create or replace table test_data.events_all
partition by event_day
as
select
  -- event_date is a string like 20201101, turn it into a real date
  parse_date('%Y%m%d', event_date) as event_day,
  *
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;

-- one daily table, kept unpartitioned like a raw ga4 export
create or replace table test_data.events_20210131
as
select *
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`;

-- a daily table nobody will query, should show up as unused
create or replace table test_data.events_20201101_unused
as
select *
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`;

-- a forgotten backup nobody will query, should show up as unused
create or replace table test_data.old_backup_unused
as
select *
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`;

-- small derived table with one row per purchase
create or replace table test_data.purchases
as
select
  parse_date('%Y%m%d', event_date) as event_day,
  user_pseudo_id,
  ecommerce.transaction_id as transaction_id,
  ecommerce.purchase_revenue_in_usd as revenue_usd
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name = 'purchase';

-- view on top of events_all, to test that view queries count against the base table
create or replace view test_data.v_daily_events
as
select
  event_day,
  event_name,
  count(*) as event_count
from test_data.events_all
group by event_day, event_name;
