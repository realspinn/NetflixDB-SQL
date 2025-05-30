 # NetflixDB

## Project Overview

**NetflixDB** is a comprehensive SQL Server database project that models and analyzes user subscription patterns, movie consumption behaviors, and subscription plan performance for a streaming platform akin to Netflix. 

Built using **SQL Server Management Studio (SSMS)**, this project showcases advanced SQL techniques including window functions, common table expressions (CTEs), subqueries, aggregates, and complex joins.

This marks my **fifth** SQL project, demonstrating progressive mastery of database querying and data analysis.

---

## Key Features & Analytical Queries

### User & Subscription Insights
- Identify users whose signup date aligns with their first subscription start date.
- Retrieve users currently subscribed to the highest-priced plans.
- Detect users with multiple subscription renewals.
- List users with subscriptions expiring within the next 10 days.
- Determine subscription plans with the longest average duration.
- Identify users who have never engaged in movie watching.
- Analyze daily watch patterns, including users who watched five or more movies in a day.
- Rank users by total watch time and detect those with diverse genre consumption.
- Track users with continuous subscription periods exceeding one year.

### Movie & Viewing Behavior Analysis
- Top 10 most viewed movies by genre and total watch count.
- Most popular genre for each year.
- List of movies with no watch records.
- Average watch duration per movie expressed as a percentage of a standard 120-minute runtime.
- Genres with the highest average movie ratings.
- Movies with the highest average watch time per user.
- Aggregate watch time by genre for the current year.
- Identify users who watched the highest-rated movie and corresponding watch dates.
- Users exhibiting high frequency watching of multiple movies from the same genre on a single day.
- Monthly average watch times per user over the past six months.

### Advanced SQL: Window Functions & Joins
- User ranking by watch time partitioned by subscription plan.
- Identification of the most recent movie viewed by each user.
- Display of users’ first and last viewed movies.
- Analysis of longest intervals between user watch events.
- Calculation of cumulative watch time per user ordered chronologically.
- Subscription plan upgrade and downgrade tracking.
- Identification of users with a minimum of 7 consecutive days of daily watch activity.

### Subqueries, Aggregates, and CTEs
- Users who exclusively watch top-rated movies (rating > 4.5).
- Users with below-average total watch time within their subscription plans.
- Monthly most-watched movies and their total watch counts.

---

## Stored Procedures Overview

| Procedure | Purpose |
|----------|---------|
| `GetSubscriptionsEndingSoon` | Alerts for subscriptions expiring in X days |
| `GetTopWatchedMovies` | Returns top N most watched movies |
| `GetUsersWithRenewedSubscriptions` | Lists users with >1 subscription |
| `GetUnderperformingUsersByPlan` | Finds users watching less than plan average |
| `GetTopMonthlyMovies` | Top movie per month (by year) |
| `GetHeavyWatchersPerDay` | Users who watched 5+ movies in one day |
| `GetSignupSameMonthAsSubscription` | Users whose sign-up matches sub month |

---

## Technologies Utilized

- **SQL Server Management Studio (SSMS)**
- Transact-SQL (T-SQL) for complex querying including window functions, CTEs, and aggregations

---

## Repository Structure and Usage

- Query scripts are organized into folders reflecting the analytical categories outlined above.
- Each script contains descriptive comments explaining query objectives and logic.
- To utilize these scripts, execute them within SSMS connected to your NetflixDB database instance.
- The README provides a conceptual overview, while detailed query logic is available within individual SQL files.

---

## Contact and Collaboration

For inquiries, feedback, or collaboration opportunities, please contact me via:

- GitHub: [https://github.com/realspinn]
- Email: adeleyeisrael400@gmail.com

---

Thank you for your interest in the NetflixDB project.  
Your feedback and contributions are welcome!
