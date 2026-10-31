select * from customers;
select * from sellers;
select * from orders;
select * from order_items oi;
--Q.1. Revenue (SUM of price) by customer_state for delivered orders. Top 10 states.

select customer_state,SUM(price)revenue, order_status from orders o
join customers c on c.customer_id = o.customer_id 
join order_items oi  on oi.order_id=o.order_id
group by customer_state,order_status
having o.order_status ='delivered'
order by revenue desc
limit 10
 

-- Q.2 How many orders have no review at all? (anti-join)

select count(*)without_review from orders o
left join order_reviews r on o.order_id =r.order_id 
where r.order_id is null


select * from order_reviews t where t.order_id ='00143d0f86d6fbd9f9b38ab440ac16f5'

 


select distinct(p.product_category_name ) from products p
select * from order_items limit 10 
select * from orders

select * from category_translation ct 
-- Q:3 Top 10 product categories in English by items sold. Why LEFT JOIN to the translation?
select  ct.product_category_name_english   from order_items oi 
join products p 
on p.product_id =oi.product_id 
left join category_translation ct on p.product_category_name = ct.product_category_name limit 10 

-- 4. What share of order items were sold by a seller in the same state as the customer?
select 
ROUND(100.0 * COUNT(CASE WHEN c.customer_state = s.seller_state THEN 1 END) / COUNT(*), 2) AS share
from order_items oi 
join orders o on o.order_id =oi.order_id 
join sellers s on oi.seller_id=s.seller_id 
join customers c  on o.customer_id =c.customer_id 

--- 5. For 5 orders, show item revenue and payment total side by side — without fan-out.
select o.order_id,o.revenue,paid
from (select order_id,SUM(price+ freight_value)as revenue from order_items
group by order_id) o
join
(select order_id, SUM(payment_value)paid  from order_payments 
group by order_id) p on o.order_id =p.order_id 
limit 5

--6. Find orders where payments differ from price + freight by more than 1.00.

select o.order_id,o.revenue,paid, p.paid -o.revenue  as diff
from (select order_id,SUM(price+ freight_value)as revenue from order_items
group by order_id) o
join
(select order_id, SUM(payment_value)paid  from order_payments 
group by order_id) p on o.order_id =p.order_id 
where p.paid -o.revenue >1
order by diff desc


