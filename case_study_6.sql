-- Section 1

--question 1
select count(distinct user_id) as total_users 
from clique_bait.users

  --question 2
  with cte as(SELECT user_id,
count(cookie_id) as cookies
FROM clique_bait.users 
group by 1
order by 1)
select user_id,
round(avg(cookies),2) as avg_cookies
from 
cte
group by 1
order by 1
;
  --question 3
  select u.user_id,
extract(month from u.start_date) as month,
count(distinct e.visit_id) as total_visits
from clique_bait.users as u
join clique_bait.events as e
on u.cookie_id = e.cookie_id
group by 1, 2
order by 1
   
--question 4

SELECT e.event_type, i.event_name, count(e.event_type) as total_events FROM clique_bait.events as e
join clique_bait.event_identifier as i 
on e.event_type = i.event_type
group by e.event_type, i.event_name
order by 1;


--question 5
SELECT 100*count(visit_id)/(1.0*(select count(visit_id) from clique_bait.events)) as purchase_percentage
FROM clique_bait.events 
where event_type = 3

--question 6
SELECT 100*count(visit_id)/(1.0*(select count(visit_id) from clique_bait.events)) as total_visits_without_purchase
FROM clique_bait.events 
where event_type != 3 and page_id = (select page_id from clique_bait.page_hierarchy where page_name = 'Checkout')

--question 7
SELECT e.page_id, 
p.page_name,
count(e.visit_id) as total_views
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
group by 1,2
order by total_views desc
limit 3

--question 8
SELECT 
p.product_category,
sum (case when e.event_type = 1 then 1
     else 0
     end) as page_views
sum (case when e.event_type = 2 then 1
     else 0
     end) as added_to_cart
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
group by 1

--question 9
with purchase as(
  select visit_id,
event_type
from clique_bait.events
where event_type = 3),

cart_add as(
	select e.page_id,
p.product_id,
e.visit_id
from clique_bait.events e
join clique_bait.page_hierarchy p
using(page_id)
where event_type = 2),

total_purchase as (
	select 
c.product_id,
count(p.visit_id) as total_products
from purchase p
join cart_add c
on p.visit_id=c.visit_id
group by 1)

select 
product_id,
total_products
from total_purchase 
order by 2 desc
limit 3;





--Section 3  Product funnel Analysis
create table product_details as(
SELECT 
p.product_category,
p.product_id,
sum (case when e.event_type = 1 then 1
     else 0
     end) as page_views,
sum (case when e.event_type = 2 then 1
     else 0
     end) as added_to_cart,
sum (case when e.event_type = 2 and visit_id not in (select visit_id from clique_bait.events where event_type = 3)
     then 1
     else 0
     end) as abondoned,
sum (case when e.event_type = 2 and visit_id in (select visit_id from clique_bait.events where event_type = 3)
     then 1
     else 0
     end) as purchased
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where p.product_id is not null and p.product_category is not null
group by 1,2
  );

select * from product_details;


create table product_category_details as(
SELECT 
p.product_category,
sum (case when e.event_type = 1 then 1
     else 0
     end) as page_views,
sum (case when e.event_type = 2 then 1
     else 0
     end) as added_to_cart,
sum (case when e.event_type = 2 and visit_id not in (select visit_id from clique_bait.events where event_type = 3)
     then 1
     else 0
     end) as abondoned,
sum (case when e.event_type = 2 and visit_id in (select visit_id from clique_bait.events where event_type = 3)
     then 1
     else 0
     end) as purchased
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where p.product_id is not null and p.product_category is not null
group by 1
  );
 select * from product_category_details


create table product_category_details as(
with page_views as(
SELECT 
p.product_category,
count(*) as total_views
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where p.product_id is not null and p.product_category is not null
group by 1),
add_to_cart as (
SELECT 
p.product_category,
count(*) as added_to_cart
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where e.event_type = 2 and p.product_id is not null 
group by 1),
abondoned as (
SELECT 
p.product_category,
count(*) as total_abondoned
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where e.event_type = 2 and
  p.product_id is not null and e.visit_id not in (select visit_id from clique_bait.events where event_type = 3)
group by 1),

purchased as (
  SELECT 
p.product_category,
count(*) as total_purchased
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
where e.event_type = 2 and
  p.product_id is not null and e.visit_id in (select visit_id from clique_bait.events where event_type = 3)
group by 1),
product_category_wise_details as (
select v.product_category, v.total_views,
a.added_to_cart,
p.total_purchased
from page_views as v 
join add_to_cart as a using(product_category)
join purchased as p using(product_category)
 )
select * from product_category_wise_details
  );



-- Which product had the most views, cart adds and purchases?
--Which product was most likely to be abandoned?
with cte as(
select *,
        rank()over(order by total_views desc) as view_rank,
        rank()over(order by added_to_cart desc) as add_cart_rank,
        rank()over(order by total_abondoned desc) as abondoned_rank,
        rank()over(order by total_purchased desc) as purchase_rank
        from product_category_details)
        
select product_category as most_viewed from cte where view_rank = 1


--Which product had the highest view to purchase percentage?
 with cte as(
select *,
       round((100*total_purchased)/(total_views*1.0), 2) as view_purchase_ratio
        from product_category_details)
select * from cte
order by view_purchase_ratio desc
limit 1

--What is the average conversion rate from view to cart add?
 with cte as(
select
       avg(round((100*added_to_cart)/(total_views*1.0), 2)) as avg_view_to_cart_ratio
        from product_category_details)
select * from cte
--What is the average conversion rate from cart add to purchase?
 with cte as(
select
       avg(round((100*total_purchased)/(added_to_cart*1.0), 2)) as avg_cart_to_purchase_ratio
        from product_category_details)
select * from cte



-- Section 3 Campaign Analysis
with cte as(SELECT distinct e.visit_id, u.user_id,
min(e.event_time) as visit_start_time,
count(e.page_id) as page_views,
sum(
  case when e.event_type = 2 and e.visit_id not in (select visit_id from clique_bait.events where event_type = 3)then 1
  else 0
  end) as cart_adds,
sum(
  case when e.event_type = 4 then 1
  else 0
  end) as impressions,
sum(
  case when e.event_type = 5 then 1
  else 0
  end) as click,
count(case when e.event_type = 3 then 1
else null
end )as purchase_flag
FROM clique_bait.events e
join clique_bait.users u using(cookie_id)
group by e.visit_id, u.user_id
order by 2),
temp as (
select c.visit_id,
c.user_id,
c.visit_start_time,
c.page_views,
c.cart_adds,
c.impressions,
c.click,
case when c.purchase_flag >= 1 then true
else false
end as purchase,
ci.campaign_name
from cte as c join clique_bait.campaign_identifier as ci on c.visit_start_time between ci.start_date and ci.end_date)
select campaign_name, count(purchase) from temp 
where purchase = 'true'
group by campaign_name;
