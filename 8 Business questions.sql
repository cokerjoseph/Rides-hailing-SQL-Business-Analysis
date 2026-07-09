CREATE TABLE rides_raw (
    ride_id VARCHAR(50) PRIMARY KEY,
    rider_id VARCHAR(50),
    driver_id VARCHAR(50),
    request_time TIMESTAMP,
    pickup_time TIMESTAMP,
    dropoff_time TIMESTAMP,
    pickup_city VARCHAR(100),
    dropoff_city VARCHAR(100),
    distance_km DECIMAL(10,2),
    status VARCHAR(50),
    fair DECIMAL(10,2)
);

CREATE TABLE payment_raw (
    payment_id VARCHAR(50) PRIMARY KEY,
    ride_id VARCHAR(50),
    amount DECIMAL(10,2),
    method VARCHAR(50),
    pay_date DATE
);

CREATE TABLE riders_raw (
    rider_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    signup_date DATE,
    city VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE drivers_raw (
    driver_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    signup_date DATE,
    rating DECIMAL(3,2)
);


SELECT COUNT(*) as total_rides FROM rides_raw;
SELECT * FROM rides_raw LIMIT 10;


SELECT 
    MIN(pickup_time) as earliest_ride,
    MAX(pickup_time) as latest_ride
FROM rides_raw;


SELECT COUNT(*) as total_payments FROM payment_raw;
SELECT * FROM payment_raw LIMIT 10;

SELECT COUNT(*) as total_riders FROM riders_raw;


SELECT COUNT(*) as total_drivers FROM drivers_raw;


CREATE TABLE rides_cleaned AS
SELECT DISTINCT
    r.ride_id,
    r.rider_id,
    r.driver_id,
    r.request_time,
    r.pickup_time,
    r.dropoff_time,
    TRIM(UPPER(r.pickup_city)) as pickup_city,  
    TRIM(UPPER(r.dropoff_city)) as dropoff_city,
    r.distance_km,
    r.status,
    r.fair,
    p.amount,
    p.method as payment_method,
    p.pay_date
FROM rides_raw r
INNER JOIN payment_raw p ON r.ride_id = p.ride_id
WHERE 
    p.amount > 0  
    AND r.pickup_time >= '2021-06-01'  
    AND r.pickup_time < '2025-01-01'
    AND r.distance_km > 0  
    AND r.fair > 0;  
DROP TABLE IF EXISTS rides_cleaned;
CREATE TABLE rides_cleaned AS
SELECT DISTINCT
    r.ride_id,
    r.rider_id,
    r.driver_id,
    r.request_time,
    r.pickup_time,
    r.dropoff_time,
    TRIM(UPPER(r.pickup_city)) as pickup_city,
    TRIM(UPPER(r.dropoff_city)) as dropoff_city,
    r.distance_km,
    r.status,
    r.fair,
    p.amount,
    p.method as payment_method,
    p.pay_date
FROM rides_raw AS r
INNER JOIN payment_raw AS p ON r.ride_id = p.ride_id
WHERE 
    p.amount > 0  
    AND r.pickup_time >= '2021-06-01'  
    AND r.pickup_time < '2025-01-01'
    AND r.distance_km > 0  
    AND r.fair > 0;  


SELECT COUNT(*) FROM rides_cleaned;
SELECT * FROM rides_cleaned LIMIT 10;



SELECT COUNT(*) as total_rides FROM rides_raw;
SELECT COUNT(*) as total_payments FROM payment_raw;
SELECT COUNT(*) as total_riders FROM riders_raw;
SELECT COUNT(*) as total_drivers FROM drivers_raw;

SELECT 
    MIN(pickup_time) as earliest_ride,
    MAX(pickup_time) as latest_ride
FROM rides_raw;

SELECT COUNT(*) as completed_rides
FROM rides_raw r
JOIN payment_raw p ON r.ride_id = p.ride_id
WHERE p.amount > 0;
 

SELECT COUNT(*) as cleaned_rides_count FROM rides_cleaned;
SELECT * FROM rides_cleaned LIMIT 10;




-- Question 1:
SELECT 
    rc.ride_id,
    rc.distance_km,
    d.name as driver_name,
    ri.name as rider_name,
    rc.pickup_city,
    rc.dropoff_city,
    rc.payment_method
FROM rides_cleaned rc
JOIN drivers_raw d ON rc.driver_id = d.driver_id
JOIN riders_raw ri ON rc.rider_id = ri.rider_id
ORDER BY rc.distance_km DESC
LIMIT 10;

-- Question 2: 
SELECT COUNT(DISTINCT rc.rider_id) as active_2021_riders
FROM rides_cleaned rc
JOIN riders_raw ri ON rc.rider_id = ri.rider_id
WHERE EXTRACT(YEAR FROM ri.signup_date) = 2021
AND EXTRACT(YEAR FROM rc.pickup_time) = 2024;


-- Question 3: 
WITH quarterly_revenue AS (
    SELECT 
        EXTRACT(YEAR FROM pickup_time) as year,
        EXTRACT(QUARTER FROM pickup_time) as quarter,
        SUM(amount) as total_revenue
    FROM rides_cleaned
    GROUP BY EXTRACT(YEAR FROM pickup_time), EXTRACT(QUARTER FROM pickup_time)
),
yoy_growth AS (
    SELECT 
        curr.year,
        curr.quarter,
        curr.total_revenue,
        prev.total_revenue as prev_year_revenue,
        CASE 
            WHEN prev.total_revenue > 0 THEN 
                ((curr.total_revenue - prev.total_revenue) / prev.total_revenue * 100)
            ELSE NULL
        END as yoy_growth_pct
    FROM quarterly_revenue curr
    LEFT JOIN quarterly_revenue prev 
        ON curr.quarter = prev.quarter 
        AND curr.year = prev.year + 1
)
SELECT 
    year,
    quarter,
    total_revenue,
    prev_year_revenue,
    ROUND(yoy_growth_pct, 2) as yoy_growth_percentage
FROM yoy_growth
ORDER BY year, quarter;

-- Question 4: 
WITH driver_monthly_rides AS (
    SELECT 
        rc.driver_id,
        d.name as driver_name,
        DATE_TRUNC('month', rc.pickup_time) as ride_month,
        COUNT(*) as rides_in_month
    FROM rides_cleaned rc
    JOIN drivers_raw d ON rc.driver_id = d.driver_id
    GROUP BY rc.driver_id, d.name, DATE_TRUNC('month', rc.pickup_time)
),
driver_stats AS (
    SELECT 
        driver_id,
        driver_name,
        COUNT(DISTINCT ride_month) as active_months,
        SUM(rides_in_month) as total_rides,
        ROUND(SUM(rides_in_month)::numeric / COUNT(DISTINCT ride_month), 2) as avg_rides_per_month
    FROM driver_monthly_rides
    GROUP BY driver_id, driver_name
)
SELECT 
    driver_name,
    total_rides,
    active_months,
    avg_rides_per_month
FROM driver_stats
ORDER BY avg_rides_per_month DESC
LIMIT 5;


-- Question 5: 
WITH city_stats AS (
    SELECT 
        TRIM(UPPER(pickup_city)) as city,
        COUNT(*) as total_rides,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_rides
    FROM rides_raw
    WHERE pickup_time >= '2021-06-01' AND pickup_time < '2025-01-01'
    GROUP BY TRIM(UPPER(pickup_city))
)
SELECT 
    city,
    total_rides,
    cancelled_rides,
    ROUND((cancelled_rides::numeric / total_rides * 100), 2) as cancellation_rate_pct
FROM city_stats
ORDER BY cancellation_rate_pct DESC;


-- Question 6: 
SELECT 
    rc.rider_id,
    ri.name as rider_name,
    COUNT(*) as total_rides,
    STRING_AGG(DISTINCT rc.payment_method, ', ') as payment_methods_used
FROM rides_cleaned rc
JOIN riders_raw ri ON rc.rider_id = ri.rider_id
GROUP BY rc.rider_id, ri.name
HAVING COUNT(*) > 10 
   AND COUNT(CASE WHEN LOWER(rc.payment_method) = 'cash' THEN 1 END) = 0
ORDER BY total_rides DESC;


-- Question 7: 
WITH driver_city_revenue AS (
    SELECT 
        rc.pickup_city as city,
        rc.driver_id,
        d.name as driver_name,
        SUM(rc.amount) as total_revenue,
        ROW_NUMBER() OVER (PARTITION BY rc.pickup_city ORDER BY SUM(rc.amount) DESC) as rank
    FROM rides_cleaned rc
    JOIN drivers_raw d ON rc.driver_id = d.driver_id
    GROUP BY rc.pickup_city, rc.driver_id, d.name
)
SELECT 
    city,
    driver_name,
    total_revenue,
    rank
FROM driver_city_revenue
WHERE rank <= 3
ORDER BY city, rank;


-- Question 8: 
WITH driver_performance AS (
    SELECT 
        rc.driver_id,
        d.name as driver_name,
        d.rating,
        COUNT(*) as total_rides,
        SUM(CASE WHEN rc.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_rides
    FROM rides_cleaned rc
    JOIN drivers_raw d ON rc.driver_id = d.driver_id
    GROUP BY rc.driver_id, d.name, d.rating
)
SELECT 
    driver_name,
    total_rides,
    rating as avg_rating,
    cancelled_rides,
    ROUND((cancelled_rides::numeric / total_rides * 100), 2) as cancellation_rate_pct
FROM driver_performance
WHERE total_rides >= 30
  AND rating >= 4.5
  AND (cancelled_rides::numeric / total_rides * 100) < 5
ORDER BY total_rides DESC, rating DESC
LIMIT 10;