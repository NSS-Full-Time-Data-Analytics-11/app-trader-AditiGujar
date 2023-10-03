-- Apple
SELECT * from app_store_apps

-- Google
SELECT * from play_store_apps

SELECT distinct genres, appstr.price, playstr.price,appstr.rating, playstr.content_rating,category from app_store_apps as appstr
INNER join play_store_apps as playstr using (name)

--Develop some general recommendations about the genre by apple  
WITH apple_apps
     AS (SELECT CASE
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
SELECT price_range,avg(rating) as rating,genre,review_count
FROM   apple_apps
WHERE cast(review_count as numeric) > 10000
group by price_range,rating,genre,review_count
ORDER  BY rating DESC,price_range ASC,review_count DESC

--Develop some general recommendations about the genre by google

WITH playstr_apps
     AS (SELECT CASE
                  WHEN price = '0.99' THEN 'non'
                  WHEN price > '0.99' AND price <= '1.99' THEN '0-1'
                  WHEN price > '2.00' AND price <= '5.00' THEN '2-5'
                  WHEN price > '5.00' AND price <= '50.00' THEN '5-50'
		 		ELSE '50.00' END AS price_range,
                rating,
                primary_genre AS genre,
                content_rating,
		 		cast(review_count as numeric)
		 		
         FROM   app_store_apps)
--SELECT* from playstr_apps
SELECT price_range,avg(rating),genre,review_count
FROM   playstr_apps
WHERE cast(review_count as integer) > 10000
group by price_range,rating,genre,review_count
ORDER  BY rating DESC,price_range ASC,review_count DESC








