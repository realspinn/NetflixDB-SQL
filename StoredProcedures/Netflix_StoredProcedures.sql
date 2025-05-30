-- =======================================
--  1. Subscriptions Ending Soon
-- =======================================
/*
  Stored Procedure: GetSubscriptionsEndingSoon
  Purpose: Retrieves all users whose active subscriptions are ending within the next X days.
  Parameters:
      @DaysAhead (INT) – Number of days from today to look ahead.
  Usage: Useful for generating renewal reminder reports or alerts.
*/
CREATE PROCEDURE GetSubscriptionsEndingSoon
    @DaysAhead INT = 10
AS
BEGIN
    SELECT 
        u.user_id,
        u.full_name,
        s.start_date,
        s.end_date,
        CASE 
            WHEN s.end_date >= GETDATE() THEN 'Active'
            ELSE 'Expired'
        END AS subscription_status
    FROM Users u
    LEFT JOIN Subscriptions s ON u.user_id = s.user_id
    WHERE s.end_date BETWEEN GETDATE() AND DATEADD(DAY, @DaysAhead, GETDATE())
    ORDER BY s.end_date;
END;
GO


-- =======================================
--  2. Top N Most Watched Movies
-- =======================================
/*
  Stored Procedure: GetTopWatchedMovies
  Purpose: Lists the top N most-watched movies across all users.
  Parameters:
      @TopN (INT) – Number of top movies to return.
  Usage: Used for dashboard insights and recommendation analysis.
*/
CREATE PROCEDURE GetTopWatchedMovies
    @TopN INT = 10
AS
BEGIN
    SELECT TOP (@TopN)
        m.title,
        m.genre,
        COUNT(w.watch_duration_minutes) AS total_watch_count
    FROM Watch_History w
    LEFT JOIN Movies m ON w.movie_id = m.movie_id
    GROUP BY m.title, m.genre
    ORDER BY total_watch_count DESC;
END;
GO


-- =======================================
--  3. Users with Renewed Subscriptions
-- =======================================
/*
  Stored Procedure: GetUsersWithRenewedSubscriptions
  Purpose: Identifies users who have had more than one subscription (i.e., they renewed).
  Parameters: None
  Usage: Useful for retention and churn analysis.
*/
CREATE PROCEDURE GetUsersWithRenewedSubscriptions
AS
BEGIN
    SELECT DISTINCT user_id, full_name
    FROM (
        SELECT 
            u.user_id,
            u.full_name,
            COUNT(s.start_date) OVER (PARTITION BY u.user_id) AS subscription_count
        FROM Users u
        LEFT JOIN Subscriptions s ON u.user_id = s.user_id
    ) t
    WHERE t.subscription_count > 1
    ORDER BY full_name;
END;
GO


-- =======================================
--  4. Users Below Plan Average Watch Time
-- =======================================
/*
  Stored Procedure: GetUnderperformingUsersByPlan
  Purpose: Returns users whose total watch time is below their plan's average usage.
  Parameters: None
  Usage: Helps identify under-engaged users or potential churn risks.
*/
CREATE PROCEDURE GetUnderperformingUsersByPlan
AS
BEGIN
    WITH UserWatchTime AS (
        SELECT 
            s.user_id,
            s.plan_id,
            SUM(wh.watch_duration_minutes) AS total_watch_time
        FROM Subscriptions s
        LEFT JOIN Plans p ON s.plan_id = p.plan_id
        LEFT JOIN Watch_History wh ON s.user_id = wh.user_id
        GROUP BY s.user_id, s.plan_id
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
    LEFT JOIN PlanAverage p ON u.plan_id = p.plan_id
    WHERE u.total_watch_time < p.avg_watch_time;
END;
GO


-- =======================================
-- 5. Most Watched Movie per Month
-- =======================================
/*
  Stored Procedure: GetTopMonthlyMovies
  Purpose: Finds the most-watched movie in each month for a given year.
  Parameters:
      @Year (INT) – Year to analyze.
  Usage: Useful for monthly content performance tracking.
*/
CREATE PROCEDURE GetTopMonthlyMovies
    @Year INT
AS
BEGIN
    WITH MonthlyWatchCounts AS (
        SELECT
            MONTH(wh.watch_date) AS watch_month,
            m.title,
            COUNT(wh.watch_duration_minutes) AS total_watch_count
        FROM Watch_History wh
        LEFT JOIN Movies m ON wh.movie_id = m.movie_id
        WHERE YEAR(wh.watch_date) = @Year
        GROUP BY MONTH(wh.watch_date), m.title
    ),
    RankedMovies AS (
        SELECT 
            watch_month,
            title,
            total_watch_count,
            RANK() OVER (PARTITION BY watch_month ORDER BY total_watch_count DESC) AS rk
        FROM MonthlyWatchCounts
    )
    SELECT 
        watch_month,
        title AS most_watched_movie,
        total_watch_count
    FROM RankedMovies
    WHERE rk = 1
    ORDER BY watch_month;
END;
GO


-- =======================================
-- 6. Heavy Watchers (5+ Movies in a Day)
-- =======================================
/*
  Stored Procedure: GetHeavyWatchersPerDay
  Purpose: Lists users who watched 5 or more movies in a single day.
  Parameters: None
  Usage: Tracks highly engaged users and binge-watching patterns.
*/
CREATE PROCEDURE GetHeavyWatchersPerDay
AS
BEGIN
    SELECT 
        u.user_id,
        w.watch_date,
        COUNT(m.movie_id) AS movies_watched
    FROM Users u
    LEFT JOIN Watch_History w ON u.user_id = w.user_id
    LEFT JOIN Movies m ON w.movie_id = m.movie_id
    GROUP BY u.user_id, w.watch_date
    HAVING COUNT(m.movie_id) >= 5
    ORDER BY movies_watched DESC;
END;
GO


-- =======================================
--  7. Signups Matching Subscription Start Month
-- =======================================
/*
  Stored Procedure: GetSignupSameMonthAsSubscription
  Purpose: Retrieves users who signed up in the same month and year as their first subscription.
  Parameters: None
  Usage: Helps analyze onboarding effectiveness and conversion rates.
*/
CREATE PROCEDURE GetSignupSameMonthAsSubscription
AS
BEGIN
    SELECT 
        u.user_id,
        u.full_name,
        u.signup_date,
        s.start_date
    FROM Users u 
    LEFT JOIN Subscriptions s ON u.user_id = s.user_id
    WHERE 
        MONTH(u.signup_date) = MONTH(s.start_date)
        AND YEAR(u.signup_date) = YEAR(s.start_date)
    ORDER BY u.signup_date DESC;
END;
GO
