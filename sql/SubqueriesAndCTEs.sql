Find all users who have watched only top-rated movies (above 4.5 rating).
SELECT 
	wh.user_id,
	m.title,
	wh.watch_duration_minutes,
	m.rating
FROM Users u 
LEFT JOIN Watch_History wh 
	ON u.user_id = wh.user_id
LEFT JOIN Movies m
	ON wh.movie_id = m.movie_id
WHERE m.rating > 4.5;


-- Using a CTE, find users whose total watch time is below the average for their plan.
WITH UserWatchTime AS (
	SELECT 
		s.user_id,
		p.plan_id,
		SUM(wh.watch_duration_minutes) AS total_watch_time
	FROM Subscriptions s 
	LEFT JOIN Plans p
		ON s.plan_id = p.plan_id
	LEFT JOIN Watch_History wh 
		ON s.user_id =wh.user_id
	GROUP BY s.user_id, p.plan_id
),
PlanAverage AS (
	SELECT 
		plan_id,
		AVG(total_watch_time * 1.0) AS avg_watch_time
	FROM UserWatchTime
	GROUP BY plan_id
)
SELECT 
	u.user_id,
	u.plan_id,
	u.total_watch_time,
	p.avg_watch_time
FROM UserWatchTime u 
LEFT JOIN PlanAverage p 
	ON u.plan_id = p.plan_id
WHERE u.total_watch_time < p.avg_watch_time;


-- For each month, find the most-watched movie and its total watch count. */
WITH MonthylyWatchCounts AS (
	SELECT
		DATENAME(MONTH, wh.watch_date) AS watch_month,
		m.title,
		COUNT(wh.watch_duration_minutes) AS total_watch_count
	FROM Watch_History wh 
	LEFT JOIN Movies m 
		ON wh.movie_id = m.movie_id
	GROUP BY DATENAME(MONTH, wh.watch_date), m.title
),
RankedMovies AS (
	SELECT 
		watch_month,
		title,
		total_watch_count,
		RANK() OVER (PARTITION BY watch_month ORDER BY total_watch_count DESC) AS rk
	FROM MonthylyWatchCounts
)
SELECT TOP 10
	watch_month,
	title AS most_watched_movie,
	total_watch_count
FROM RankedMovies
WHERE rk = 1
ORDER BY watch_month;