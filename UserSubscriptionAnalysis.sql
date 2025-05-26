-- List all users who signed up in the same month and year as their first subscription start date.
SELECT 
	u.user_id,
	u.full_name,
	u.signup_date,
	s.start_date
FROM users u 
LEFT JOIN Subscriptions s 
	ON u.user_id = s.user_id
WHERE 
    YEAR(u.signup_date) = YEAR(s.start_date)
    AND MONTH(u.signup_date) = MONTH(s.start_date)
ORDER BY u.signup_date DESC;


-- Which users are on the most expensive plan currently active? List their full name, plan name, and price.
SELECT
	u.full_name,
	p.plan_name,
	p.price,
	u.signup_date
FROM Users u 
LEFT JOIN Subscriptions s
	ON u.user_id = s.user_id
LEFT JOIN Plans p 
	ON s.plan_id = p.plan_id
WHERE u.signup_date = '2025'
ORDER BY p.price DESC;

/* Find users who have had more than one subscription (renewed).
SELECT 
	u.full_name,
	COUNT(s.start_date) AS renewed_subscription
FROM Users u 
LEFT JOIN Subscriptions s 
	ON u.user_id = s.user_id
GROUP BY u.full_name
HAVING COUNT(u.signup_date) > 1; */

-- -- Find users who have had more than one subscription (renewed).
SELECT *
FROM(
	SELECT 
		u.user_id,
		u.full_name,
		s.start_date,
		COUNT(s.start_date) OVER (PARTITION BY u.full_name) AS renewed_subscriptions
	FROM Users u 
	LEFT JOIN Subscriptions s
		ON u.user_id = s.user_id
) t
WHERE t.renewed_subscriptions > 1
ORDER BY t.start_date DESC;


-- Which users have active subscriptions that will expire in the next 10 days?
SELECT 
	u.user_id,
	u.full_name,
	s.start_date,
	s.end_date,
	CASE 
		WHEN s.end_date >= GETDATE() THEN 'Active' 
		ELSE 'Expired'
	END AS subscriptions_status
FROM Users u 
LEFT JOIN Subscriptions s 
	ON u.user_id = s.user_id
WHERE s.end_date BETWEEN GETDATE() AND DATEADD(DAY, 10, GETDATE())
ORDER BY s.end_date;


-- Which plan has the highest average subscription duration (in days)?
SELECT 
	p.plan_name,
	AVG(DATEDIFF(DAY, s.start_date, s.end_date)) AS avg_subscription_days
FROM Plans p 
LEFT JOIN Subscriptions s 
	ON p.plan_id = s.plan_id
GROUP BY p.plan_name
ORDER BY avg_subscription_days DESC;


-- Find users who have never watched any movies.
SELECT 
	u.user_id,
	u.full_name,
	m.title,
	wh.watch_date
FROM Users u 
LEFT JOIN Watch_History wh 
	ON u.user_id = wh.user_id
LEFT JOIN Movies m 
	ON wh.movie_id = m.movie_id
WHERE wh.user_id IS NULL;

-- List users who watched at least 5 movies in a single day.
SELECT 
	u.user_id,
	w.watch_date,
	COUNT(m.movie_id) AS movies_watched
FROM Users u 
LEFT JOIN Watch_History w 
	ON u.user_id = w.user_id
LEFT JOIN Movies m 
	ON w.movie_id = m.movie_id
GROUP BY u.user_id, w.watch_date
HAVING COUNT(m.movie_id) >= 5;

-- Who are the top 5 users with the longest total watch time?
SELECT TOP 5
	u.full_name,
	COUNT(w.watch_duration_minutes) AS total_watch_time
FROM Users u 
LEFT JOIN Watch_History w 
	ON u.user_id = w.user_id
GROUP BY u.full_name
ORDER BY total_watch_time DESC;

-- Which users have watched movies from more than 5 different genres?
SELECT 
	w.user_id,
	COUNT(m.genre) AS diffrent_genres
FROM Users u 
LEFT JOIN Watch_History w 
	ON u.user_id = w.user_id
LEFT JOIN Movies m 
	ON w.movie_id = m.movie_id
GROUP BY w.user_id
HAVING 	COUNT(m.genre) > 5
ORDER BY diffrent_genres DESC;


-- Find users who have been subscribed to Netflix for over a year continuously (no gap between end_date and next start_date).
WITH RankedSubs AS (
	SELECT 
		u.user_id,
		s.start_date,
		s.end_date,
		LAG(s.end_date) OVER (PARTITION BY u.user_id ORDER BY s.start_date) AS prev_end
	FROM Users u 
	LEFT JOIN Subscriptions s 
		ON u.user_id = s.user_id
),
ConsecutiveSubs AS (
	SELECT 
		user_id,
		start_date,
		end_date,
		prev_end,
		CASE 
			WHEN DATEDIFF(DAY, prev_end, start_date) = 1 OR prev_end IS NULL THEN 0
			ELSE 1
		END AS gap_flag
	FROM RankedSubs 
),
Groups AS (
	SELECT *,
		SUM(gap_flag) OVER (PARTITION BY user_id ORDER BY start_date ROWS UNBOUNDED PRECEDING) AS group_id
	FROM ConsecutiveSubs
),
GroupDurations AS (
	SELECT 
		user_id,
		group_id,
		MIN(start_date) AS group_start,
		MAX(end_date) AS group_end,
		DATEDIFF(DAY, MIN(start_date), MAX(end_date)) AS total_days
	FROM Groups 
	GROUP BY user_id, group_id
)
SELECT 
	user_id,
	group_start,
	group_end,
	total_days
FROM GroupDurations 
WHERE total_days >= 365;