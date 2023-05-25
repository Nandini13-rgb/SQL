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

-- Question 4 Query:
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
select order_id, runner_id, cast(pickup_time as timestamp), cast(distance as numeric),duration from cte
)
select o.customer_id,round(avg(c.distance),1) as avg_distance from cte2 as c
join pizza_runner.customer_orders as o on
c.order_id = o.order_id
group by o.customer_id
;

