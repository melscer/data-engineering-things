/* Store the dates_active array in a more efficient format:
 * 1 if the user was active on that day, 0 if the user was not active
 * first bit corresponds to the oldest date (2023-01-03)
 * see writeup here: https://www.linkedin.com/pulse/datelist-int-efficient-data-structure-user-growth-max-sung/
 */

with users as (
-- this has a list of dates where the user_id was active
	select * from users_cumulated
	where date = DATE('2023-01-03')
),

series as (
	select *
	from GENERATE_SERIES(DATE('2023-01-01'), DATE('2023-01-03'), interval '1 DAY') as series_date
),

placeholder_ints as (
select
	*, 
		case WHEN
		dates_active @> ARRAY[DATE(series_date)] -- true if series_date is in dates_active
		-- BIGINT uses 64 bits total, with 1 bit reserved for the sign.
		-- so we are limited to storing 63 days of history
		-- this implementation differs slightly from ZW's
		-- usually at facebook they only needed 28-30 days for a month, so casting to BIT(32) was sufficient
		then cast(POW(2, (date - DATE(series_date))) as BIGINT) 
		else 0  -- if it was not active that day
	 end as placeholder_int_value
from users cross join series
--where user_id = '12615598167083900000'
)

select
	user_id,
	SUM(placeholder_int_value) as placeholder_int_sum,
	-- BIT size should be at least equal to the length of series_date not to cause overflow
	CAST(cast(SUM(placeholder_int_value) as BIGINT) as BIT(3)) as history
from placeholder_ints
group by user_id