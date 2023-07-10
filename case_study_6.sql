-- Section 1

--question 1
select count(distinct user_id) as total_users 
from clique_bait.users

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
count(e.visit_id) as total_views,
sum (
  case when event_type = 2 then 1
  else 0
  end) as add_cart
FROM clique_bait.events as e
join clique_bait.page_hierarchy as p
on e.page_id = p.page_id
group by 1

--question 9
all the evnt_type of purchase have null in product_category
