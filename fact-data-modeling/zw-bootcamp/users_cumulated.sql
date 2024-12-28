create table if not exists users_cumulated (
	user_id TEXT, -- too big for BIGINT
	dates_active DATE[], -- list of dates in the past where the user was active
	date DATE,
	primary key (user_id, date)
	
);

--  drop table users_cumulated;
insert into users_cumulated (

	WITH yesterday AS (
		SELECT
			*
		FROM users_cumulated
		WHERE date = DATE('2023-01-02') -- first data in events table is on 2023-01-01
		),
	
	today AS (
		SELECT
			cast(user_id AS text) AS user_id,
			DATE(CAST(event_time AS TIMESTAMP)) AS today_date
		FROM events
		WHERE
			DATE(CAST(event_time AS TIMESTAMP)) = DATE('2023-01-03')
			AND user_id is not NULL -- data problem, remove
		GROUP BY 
			user_id,
			DATE(CAST(event_time as TIMESTAMP)) 		
		)
	
	SELECT
		COALESCE(t.user_id, y.user_id) AS user_id,
		CASE
			WHEN y.dates_active IS NULL
				THEN ARRAY[t.today_date]
			WHEN t.user_id IS NULL THEN y.dates_active
			ELSE ARRAY[t.today_date]  || y.dates_active -- most recent date in the front
		END AS dates_active,
		-- notice how we din't just hardcode a date here (!). We want idempotency
		COALESCE(t.today_date, y.date + interval '1 day') as date
	FROM today t 
	FULL OUTER JOIN yesterday y
		ON t.user_id = y.user_id
);
-- check expected result: 3 rows for this user id
SELECT * FROM users_cumulated WHERE user_id = '16899212529494500000';