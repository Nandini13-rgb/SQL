--Section A
--Question 1
SELECT
	COUNT(order_id) AS orders
FROM pizza_runner.customer_orders


--Question 2
  SELECT
	COUNT(distinct order_id) AS orders
FROM pizza_runner.customer_orders


--Question 3
  SELECT
	runners.runner_id,
    runners.registration_date,
	COUNT(DISTINCT runner_orders.order_id) AS orders
FROM pizza_runner.runners
INNER JOIN pizza_runner.runner_orders
	ON runners.runner_id = runner_orders.runner_id
WHERE runner_orders.cancellation IS NOT NULL
GROUP BY
	runners.runner_id,
  runners.registration_date;

--Question 4
select c.pizza_id,
p.pizza_name,
count(c.pizza_id) as total_pizzas
from pizza_runner.customer_orders c
join pizza_runner.pizza_names p
using(pizza_id)
group by c.pizza_id, p.pizza_name
order by 1;

--Question 5
select c.customer_id,
c.pizza_id,
p.pizza_name,
count(c.pizza_id) as total_pizzas
from pizza_runner.customer_orders c
join pizza_runner.pizza_names p
using(pizza_id)
group by c.customer_id, c.pizza_id, p.pizza_name
order by 1;


--Question 6
with orders as (select c.order_id,
count(c.pizza_id) as total_pizzas
from pizza_runner.customer_orders c
join pizza_runner.pizza_names p
using(pizza_id)
group by c.order_id
order by 1)
select * 
from orders
where total_pizzas = (select max(total_pizzas) from orders);

--Question 7
with orders as (select customer_id,
case when extras = '' or extras = 'null' then null
  else extras
  end as extras,
case when exclusions = '' or exclusions = 'null' then null
  else exclusions
  end as exclusions              
from pizza_runner.customer_orders            
)
select customer_id, 
sum(case when extras is null and exclusions is null then 1
    else 0
    end) as no_change,
sum(case when extras is not null or exclusions is not null then 1
    else 0
    end) as any_change
from orders
group by 1
order by 1;

--Question 8
with orders as (select customer_id,
case when extras = '' or extras = 'null' then null
  else extras
  end as extras,
case when exclusions = '' or exclusions = 'null' then null
  else exclusions
  end as exclusions              
from pizza_runner.customer_orders            
)
select
sum(case when extras is not null and exclusions is not null then 1
    else 0
    end) as total_pizza_with_both_changes
from orders
;

-- Question 9 Query:
with cte as(
select
*,
extract(hour from order_time) as hour,
extract(day from order_time) as day
from
pizza_runner.customer_orders)
select 
hour,
count(pizza_id) as total_volume
from cte
group by hour

-- Question 10 Query:
select
to_char(order_time, 'day') as day,
count(pizza_id) as total_pizza
from
pizza_runner.customer_orders
group by 
day
order by total_pizza;


--Section B
--Question 2 Query
with orders as (
  select r.runner_id, r.order_id,
  cast((case when r.pickup_time = '' or r.pickup_time = 'null' then null
  else r.pickup_time
  end ) as timestamp),
  c.order_time
FROM pizza_runner.runner_orders r
join pizza_runner.customer_orders c
on r.order_id = c.order_id),

total_time as (
  select runner_id,
extract(minutes from pickup_time - order_time) as total_minutes
from orders
group by 1, pickup_time, order_time)

select runner_id,
round(avg(total_minutes)::numeric,2) as avg_minutes
from total_time
group by 1
order by 1;

--Question 3 Query
with orders as (
  select r.runner_id, r.order_id,
  cast((case when r.pickup_time = '' or r.pickup_time = 'null' then null
  else r.pickup_time
  end ) as timestamp),
  c.order_time
FROM pizza_runner.runner_orders r
join pizza_runner.customer_orders c
on r.order_id = c.order_id),

total_time as (
  select runner_id,
extract(minutes from pickup_time - order_time) as total_minutes
from orders
group by 1, pickup_time, order_time)

select distinct t.runner_id,
round(avg(t.total_minutes)::numeric,2) as avg_minutes,
count(r.order_id)  as total_pizza
from total_time t
join pizza_runner.runner_orders r
using(runner_id)
group by 1, r.order_id
order by 1;

  
-- Question 4 Query:
with cleaning as(
  select order_id,
  runner_id,
  case when pickup_time = 'null' then null
  	else pickup_time
  	end as pickup_time,
  case when distance = 'null' then null
  	when distance like '%km' then trim('km' from distance)
  	else distance
  	end as distance,
  cancellation
  from pizza_runner.runner_orders
  ),
  cte as(
select order_id, runner_id, cast(pickup_time as timestamp), cast(distance as numeric) from cleaning
)
select o.customer_id,round(avg(c.distance),1) as avg_distance from cte2 as c
join pizza_runner.customer_orders as o on
c.order_id = o.order_id
group by o.customer_id
;


-- Question 6 Query:
with cte as(
  select order_id,
  runner_id,
  case when pickup_time = 'null' then null
  	else pickup_time
  	end as pickup_time,
  case when distance = 'null' then null
  	when distance like '%km' then trim('km' from distance)
  	else distance
  	end as distance,
  case when duration = 'null' then null
  	when duration like '%mins' then trim('mins' from duration)
    when duration like '%minutes' then trim('minutes' from duration)
  	when duration like '%minute' then trim('minute' from duration)
  	else duration
  	end as duration,
  cancellation
  from pizza_runner.runner_orders
  ),
  cte2 as(
select order_id, runner_id, cast(pickup_time as timestamp), cast(distance as numeric),cast(duration as numeric) from cte
)
select max(duration)-min(duration) as difference from cte2

  
  --Question 5
  with cte as (
  select order_id, runner_id,
  cast((case when duration = '' or duration = 'null' then null
  	when duration like '%minutes' then trim(' minutes' from duration)
    when duration like '%mins' then trim(' mins' from duration)
    when duration like '% minute' then trim(' minute' from duration)
  	else duration
  end) as integer) as duration
  from pizza_runner.runner_orders
  )
  select (max(duration)-min(duration)) as diff_minutes from cte
  
  --Question 6
  with cte as (
  select order_id, runner_id,
  cast((case when duration = '' or duration = 'null' then null
  	when duration like '%minutes' then trim(' minutes' from duration)
    when duration like '%mins' then trim(' mins' from duration)
    when duration like '% minute' then trim(' minute' from duration)
  	else duration
  end) as integer) as duration,
  cast((case when distance = '' or distance = 'null' then null
  	when distance like '%km' then trim('km' from distance)
  	else distance
  end) as  decimal) as distance
  from pizza_runner.runner_orders
  )
  select runner_id, order_id, (distance * 60/duration) as speed from cte
  where distance is not null
  group by runner_id, order_id, distance, duration
  order by runner_id
  
  
  --Question 7
  with cte as (
  select order_id, runner_id,
  cast((case when distance = '' or distance = 'null' then null
  	when distance like '%km' then trim('km' from distance)
  	else distance
  end) as  decimal) as distance
  from pizza_runner.runner_orders
  ),
  cte2 as (
  select runner_id, sum(case when distance is not null then 1
                        else 0 end) as distance_sum,
                        count(order_id) as total_orders
                        from cte
  group by runner_id)
  select runner_id, (distance_sum*100/total_orders) as per
  from cte2

  
  

C
--Question 1 Query
with pizza as (
  select distinct c.pizza_id,
  p.pizza_name, 
  r.toppings 
  from 
pizza_runner.customer_orders as c
join pizza_runner.pizza_names as p on c.pizza_id = p.pizza_id
join pizza_runner.pizza_recipes as r on c.pizza_id = r.pizza_id),
toppings as (
select
pizza_name, 
cast(unnest(string_to_array(toppings, ',')) as integer) as topping_id
from pizza),
cte3 as (
  select c.pizza_name, 
  p.topping_name
  from toppings as c
  join pizza_runner.pizza_toppings as p 
  on c.topping_id = p.topping_id)
select pizza_name, 
string_agg(topping_name,',') as toppings 
from cte3 group by pizza_name;




--Question 2 query
with cleaning as (
  select
  case when extras = '' or extras = 'null' then null
  else extras
  end as extras
from pizza_runner.customer_orders),
  extra as (
    select unnest((string_to_array(extras,','))) as extras from cleaning),
 extra_count as (select extras, count(extras) as count from extra group by extras),
 cte4 as (select cast(extras as integer) from extra_count order by count desc limit 1)
    select topping_name from pizza_runner.pizza_toppings as p
    join cte4 as c on p.topping_id = c.extras;
   
--Question 3 query
    with cte as (
  select
  case when exclusions = 'null' then null
  else exclusions
  end as exclusions
from pizza_runner.customer_orders),
  cte2 as (
    select unnest((string_to_array(exclusions,','))) as exclusions from cte),
    cte3 as (select exclusions, count(exclusions) as count from cte2 group by exclusions),
    cte4 as (select cast(exclusions as integer) from cte3 order by count desc limit 1)
    select topping_name from pizza_runner.pizza_toppings as p
    join cte4 as c on p.topping_id = c.exclusions;
