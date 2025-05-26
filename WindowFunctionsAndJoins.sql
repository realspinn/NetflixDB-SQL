
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