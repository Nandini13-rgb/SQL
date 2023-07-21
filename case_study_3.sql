--Section B
--Question 1
SELECT count(distinct customer_id) as total_customers FROM foodie_fi.subscriptions;

--Question 2
SELECT 
-- extract(month from start_date) as month,
to_char(start_date, 'Month') as months,
count(plan_id)
FROM foodie_fi.subscriptions 
where plan_id = 0
group by to_char(start_date, 'Month')
order by 1


--Question 3
  SELECT 
s.plan_id,
plan_name,
count(plan_id) as events
FROM foodie_fi.subscriptions s
join foodie_fi.plans using(plan_id)
where extract(year from start_date) > 2020
group by 1, 2
order by 1


--Question 4
SELECT 
count(distinct customer_id) as total_customers,
concat(round(100*count(distinct customer_id)::decimal/(select count(distinct customer_id) from foodie_fi.subscriptions),2), '%') as percentage
FROM foodie_fi.subscriptions s
join foodie_fi.plans using(plan_id)
where plan_name = 'churn'

--Question 5
  with plan as (SELECT 
customer_id,
plan_id,
row_number()over(partition by customer_id order by plan_id)
from foodie_fi.subscriptions)
select count(distinct customer_id) as total_customers,
round(100*count(distinct customer_id)::decimal/(select count(distinct customer_id) from foodie_fi.subscriptions),2) as percentage
from plan
where plan_id = 4 and row_number = 2


  
--Question 8
SELECT count(distinct customer_id) as pro_customers 
FROM foodie_fi.subscriptions 
where extract(year from start_date) = 2020 and plan_id = (select plan_id from foodie_fi.plans where plan_name = 'pro annual');


--Question 9
with cte as (
SELECT customer_id, start_date as convert_date 
FROM foodie_fi.subscriptions 
where plan_id in (select plan_id from foodie_fi.plans where plan_name = 'pro annual')),
temp as (
  select c.customer_id, s.start_date, c.convert_date
  from cte as c
  left join foodie_fi.subscriptions as s
  on c.customer_id = s.customer_id
  )

select round(avg(convert_date-start_date)) from temp
where convert_date -start_date <> 0;

select round(avg(s.start_date - c.start_date))
  from foodie_fi.subscriptions as c
  left join foodie_fi.subscriptions as s
  on c.customer_id = s.customer_id
   and s.plan_id = c.plan_id + 3
   and s.plan_id = 3
  
  
  
  
  --Question 10
  WITH duration_table AS (
  SELECT s2.start_date - s1.start_date AS duration,
  WIDTH_BUCKET(s2.start_date - s1.start_date, 1, 360, 12) AS bin
  FROM foodie_fi.subscriptions s1
  JOIN foodie_fi.subscriptions s2
  ON s1.customer_id = s2.customer_id
   AND s1.plan_id +  3 = s2.plan_id
  WHERE s2.plan_id = 3
  ORDER BY duration 
 )
 SELECT CONCAT((bin-1)*30+1,' - ',bin*30,' days') AS breakdown, 
  ROUND(AVG(duration)) AS avg_in_days,
  COUNT(bin) AS customers
 FROM duration_table
 GROUP BY bin;
 
 
 --Question 11
 WITH downgrade_table AS (
  SELECT distinct s1.customer_id
  FROM foodie_fi.subscriptions s1
  JOIN foodie_fi.subscriptions s2
  ON s1.customer_id = s2.customer_id
   AND s1.plan_id - 1  = s2.plan_id 
  WHERE s2.plan_id = 1 and s2.start_date > s1.start_date and extract(year from s2.start_date) = 2020
 )
  select count(*) from downgrade_table
  
  
  
  
  
  --Section C
  with recursive cte as(
  select s.customer_id, s.plan_id, p.plan_name, s.start_date,
price as amount,
lead(start_date)over(partition by s.customer_id order by s.start_date, s.plan_id) as cutoff_date
from foodie_fi.subscriptions as s join
foodie_fi.plans as p on
s.plan_id = p.plan_id
where extract(year from start_date) = 2020 and s.plan_id not in (0,4)),
cte2 as (select customer_id,plan_id,plan_name,start_date,amount,
         coalesce(cutoff_date, '2020-12-31') as cutoff_date
         from cte),
cte3 as(
  select customer_id, plan_id, plan_name,start_date,amount,cutoff_date
  from cte2
  union 
  select customer_id, plan_id, plan_name,
  date(start_date + interval '1 month') as start_date, amount,cutoff_date
  from cte3
  where cutoff_date > (start_date + interval '1 month')
  and plan_name <> 'pro annual'
)
cte4 AS (
 SELECT *, 
   LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) 
    AS last_payment_plan,
   LAG(amount, 1) OVER(PARTITION BY customer_id ORDER BY start_date) 
    AS last_amount_paid,
   RANK() OVER(PARTITION BY customer_id ORDER BY start_date) AS payment_order
 FROM cte3
 ORDER BY customer_id, start_date
)
SELECT customer_id, plan_id, plan_name, start_date AS payment_date, 
 (CASE 
   WHEN plan_id IN (2, 3) AND last_payment_plan = 1 
    THEN amount — last_amount_paid
   ELSE amount
 END) AS amount, payment_order
FROM cte4;

