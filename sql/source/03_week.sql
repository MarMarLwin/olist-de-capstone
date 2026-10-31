
WITH delivered AS (
  SELECT o.order_id, c.customer_state,
         o.order_delivered_customer_date::date
           - o.order_purchase_timestamp::date AS days,
         o.order_delivered_customer_date
           > o.order_estimated_delivery_date  AS is_late
  FROM raw.orders o
  JOIN raw.customers c USING (customer_id)
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
)
SELECT customer_state,
       COUNT(*)                 AS orders,
       ROUND(AVG(days), 1)      AS avg_days,
       ROUND(100.0 * AVG(is_late::int), 1) AS pct_late
FROM delivered
GROUP BY customer_state ORDER BY pct_late DESC;

-- Q1. NULL audit: count NULLs in product_category_name and product_weight_g.

select 
count(case when product_category_name is null then 1 end) as null_product_category_name,
count(case when product_weight_g is null then 1 end) as null_product_weight_g
from products;



-- Q2. For each month of purchase, what is the average delivery time, and how many orders (and what percentage) were delivered within 30 days of purchase?

with delivered as (
  select o.order_id,order_delivered_customer_date,order_purchase_timestamp,
  		date_trunc('month', order_purchase_timestamp) AS purchase_month,
         o.order_delivered_customer_date::date
           - o.order_purchase_timestamp::date as days              
           
  from orders o
  where o.order_status = 'delivered'
    and o.order_delivered_customer_date IS NOT null
    group by order_id
    order by order_purchase_timestamp
)

select to_char(purchase_month, 'YYYY-MM'),round(avg(days), 1)      AS avg_days,
       count(*)                 AS total_orders  ,
       round(
        count(
            CASE
                WHEN order_delivered_customer_date - order_purchase_timestamp
                     <= INTERVAL '30 days'
                THEN 1
            END

        ) * 100.0 / count(*),
        2
    ) AS percentage_within_30_days
    
from delivered
group by purchase_month
order by purchase_month;



---Q.3 On which day of the week do customers place the most orders? Show each weekday’s name and number, and the total orders for that day, sorted from busiest to quietest.

with week as(
select order_id,
	extract(DOW from order_purchase_timestamp)as weekday_num,
	to_char(order_purchase_timestamp,'FMDay')as weekday_text
from orders
)
select weekday_num,weekday_text,count(order_id) as total_order
from week
group by weekday_num,weekday_text
order by total_order desc


-- Q.4 What is the total revenue for each product category, shown with its English name? If a category has no English translation, 
--show the original Portuguese name instead. If the product has no category at all, show it as ‘unknown’.

--select distinct(product_category_name) from category_translation ct 

select 
case
	when ct.product_category_name_english is null
		then ct.product_category_name
	when ct.product_category_name_english is not null
		then ct.product_category_name_english
	
end
as category_name
,
SUM(price+freight_value) as revenue
from order_items oi
join products p on oi.product_id =p.product_id 
join category_translation ct on ct.product_category_name=p.product_category_name

group by ct.product_category_name,ct.product_category_name_english
order by product_category_name_english



--Q.5 Group delivered orders by delivery speed:
--•           Fast: 7 days or less from purchase to delivery.
--•           Normal: 8 to 14 days.
--•           Slow: 15 to 30 days.
--•           Very slow: more than 30 days.
--How many orders fall into each group, and what percentage of the total is each?

with delivery_records as(
select order_id,
order_delivered_customer_date::date - order_purchase_timestamp::date as delivered_day
from orders
where order_status ='delivered' and order_delivered_customer_date is not null)
select 
case 
	when delivered_day <= 7 then 'Fast'
	when delivered_day<=14 then 'Normal'
	when delivered_day<=30 then 'Slow'
	else 'Very slow'
end
as speed,count(delivered_day) as total, round(count(order_id)*100.0/SUM(count(order_id)) over(),2) as percentage
from delivery_records
group by speed 
order by speed 

