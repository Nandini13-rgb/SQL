section a
--question 1
SELECT COUNT(distinct node_id) as total_nodes FROM data_bank.customer_nodes;

--question 2
select region_id, count(distinct node_id)
from data_bank.customer_nodes
group by region_id;


--question 3
select region_id, count(distinct customer_id)
from data_bank.customer_nodes
group by region_id;

--question 4
select round(avg(end_date-start_date ),2) as rellocation_days
from data_bank.customer_nodes
where end_date <> '9999-12-31'

--question 5
with reallocation as (
  select region_id, (end_date-start_date) as reallocation_days
from data_bank.customer_nodes
where end_date <> '9999-12-31'
),
percentile as (
  select region_id, reallocation_days,
  percent_rank()over(partition by region_id order by reallocation_days)*100 as p
  from reallocation
  )
  select region_id, reallocation_days from percentile where p>95
  group by region_id, reallocation_days



Section B
--question 1
select distinct txn_type, sum(txn_amount) as total_amount
from data_bank.customer_transactions 
group by txn_type


--question 2
select customer_id, count(txn_type), sum(txn_amount) as total_amount
from data_bank.customer_transactions 
where txn_type = 'deposit'
group by customer_id
