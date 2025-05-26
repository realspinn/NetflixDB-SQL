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


/* 🍿 Movies & Watch Behavior
List the top 10 most watched movies along with their genres and total watch count. */
SELECT TOP 10
	m.title,
	m.genre,
	COUNT(w.watch_duration_minutes) AS total_watch_count
FROM Watch_History w 
LEFT JOIN Movies m 
	ON w.movie_id = m.movie_id
GROUP BY m.title, m.genre
ORDER BY total_watch_count DESC;


-- Find the most watched genre in each year.
WITH GenreCounts AS (
	SELECT 
		YEAR(w.watch_date) AS watch_year,
		m.genre,
		COUNT(*) AS watch_count
	FROM Watch_History w 
	LEFT JOIN Movies m
		ON w.movie_id = w.movie_id
	GROUP BY YEAR(w.watch_date), m.genre
),
RankedGenres AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY watch_year ORDER BY watch_count) AS rn
	FROM GenreCounts 
)

SELECT 
	watch_year,
	genre
	watch_count
FROM RankedGenres
WHERE rn = 1;


-- Which movies have never been watched?
SELECT 
	m.movie_id,
	m.title
FROM Movies m 
LEFT JOIN Watch_History w 
	ON m.movie_id = w.movie_id
WHERE w.movie_id IS NULL;


-- For each movie, what is the average watch duration as a percentage of 120 minutes (standard movie length)?
SELECT 
	m.movie_id,
	m.title,
	AVG(w.watch_duration_minutes) avg_watch_duration,
	CONCAT(AVG(w.watch_duration_minutes) * 100.0 / 120, '%') AS avg_watch_percentage
FROM Movies m 
LEFT JOIN Watch_History w 
	ON m.movie_id = w.movie_id
GROUP BY m.movie_id, m.title


-- Which genre has the highest average movie rating?
SELECT TOP 1
	genre,
	AVG(rating) OVER (PARTITION BY movie_id) AS avg_movie_rating
FROM Movies
ORDER BY avg_movie_rating DESC;


-- Which 5 movies have the highest average watch time per user?
SELECT TOP 5
	m.title,
	u.full_name,
	AVG(w.watch_duration_minutes) OVER (PARTITION BY u.user_id) AS avg_watch_time_per_user
FROM Movies m 
LEFT JOIN Watch_History w 
	ON m.movie_id = w.movie_id
LEFT JOIN Users u 
	ON u.user_id = w.user_id
ORDER BY avg_watch_time_per_user DESC;


-- What is the total watch time per genre this year?
SELECT *
FROM(
	SELECT
		m.genre,
		YEAR(w.watch_date) AS watch_year,
		COUNT(*) AS total_watch_per_genre
	FROM Watch_History w 
	LEFT JOIN Movies m
		ON w.movie_id = m.movie_id
	GROUP BY m.genre, YEAR(w.watch_date) 
) sub 
WHERE sub.watch_year = '2025';

-- Which user watched the highest-rated movie of all time, and when?
SELECT TOP 1 
	u.user_id,
	u.full_name,
	m.title,
	w.watch_date,
	m.rating
FROM Users u 
LEFT JOIN Watch_History w 
	ON u.user_id = w.user_id
LEFT JOIN Movies m 
	ON w.movie_id = m.movie_id
WHERE m.rating = 9.9
ORDER BY m.rating DESC;


-- Which users watched more than 3 movies from the same genre in a day?
SELECT 
	w.user_id,
	m.genre,
	CAST(w.watch_date AS DATE) AS watch_day,
	COUNT(*) AS movies_watched
FROM Users u 
LEFT JOIN Watch_History w 
	ON u.user_id = w.user_id
LEFT JOIN Movies m 
	ON w.movie_id = m.movie_id
GROUP BY w.user_id, m.genre, CAST(w.watch_date AS DATE)
HAVING COUNT(*) > 3;


-- What are the average watch times per user per month for the last 6 months?
SELECT 
	wh.user_id,
	MONTH(CAST(wh.watch_date AS DATE)) AS watch_month,
	AVG(wh.watch_duration_minutes) AS avg_watch_duration_minutes
FROM Watch_History wh 
LEFT JOIN Users u 
	ON wh.user_id = u.user_id
WHERE wh.watch_date >= DATEADD(MONTH, -6, GETDATE())
GROUP BY wh.user_id, MONTH(CAST(wh.watch_date AS DATE))



/* Rank users by total watch time using a window function (partitioned by plan). */
SELECT 
	u.user_id,
	p.plan_name,
	SUM(wh.watch_duration_minutes)  AS total_watch_time,
	RANK() OVER (PARTITION BY p.plan_name ORDER BY SUM(wh.watch_duration_minutes) DESC) AS watch_rank
FROM Users u
LEFT JOIN Watch_History wh 
	ON u.user_id = wh.user_id
LEFT JOIN Subscriptions s 
	ON u.user_id = s.user_id
LEFT JOIN Plans p 
	ON s.plan_id = p.plan_id
GROUP BY u.user_id, p.plan_name
ORDER BY p.plan_name, watch_rank;


--Find the most recent movie watched by each user.
SELECT 
	u.full_name,
	m.title,
	wh.watch_date
FROM Movies m 
LEFT JOIN Watch_History wh 
	ON m.movie_id = wh.movie_id
LEFT JOIN Users u 
	ON wh.user_id = u.user_id
ORDER BY wh.watch_date DESC;

-- First and last watched movie title per user
WITH RankedWatches AS (
    SELECT
        wh.user_id,
        wh.movie_id,
        wh.watch_date,
        ROW_NUMBER() OVER (PARTITION BY wh.user_id ORDER BY wh.watch_date) AS rn_asc,
        ROW_NUMBER() OVER (PARTITION BY wh.user_id ORDER BY wh.watch_date DESC) AS rn_desc
    FROM Watch_History wh
)
SELECT TOP 10
    fw.user_id,
    m1.title AS first_movie_title,
    m2.title AS last_movie_title
FROM RankedWatches fw
JOIN RankedWatches lw
    ON fw.user_id = lw.user_id
    AND fw.rn_asc = 1
    AND lw.rn_desc = 1
JOIN Movies m1
    ON fw.movie_id = m1.movie_id
JOIN Movies m2
    ON lw.movie_id = m2.movie_id;



-- Which user has the longest gap between any two watch events?
WITH WatchWithGap AS (
    SELECT
        user_id,
        watch_date,
        LAG(watch_date) OVER (PARTITION BY user_id ORDER BY watch_date) AS prev_watch_date
    FROM Watch_History
),
GapInDays AS (
    SELECT
        user_id,
        DATEDIFF(DAY, prev_watch_date, watch_date) AS gap_days
    FROM WatchWithGap
    WHERE prev_watch_date IS NOT NULL
),
MaxGapPerUser AS (
    SELECT
        user_id,
        MAX(gap_days) AS max_gap
    FROM GapInDays
    GROUP BY user_id
)
SELECT TOP 1
    user_id,
    max_gap
FROM MaxGapPerUser
ORDER BY max_gap DESC;



-- Show the cumulative watch time per user, ordered by date.
SELECT
    user_id,
    watch_date,
    watch_duration_minutes,
    SUM(watch_duration_minutes) OVER (PARTITION BY user_id ORDER BY watch_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_watch_time
FROM Watch_History
ORDER BY user_id, watch_date;



-- For each plan, how many users upgraded or downgraded from/to it (based on previous subscriptions)?
WITH OrderedSubs AS (
    SELECT 
        s.user_id,
        s.plan_id,
        s.start_date,
        p.plan_name,
        p.price AS current_price,
        LAG(p.price) OVER (PARTITION BY s.user_id ORDER BY s.start_date) AS previous_price,
        LAG(s.plan_id) OVER (PARTITION BY s.user_id ORDER BY s.start_date) AS previous_plan_id
    FROM Subscriptions s
    JOIN Plans p ON s.plan_id = p.plan_id
),
Transitions AS (
    SELECT 
        plan_id,
        plan_name,
        CASE 
            WHEN previous_price IS NULL THEN NULL
            WHEN previous_price < current_price THEN 'Upgrade'
            WHEN previous_price > current_price THEN 'Downgrade'
            ELSE 'Same'
        END AS transition_type
    FROM OrderedSubs
)
SELECT 
    plan_name,
    transition_type,
    COUNT(*) AS transition_count
FROM Transitions
WHERE transition_type IN ('Upgrade', 'Downgrade')
GROUP BY plan_name, transition_type
ORDER BY plan_name, transition_type;



WITH CleanedDates AS (
    SELECT DISTINCT user_id, CAST(watch_date AS DATE) AS watch_day
    FROM Watch_History
),
DateWithRowNum AS (
    SELECT 
        user_id,
        watch_day,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY watch_day) AS rn
    FROM CleanedDates
),
Streaks AS (
    SELECT 
        user_id,
        watch_day,
        DATEADD(DAY, -rn, watch_day) AS streak_group
    FROM DateWithRowNum
),
GroupedStreaks AS (
    SELECT 
        user_id,
        streak_group,
        COUNT(*) AS consecutive_days
    FROM Streaks
    GROUP BY user_id, streak_group
)
SELECT DISTINCT user_id
FROM GroupedStreaks
WHERE consecutive_days >= 7;


-- Find all users who have watched only top-rated movies (above 4.5 rating).
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