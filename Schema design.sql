/* CREATE DB
CREATE DATABASE NetflixDB; */

-- USERS
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    country VARCHAR(50),
    date_joined DATE
);

-- MOVIES / SHOWS
CREATE TABLE movies (
    movie_id INT PRIMARY KEY,
    title VARCHAR(255),
    type VARCHAR(20), -- 'Movie' or 'TV Show'
    release_year INT,
    duration VARCHAR(20), -- e.g. '90 min' or '2 Seasons'
    description TEXT
);

-- GENRES
CREATE TABLE genres (
    genre_id INT PRIMARY KEY,
    genre_name VARCHAR(50)
);

-- MOVIE_GENRES (many-to-many)
CREATE TABLE movie_genres (
    movie_id INT REFERENCES movies(movie_id),
    genre_id INT REFERENCES genres(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

-- WATCH HISTORY
CREATE TABLE watch_history (
    history_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    movie_id INT REFERENCES movies(movie_id),
    watch_date TIMESTAMP
);

-- RATINGS
CREATE TABLE ratings (
    rating_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    movie_id INT REFERENCES movies(movie_id),
    rating INT CHECK (rating >= 1 AND rating <= 5),
    rated_at TIMESTAMP
);

-- SUBSCRIPTIONS
CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    plan_type VARCHAR(50), -- 'Basic', 'Standard', 'Premium'
    start_date DATE,
    end_date DATE
);

-- PAYMENTS
CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    amount DECIMAL(10,2),
    payment_date DATE,
    payment_method VARCHAR(50) -- 'Credit Card', 'PayPal', etc.
);

