-- Create Database 
-- USE NetflixDB;
CREATE DATABASE NetflixDB;

-- Netflix DDL Design
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    signup_date DATE NOT NULL
);

CREATE TABLE Plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL,
    price DECIMAL(5,2) NOT NULL
);

CREATE TABLE Subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT FOREIGN KEY REFERENCES Users(user_id),
    plan_id INT FOREIGN KEY REFERENCES Plans(plan_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE Movies (
    movie_id INT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    release_year INT NOT NULL,
    rating DECIMAL(2,1) NOT NULL
);

CREATE TABLE Watch_History (
    watch_id INT PRIMARY KEY,
    user_id INT FOREIGN KEY REFERENCES Users(user_id),
    movie_id INT FOREIGN KEY REFERENCES Movies(movie_id),
    watch_date DATETIME NOT NULL,
    watch_duration_minutes INT NOT NULL
);

