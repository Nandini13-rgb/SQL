danny ma case study 1
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Question 1 Query:
-- SELECT
--   	s.customer_id,
--     sum(m.price) as price
-- FROM dannys_diner.sales as s
-- join dannys_diner.menu as m
-- on s.product_id = m.product_id
-- group by s.customer_id;

-- Question 2 Query:
-- select
-- 	customer_id,
--     count(distinct(order_date))
-- from
-- 	dannys_diner.sales
-- group by customer_id

-- Question 3 Query:
-- with cte as (
--  select customer_id,
--   	product_id,
-- 	row_number()over(partition by customer_id order by order_date) as rn
--   from
-- 	dannys_diner.sales 
--   )
--   select s.customer_id,
--   	m.product_name
--     from cte as s
--     join dannys_diner.menu as m
--     on s.product_id = m.product_id
--     where rn =1;

-- Question 4 Query:
-- select 
-- 	s.product_id,
-- 	count(s.product_id) as count,
--     m.product_name
-- from
-- 	dannys_diner.sales as s
-- join
-- 	dannys_diner.menu as m
-- on 
-- 	s.product_id = m.product_id
-- group by s.product_id, m.product_name
-- order by 
-- 	count(s.product_id) desc
-- limit 1;


-- Question 5 Query
-- with cte as(
--   select 
-- 	s.product_id,
--     s.customer_id,
-- 	count(s.product_id) over(partition by s.customer_id) as count,
--     m.product_name,
--   	row_number()over(partition by s.customer_id order by count(s.product_id) desc) as rn
-- from
-- 	dannys_diner.sales as s
-- join
-- 	dannys_diner.menu as m
-- on 
-- 	s.product_id = m.product_id
-- group by s.product_id, m.product_name, s.customer_id)
-- select *
-- from cte
-- where rn = 1;

-- Question 6 Query
-- with cte as(
-- select s.customer_id, s.product_id,
-- row_number()over(partition by s.customer_id order by s.order_date) as rn
-- from dannys_diner.sales as s
-- join dannys_diner.members as m
-- on s.customer_id = m.customer_id
-- where 
-- s.order_date > (m.join_date))
-- select
-- c.customer_id,
-- m.product_name
-- from cte as c 
-- join dannys_diner.menu as m on c.product_id = m.product_id
-- where rn = 1

-- Question 7 Query

-- with cte as(
-- select s.customer_id, s.product_id,
-- row_number()over(partition by s.customer_id order by s.order_date desc) as rn
-- from dannys_diner.sales as s
-- join dannys_diner.members as m
-- on s.customer_id = m.customer_id
-- where 
-- s.order_date < (m.join_date))
-- select
-- c.customer_id,
-- m.product_name
-- from cte as c 
-- join dannys_diner.menu as m on c.product_id = m.product_id
-- where rn = 1

-- Question 8 Query

-- with cte as(
-- select s.customer_id, 
--   count(s.product_id) as total_item,
--   sum(m.price) as total_spent
-- from dannys_diner.sales as s
-- left join dannys_diner.menu as m on  s.product_id = m.product_id
-- left join dannys_diner.members as mem on s.customer_id = mem.customer_id
-- where 
-- s.order_date < (mem.join_date)
-- group by s.customer_id
-- )
-- select
-- *
-- from cte

-- Question 9 query
-- select s.customer_id,
-- sum(case when m.product_name = 'sushi' then m.price*2*10
--     else m.price*10
--     end) as total_spent
-- from dannys_diner.sales as s
-- join dannys_diner.menu as m
-- on s.product_id = m.product_id
-- group by s.customer_id

-- Question 10 Query
with cte as(
select
  	customer_id,
  	join_date + interval '6 day' AS valid_date, 
      date_trunc('month', join_date) + interval '1 month' - interval '1 day' AS last_date,
    join_date 
from 
    dannys_diner.members
)
select s.customer_id,
	sum(case when s.order_date between c.join_date and  c.valid_date  then m.price*20
	else
	m.price*10
    end) as total_spent
from
    dannys_diner.sales as s
join cte as c on s.customer_id = c.customer_id
join dannys_diner.menu as m on s.product_id = m.product_id
where s.order_date < c.last_date
group by 
s.customer_id

-- bonus question 1
SELECT
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    case
    when mem.join_date is null then 'N'
    when mem.join_date>s.order_date then 'N'
    else 'Y'
    end as member

FROM dannys_diner.sales as s
join dannys_diner.menu as m on s.product_id = m.product_id
join dannys_diner.members as mem on s.customer_id = mem.customer_id
;

