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
