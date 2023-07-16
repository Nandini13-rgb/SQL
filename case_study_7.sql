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

SELECT TOP 1 s.prod_id, s2.prod_id, s3.prod_id, COUNT(*) AS [Combinations]
FROM balanced_tree.sales s 
JOIN balanced_tree.sales  s2 ON s2.txn_id = s.txn_id AND s.prod_id < s2.prod_id
JOIN balanced_tree.sales  s3 ON s3.txn_id = s.txn_id AND s2.prod_id < s3.prod_id
GROUP BY s.prod_id, s2.prod_id, s3.prod_id
ORDER BY Combinations DESC


--Reporting Challenge
with cte as (SELECT pd.category_id, 
pd.category_name AS Category, 
pd.product_id, 
pd.product_name AS Product, 
RANK() OVER(PARTITION BY pd.segment_id ORDER BY SUM(sls.qty)) AS Ranked_Products, 
pd.segment_id, 
pd.segment_name AS Segment, 
sls.txn_id AS Transactions, 
sls.member, 
ROUND(100.0 * COUNT(sls.member)/(SELECT COUNT(member) FROM balanced_tree.sales),2) AS Member_Percentage, 
COUNT(DISTINCT sls.txn_id) AS Number_of_Transactions, 
SUM(qty) AS Total_quantity_products, 
SUM(sls.qty * sls.price) AS Total_Revenue_before_discounts, ROUND(SUM(sls.qty * sls.price * (discount/100)), 2) AS Total_Discount,
  extract(month from start_txn_time) AS Month, 
 extract(year from start_txn_time) AS Year
  FROM balanced_tree.sales sls
  INNER JOIN balanced_tree.product_details AS pd ON  sls.prod_id = pd.product_id
  WHERE extract(month from start_txn_time) = 1 AND extract(year from start_txn_time) = '2021'
  GROUP BY extract(year from start_txn_time), extract(year from start_txn_time), txn_id, member, pd.product_id, pd.product_name, pd.segment_id, pd.segment_name, pd.category_id, pd.category_name,sls.start_txn_time),
  temp as (
    SELECT *, 
    ROUND(AVG(Total_quantity_products), 2) AS avg_unique_products, 
    ROUND(AVG(Total_Revenue_before_discounts), 2) AS Average_Revenue, 
    ROUND(AVG(Total_Discount), 2) AS Average_Discount,
  PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY Total_Revenue_before_discounts)  AS percentile_25,
  PERCENTILE_DISC(0.50) WITHIN GROUP(ORDER BY Total_Revenue_before_discounts)  AS percentile_50,
  PERCENTILE_DISC(0.75) WITHIN GROUP(ORDER BY Total_Revenue_before_discounts)  AS percentile_75
    from cte
    GROUP BY Number_of_Transactions, Total_Discount, Total_quantity_products, Total_Revenue_before_discounts, Month, Year, Transactions, member, Member_Percentage, product_id, Product, segment_id, Segment, Ranked_Products, Category, category_id
)

    select * from cte
  
--bonus question
with cte as(
select id, parent_id,
level_text,
level_name
from balanced_tree.product_hierarchy
where id >= 7),
temp as (
  select c.id, p.parent_id, c.level_text as c_level_text,
  c.level_name as c_level_name,
  p.level_text as p_level_text,
  p.level_name as p_level_name
  from cte as c 
  join balanced_tree.product_hierarchy as p
  on c.parent_id = p.id),
  final as(
    select t.id,
    t.parent_id,
    t.c_level_text,
    t.c_level_name,
    t.p_level_text,
    t.p_level_name,
    p.level_text,
    p.level_name
    from temp as t
    join balanced_tree.product_hierarchy as p
  on t.parent_id = p.id),
  final2 as (select id,
             concat(c_level_text, ' ', p_level_text, ' ', level_text) as product_name,
             case when c_level_name = 'Style'
             then id
             end as style_id,
             c_level_text as style_name,
             case when p_level_text = 'Jeans' then 3
             when p_level_text = 'Jacket' then 4
             when p_level_text = 'Shirt' then 5
             when p_level_text  = 'Socks' then 6
             end as segment_id,
            p_level_text as segment_name,
            case when level_text = 'Womens' then 1
            when level_text = 'Mens' then 2
            end as category_id,
            level_text as category_name
            from final),
 final3 as (
   select p.product_id,
   p.price,
   f.product_name,
   f.category_id,
   f.segment_id,
   f.style_id,
   f.category_name,
   f.segment_name,
   f.style_name
   from final2 f
   join balanced_tree.product_prices p
   on f.id = p.id)
  
  select * from final3
