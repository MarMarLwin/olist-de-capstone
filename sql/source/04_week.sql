
with seller_revenue as(
select s.seller_id,s.seller_state, SUM(oi.price +oi.freight_value )as revenue
from order_items oi 
join sellers s on oi.seller_id =s.seller_id 
group by s.seller_id ,s.seller_state 
),
 ranked as (
 select s.*, rank()over(partition by seller_state order by revenue desc) as rnk
 from seller_revenue s
)
select * from ranked
order by revenue desc

--For every customer, show the date of their first order and how many orders they placed in total.


A customer = customer_unique_id (customer_id is new on every order)
Join raw.orders to raw.customers
First order date = earliest order_purchase_timestamp, as a date
Count every order, whatever its status
MIN() and COUNT() with GROUP BY is enough
Then try ROW_NUMBER() = 1 for the same answer
Most customers placed only 1 order




--32ea3bdedab835c3aa6cb68ce66565ef
select * from (
select c.customer_unique_id , MIN(order_purchase_timestamp::date) as first_order,
rank () OVER(partition by  MIN(order_purchase_timestamp::date) order by c.customer_unique_id )date_rnk,
rank() OVER(partition by customer_unique_id order by order_purchase_timestamp asc)date_rem,
count(order_id) OVER(partition by c.customer_unique_id)as order_count
from orders o 
join customers c on o.customer_id =c.customer_id
group by c.customer_unique_id ,o.order_id
order by first_order) a where date_rem=1

-- GROUP BY: 1 row per order
SELECT order_id, SUM(price) AS order_total
FROM raw.order_items
GROUP BY order_id having order_id='001d8f0e34a38c37f7dba2a37d4eba8b';

-- Window: every item row kept, with its order's total beside it
SELECT order_id, order_item_id, price,
       SUM(price) OVER (PARTITION BY order_id) AS order_total
FROM raw.order_items
where order_id ='001d8f0e34a38c37f7dba2a37d4eba8b';

WITH monthly AS (
SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
SUM(oi.price+oi.freight_value  ) AS revenue
FROM raw.orders o
JOIN raw.order_items oi ON oi.order_id = o.order_id
GROUP BY 1
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month,
revenue,
SUM(revenue) OVER (ORDER BY month
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
ROUND(SUM(revenue) OVER (ORDER BY month
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_sum_2,
SUM(revenue) OVER (ORDER BY month
ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS this_and_next ,
SUM(revenue) OVER (ORDER BY month
ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS remaining_total
FROM monthly
ORDER BY month;

select (354.75+57163.59+19.62)--57537.96

select (137188.49+57163.59)--194352.08
select (137188.49+57183.21)--194371.70
select (137188.49+19.62+56808.84)--194016.95

 



-- Some orders have more than one review.
-- Keep only the most recent review per order.
WITH ranked AS (
  SELECT r.*,
         ROW_NUMBER() OVER (
           PARTITION BY order_id
           ORDER BY review_answer_timestamp DESC,
                    review_id
         ) AS rn
  FROM raw.order_reviews r
)
SELECT *
FROM ranked
WHERE order_id = '0035246a40f520710769010f752e7507';



--Question 3 Running revenue per seller
--Question: For each seller, show how their revenue adds up over time, order by order. The running total starts again for each seller.
WITH seller_revenue AS (
    SELECT
        seller_id,order_id,SUM(price) AS order_revenue
    FROM order_items GROUP BY
        seller_id,order_id
),
running_revenue AS (
    SELECT
        seller_id,order_id,order_revenue, SUM(order_revenue) OVER ( PARTITION BY seller_id ORDER BY order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_revenue
    FROM seller_revenue
)
SELECT
    seller_id,order_id,order_revenue,running_total_revenue
FROM running_revenue
ORDER BY    seller_id,order_id;
 

--Question 4 · Share of money by payment type
--Question: What percentage of all money paid came from each payment type? Get the grand total with SUM(…) OVER (), not a subquery. Round to 1 decimal.
--select distinct(payment_type) from order_payments op 
WITH payment_summary AS (
    SELECT
        payment_type,SUM(payment_value) AS total_payment
    FROM order_payments 
    WHERE payment_type <> 'not_defined'
    GROUP BY payment_type
)
SELECT
    payment_type,total_payment,
    ROUND(total_payment * 100.0 / SUM(total_payment) OVER (),1) AS percentage
FROM payment_summary
ORDER BY percentage DESC;
--Question 5 · Items priced above their category average
--Question: Find the order items whose price is higher than the average price in their product category. 
--Use AVG(price) OVER (PARTITION BY category). Leave out products with no category.
WITH category_avg AS (
    SELECT
        oi.order_id,oi.product_id,oi.price,p.product_category_name AS category,
        AVG(oi.price) OVER (PARTITION BY p.product_category_name) AS avg_category_price
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_category_name IS NOT null
)
SELECT
    order_id,product_id,category,price,
    ROUND(avg_category_price, 2) AS avg_category_price
FROM category_avg
WHERE price > avg_category_price
ORDER BY category, price DESC;
