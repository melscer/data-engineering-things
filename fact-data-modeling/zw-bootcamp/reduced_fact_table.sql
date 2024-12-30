/* Goal: create a reduced fact table
 * Update logic: daily merge. The array is incremented each day by 1 value 
 * via a full outer join with yesterday's array
 * The first element in the array corresponds to the 1st of the month
 */

create table array_metrics (
	user_id numeric,
	month_start DATE,
	metric_name text,
	metric_array REAL[],
	primary key (user_id, month_start, metric_name)
);

delete table array_metrics;

insert into array_metrics

with daily_aggregate as (
	select 
		user_id,
		DATE(event_time) as date,
		cast(count(1) as real) as num_site_hits
	from events
	where DATE(event_time) = DATE('2023-01-04') -- this is the date that changes
	and user_id is not null
	group by
		user_id,
		date
),

	yesterday_array as (
		select *
		from array_metrics
		where month_start = DATE('2023-01-01') -- on the first run this will be null
	)

select 
	COALESCE(da.user_id, ya.user_id) as user_id,
	COALESCE(ya.month_start, DATE_TRUNC('month', da.date)) as month_start,
	'site_hits' as metric_name,
	case
		when ya.metric_array is not null
			then ya.metric_array || ARRAY[coalesce(da.num_site_hits, 0)::REAL]
		when ya.metric_array is null
			-- coalesce to 0 because 
			then ARRAY_FILL(0 :: REAL, array[coalesce(da.date - DATE(DATE_TRUNC('month', da.date)), 0)]) || 
				 ARRAY[coalesce(da.num_site_hits, 0)]
	end as metric_array
from daily_aggregate da
	full outer join yesterday_array ya
	on da.user_id = ya.user_id
	
on conflict (user_id, month_start, metric_name)
do 
	update set metric_array = EXCLUDED.metric_array;

-- CHECK that you only have 1 value for the cardinality of the array
select cardinality(metric_array), COUNT(1)
from array_metrics
group by  cardinality(metric_array);

select * from array_metrics;

with agg as (
	select
	metric_name,
	month_start,
	ARRAY[SUM(metric_array[1]), SUM(metric_array[2]), SUM(metric_array[3])] as summed_array
	from array_metrics
	group by metric_name, month_start
)

-- example of aggregation query
select
	metric_name,
	month_start + CAST(cast(index - 1 as TEXT) || 'day' as interval) as date,
	elem as value
from agg
cross join UNNEST(agg.summed_array)
	-- it's very fast because we only explode the array AFTER everything is aggregated
	with ordinality as a(elem, index) -- this will return the index as well!
	