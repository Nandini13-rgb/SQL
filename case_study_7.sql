--What was the total quantity sold for all products?
SELECT s.prod_id, d.product_name, sum(qty) FROM balanced_tree.sales s
join balanced_tree.product_details d
on s.prod_id = d.product_id
group by s.prod_id, d.product_name;


-- What is the total generated revenue for all products before discounts?
SELECT s.prod_id, d.product_name, sum(s.qty*s.price) as revenue_before_discounts
FROM balanced_tree.sales s
join balanced_tree.product_details d
on s.prod_id = d.product_id
group by s.prod_id, d.product_name;

-- What was the total discount amount for all products?
SELECT s.prod_id, d.product_name, sum(round(s.price*s.discount/100.00,2)) as discounts
FROM balanced_tree.sales s
join balanced_tree.product_details d
on s.prod_id = d.product_id
group by s.prod_id, d.product_name;

-- How many unique transactions were there?
SELECT count(distinct txn_id) as unique_transactions
FROM balanced_tree.sales 

-- What is the average unique products purchased in each transaction?
with total_unique_products as(
  SELECT txn_id, count(distinct prod_id) as unique_products
FROM balanced_tree.sales 
group by 1)
select round(avg(unique_products)) as avg_unique_products 
from total_unique_products

--What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with total_revenue as(
  SELECT txn_id, round(sum((qty*price)*((100-discount)::decimal/100)),2) as revenue
FROM balanced_tree.sales 
group by 1),
revenue_rank as(
select *, rank()over(order by revenue desc) as rn
from total_revenue
order by revenue desc)
-- select distinct revenue from revenue_rank where rn = (select max(rn) from revenue_rank)/4
select percentile_disc(0.25) within group (order by revenue desc) as percentile_25,
percentile_disc(0.50) within group (order by revenue desc) as percentile_50,
percentile_disc(0.75) within group (order by revenue desc) as percentile_75
from revenue_rank

--What is the average discount value per transaction?
with total_discount as(
  SELECT txn_id, round(sum((price)*(discount::decimal/100)),2) as discount
FROM balanced_tree.sales 
group by 1)
select round(avg(discount),2) as avg_discount_value from total_discount

--What is the percentage split of all transactions for members vs non-members?
  with total_trans as(
  SELECT member, count(distinct txn_id) as total_transactions
FROM balanced_tree.sales 
group by 1)
select case when member = 'true' then 'Member'
else 'Non-Member'
end as member,
round(100*total_transactions/(select sum(total_transactions) from total_trans),2)
from total_trans
  
--What is the average revenue for member transactions and non-member transactions?
with total_revenue as(
  SELECT member, round(avg((qty*price)*((100-discount)::decimal/100)),2) as avg_revenue
FROM balanced_tree.sales 
group by 1)
select case when member = 'true' then 'Member'
else 'Non-Member'
end as member,
avg_revenue
from total_revenue

--What are the top 3 products by total revenue before discount?
with total_revenue as(
  SELECT d.product_name, sum((s.qty*s.price)) as revenue
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1)
select * from total_revenue
order by revenue
limit 3;

--What is the total quantity, revenue and discount for each segment?
with segment_split as(
  SELECT d.segment_name,
  sum(s.qty) as total_quantity,
  sum((s.qty*s.price)) as total_revenue,
  round(sum(s.price*(s.discount/100.00)),2) as total_discount
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1)
select * from segment_split

--What is the top selling product for each segment?
with segment_split as(
  SELECT d.product_name, d.segment_name,
  sum(s.qty) as total_quantity,
  sum((s.qty*s.price)) as total_revenue,
  round(sum(s.price*(s.discount/100.00)),2) as total_discount
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1,2),
quantity_rank as(
select product_name, segment_name, total_quantity, rank()over(partition by segment_name order by total_quantity desc) as rn from segment_split)
select product_name, segment_name, total_quantity
from quantity_rank where rn = 1;

--What is the total quantity, revenue and discount for each category?
with category_split as(
  SELECT d.category_name,
  sum(s.qty) as total_quantity,
  sum((s.qty*s.price)) as total_revenue,
  round(sum(s.price*(s.discount/100.00)),2) as total_discount
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1)
select * from category_split


--What is the top selling product for each category?
with category_split as(
  SELECT d.product_name, d.category_name,
  sum(s.qty) as total_quantity,
  sum((s.qty*s.price)) as total_revenue,
  round(sum(s.price*(s.discount/100.00)),2) as total_discount
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1,2),
quantity_rank as(
select product_name, category_name, total_quantity, rank()over(partition by category_name order by total_quantity desc) as rn from category_split)
select product_name, category_name, total_quantity
from quantity_rank where rn = 1;

--What is the percentage split of revenue by product for each segment?
with segment_split as(
  SELECT d.segment_name,
  sum((s.qty*s.price)*((100-s.discount)::decimal/100)) as total_revenue as total_revenue
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1)
select segment_name, round(100.00*total_revenue/(select sum(total_revenue) from segment_split),2) as revenue_percentage
from segment_split

--What is the percentage split of revenue by segment for each category?
with category_split as(
  SELECT d.segment_name, 
  d.category_name,
  sum((s.qty*s.price)*((100-s.discount)::decimal/100)) as total_revenue 
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1,2)
select segment_name, category_name, round(100.00*total_revenue/sum(total_revenue)over(partition by category_name),2) as percentage_split
from category_split;

--What is the percentage split of total revenue by category?
with category_split as(
  SELECT
  d.category_name,
  sum((s.qty*s.price)*((100-s.discount)::decimal/100)) as total_revenue 
FROM balanced_tree.sales s join balanced_tree.product_details as d
  on s.prod_id = d.product_id
group by 1)
select category_name, round(100.00*total_revenue/(select sum(total_revenue) from category_split),2) as percentage_split
from category_split;

--What is the total transaction “penetration” for each product? 
with penetration as(
  SELECT
  s.prod_id,
  d.product_name,
  count(distinct s.txn_id)*100.0/(select count(distinct txn_id) from balanced_tree.sales) as penetration
 
FROM balanced_tree.sales s
  join balanced_tree.product_details d 
  on s.prod_id = d.product_id
 where s.qty >= 1
group by 1,2
)
select * from penetration

--What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
