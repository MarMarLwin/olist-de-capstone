--create database olist_dw;
---- Is the server alive?
--SELECT version(), current_date;
---- create three layers
--CREATE SCHEMA raw;
--CREATE SCHEMA staging;
--CREATE SCHEMA dw;
--
--create table raw.hello (id INT, message TEXT);
--insert into raw.hello values (1, 'Hello, data!');
--select * from raw.hello;
--
--select * from raw.customers;

select * from orders limit 10;

select order_id, order_status as status
from orders limit 10;

select distinct order_status from orders;

select order_id, order_status as status
from orders
where order_status ='delivered';

select distinct order_status as status
from orders
where order_status <>'canceled';

select distinct customer_state from customers;

select * from customers 
where customer_state in ('SP','RJ','MG');

select * from order_items
where price between 20 and 30;

select order_id, product_id, price, freight_value, price+freight_value as total_paid 
from order_items
order by price desc, freight_value desc
limit 10;

select seller_id, count(*)item_sold
from order_items 
group by seller_id 
having count(*)>100;

-- 1. How many customers are there in each state? Show the top 5 states.

select customer_state, count(customer_id) customer_count
from customers
group by customer_state
order by customer_count desc
limit 5;

-- 2.How many distinct real customers (customer_unique_id) are there?

select count(distinct(customer_id)) from customers;

-- 3.Which payment_type is used most, and what is its total payment_value?

select payment_type,count(payment_type)count, SUM(payment_value)total_paid 
from order_payments
group by payment_type
order by total_paid desc
limit 1;

-- 4.How many reviews are there for each review_score (1 to 5)? What is the overall average score?

select review_score,count(*) as review_count,AVG(review_score) over() overall
from order_reviews
group by review_score;

-- 5.Sellers by state: which states have more than 50 sellers?

select seller_state,count(distinct(seller_id))as seller_count
from sellers
group by seller_state
having count(distinct(seller_id))>50

-- 6.Average price and freight per order item, rounded to 2 decimals.

select order_item_id,round(AVG(price),2) Average_price,round(AVG(freight_value),2) Average_freight
from order_items
group by order_item_id 
order by order_item_id 


select  order_id,count(payment_type) from order_payments op 
group by order_id
having count(op.payment_type )>1

select order_id, count(oi.order_item_id ) from order_items oi 
group by oi.order_id  
having count(oi.order_id)>1



