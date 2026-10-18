-- usage generator: a mix of cheap and wasteful queries to create job history
-- each statement is run as its own job by run_tests.ps1
-- expected result for the cost scripts:
--   statements 1-3 are one query pattern (same text, different dates)
--   statement 4 is the most expensive (full scan, no partition filter)
--   statement 8 repeats statement 7, so it should be a cache hit

-- 1: partition filter, cheap
select event_name, count(*) as event_count
from test_data.events_all
where event_day = date '2020-11-05'
group by event_name;

-- 2: same pattern as 1, different date
select event_name, count(*) as event_count
from test_data.events_all
where event_day = date '2020-12-05'
group by event_name;

-- 3: same pattern as 1, different date
select event_name, count(*) as event_count
from test_data.events_all
where event_day = date '2021-01-05'
group by event_name;

-- 4: wasteful, reads every column of every partition
select *
from test_data.events_all
where event_name = 'purchase'
limit 1000;

-- 5: query through the view, should count against events_all
select event_day, sum(event_count) as events
from test_data.v_daily_events
group by event_day
order by event_day;

-- 6: join of two tables, cost is counted on both in script 03
select
  p.event_day,
  count(distinct p.transaction_id) as purchases,
  round(sum(p.revenue_usd), 2) as revenue_usd,
  count(distinct e.user_pseudo_id) as active_users
from test_data.purchases as p
join test_data.events_20210131 as e
  on p.user_pseudo_id = e.user_pseudo_id
group by p.event_day;

-- 7: small aggregate on the unpartitioned daily table
select device.category as device_category, count(*) as event_count
from test_data.events_20210131
group by device_category;

-- 8: exact repeat of 7, should be served from cache for free
select device.category as device_category, count(*) as event_count
from test_data.events_20210131
group by device_category;
