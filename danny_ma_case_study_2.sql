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

