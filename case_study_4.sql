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
select customer_id, count(txn_type) as deposit_counts, sum(txn_amount) as total_amount
from data_bank.customer_transactions 
where txn_type = 'deposit'
group by customer_id

--question 3 For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with counts as (SELECT customer_id,
extract(month from txn_date) as month,
sum(case
    when txn_type = 'deposit' then 1
    else 0
    end) as deposit_count,
sum(case when txn_type = 'purchase' then 1
    else 0
    end) as purchase_count,
 sum(case when txn_type = 'withdraw' then 1
    else 0
    end) as withdraw_count   
FROM data_bank.customer_transactions
group by 1,2)

select month, count(customer_id) as total_customers
from counts
where deposit_count > 1 and (purchase_count = 1 or withdraw_count = 1)
group by 1
order by 1

--question 4
  with counts as (SELECT customer_id,
extract(month from txn_date) as month,
sum(case
    when txn_type = 'deposit' then txn_amount   
    else -txn_amount
    end) as balance
FROM data_bank.customer_transactions
group by 1,2)

select customer_id, month, sum(balance) as total_balance
from counts
group by 1, 2
order by 1


  --question 5
  with counts as (SELECT customer_id,
extract(month from txn_date) as month,
sum(case
    when txn_type = 'deposit' then txn_amount   
    else -txn_amount
    end) as balance
FROM data_bank.customer_transactions
group by 1,2),

closing_balance as (select customer_id, month, sum(balance) as total_balance
from counts
group by 1, 2
order by 1, 2),

cte as (select customer_id, total_balance, lag(total_balance,1)over(partition by customer_id order by month) as prev_balance,
(lag(total_balance,1)over(partition by customer_id order by month))-total_balance as diff
from closing_balance),

temp as(

select customer_id, 100*diff/prev_balance as per_balance
from cte)

select round(100*count(customer_id)::decimal/(select count(customer_id) from data_bank.customer_transactions),2) as total_customers
from temp where per_balance > 5

Section C
with net_transactions as (SELECT customer_id,
txn_type,
txn_date,
sum(case when txn_type = 'deposit' then txn_amount
    else -txn_amount
    end) as net_transactions
    FROM data_bank.customer_transactions
    group by customer_id, txn_type, txn_date
    order by customer_id, txn_date
    ),
    running_balance as(
      select customer_id,
      txn_type,
      txn_date,
      net_transactions,
      sum(net_transactions)over(partition by customer_id order by txn_date) as running_balance
          from net_transactions
      order by customer_id, txn_date
)
      select * from running_balance;



--customer balance at the end of each month
with net_transactions as (SELECT customer_id,
extract(month from txn_date) as txn_month,
sum(case when txn_type = 'deposit' then txn_amount
    else -txn_amount
    end) as net_transactions
    FROM data_bank.customer_transactions
    group by customer_id, txn_month
    order by customer_id, txn_month
    ),
    month_end_balance as(
      select customer_id,
      txn_month
      net_transactions,
      sum(net_transactions)over(partition by customer_id, txn_month order by txn_month) as month_end_balance
          from net_transactions
      order by customer_id, txn_month
)
      select * from month_end_balance;

--minimum, average and maximum values of the running balance for each customer
with net_transactions as (SELECT customer_id,
txn_type,
txn_date,
sum(case when txn_type = 'deposit' then txn_amount
    else -txn_amount
    end) as net_transactions
    FROM data_bank.customer_transactions
    group by customer_id, txn_type, txn_date
    order by customer_id, txn_date
    ),
    running_balance as(
      select customer_id,
      txn_type,
      txn_date,
      net_transactions,
      sum(net_transactions)over(partition by customer_id order by txn_date) as running_balance
          from net_transactions
      order by customer_id, txn_date
)
      select customer_id, min(running_balance) as min_balance,
      max(running_balance) as max_balance,
      round(avg(running_balance)) as avg_balance
      from running_balance
      group by customer_id;


--option 1
with net_transactions as (SELECT customer_id,
extract(month from txn_date) as txn_month,
sum(case when txn_type = 'deposit' then txn_amount
    else -txn_amount
    end) as net_transactions
    FROM data_bank.customer_transactions
    group by customer_id, txn_month
    order by customer_id, txn_month
    ),
    month_end_balance as(
      select customer_id,
      txn_month,
      net_transactions,
      sum(net_transactions)over(partition by customer_id, txn_month order by txn_month) as month_end_balance
          from net_transactions
      order by customer_id, txn_month
)
      select txn_month, sum(month_end_balance) as data from month_end_balance
      group by txn_month
      order by txn_month;
