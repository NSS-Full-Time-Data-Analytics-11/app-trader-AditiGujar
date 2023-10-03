-- Apple
SELECT * from app_store_apps
--where  like 'LinkedIn';

-- Google
SELECT * from play_store_apps
order by name 

-- 3.a. Develop some general recommendations about the price range, genre, content rating, or any other app characteristics that the company should target.
--      Develop some general recommendations about the genre by apple  
WITH apple_apps
     AS (SELECT 
		 		name,
		 		CASE
                  WHEN price = 0 THEN 'non'
                  WHEN price > 0 AND price <= 1 THEN '0-1'
                  WHEN price > 1 AND price <= 5 THEN '1-5'
                  WHEN price > 5 AND price <= 50 THEN '5-50'
                  ELSE '50+'
                END AS price_range,
                rating,
                primary_genre AS genre,
                content_rating,
		 		cast(review_count as numeric)
FROM   app_store_apps)
SELECT price_range, rating as rating, genre, round(avg(review_count), 0) as avg_reviews
FROM   apple_apps
WHERE cast(review_count as numeric) > 10000
group by price_range, rating, genre
ORDER  BY rating DESC, price_range ASC, avg_reviews DESC

--      Develop some general recommendations about the genre by google
WITH playstr_apps
     AS (SELECT name,
		 		CASE
                  WHEN price = '0.99' THEN 'non'
                  WHEN price > '0.99' AND price <= '1.99' THEN '0-1'
                  WHEN price > '2.00' AND price <= '5.00' THEN '2-5'
                  WHEN price > '5.00' AND price <= '50.00' THEN '5-50'
		 		ELSE '50.00' END AS price_range,
                rating,
                genres AS genre,
                content_rating, 
		 		cast(review_count as integer)
         FROM   play_store_apps)
SELECT price_range, rating, genre, round(avg(review_count), 0) as avg_reviews
FROM   playstr_apps
WHERE cast(review_count as integer) > 10000
group by price_range, rating, genre
ORDER  BY rating DESC, price_range ASC, avg_reviews DESC


--3B

WITH roi_data as (
SELECT *, (COALESCE(apple_earnings_over_life, 0::money) + COALESCE(google_earnings_over_life, 0::money)) as total_earnings_over_life, 
(COALESCE(apple_purchase_price, 0::money) + COALESCE(google_purchase_price, 0::money) + (CASE WHEN COALESCE(apple_rating, 0) >= COALESCE(google_rating, 0) THEN (12 + COALESCE(apple_rating, 0) * 24) * 1000 ELSE
												 (12 + COALESCE(google_rating, 0) * 24) * 1000 END)::money) as total_expense_over_life											 
FROM 
(
-- 1) Apple App's Price, Ratings and Months in Service
WITH apple_apps
     AS (SELECT 
		 		name,
                avg(price)::money AS price, case when avg(price) < 2.5 then 25000.00::money else (avg(price) * 10000)::money end as purchase_price,
                round(avg(rating), 1) as rating, round((12 + avg(rating) * 24), 0) as months_in_service
		 FROM   app_store_apps 
		 WHERE rating IS NOT NULL 
GROUP BY name) -- Group By is required to avoid duplicates
SELECT name, rating as apple_rating, purchase_price as apple_purchase_price, (5000 * months_in_service)::money as apple_earnings_over_life from apple_apps
order by name
) apple
FULL JOIN
(
-- 2) Android App's Price, Ratings and Months in Service
WITH google_apps
     AS (SELECT 
		 		name,
                avg((trim(LEADING '$' FROM price))::numeric)::money AS price, 
		 		case when avg((trim(LEADING '$' FROM price))::numeric) < 2.5 then 25000.00::money else (avg((trim(LEADING '$' FROM price))::numeric) * 10000)::money end as purchase_price,
                round(avg(rating), 1) as rating, round((12 + avg(rating) * 24), 0) as months_in_service
		FROM   play_store_apps
		WHERE rating IS NOT NULL 
GROUP BY name) -- Group By is required to avoid duplicates
SELECT name, rating as google_rating, purchase_price as google_purchase_price, (5000 * months_in_service)::money as google_earnings_over_life from google_apps
order by name
) google USING (name) )
SELECT *
, CASE WHEN total_earnings_over_life != 0::money THEN ((total_earnings_over_life - total_expense_over_life)/total_earnings_over_life) ELSE 0 END * 100 as roi 
FROM roi_data
ORDER BY roi DESC
