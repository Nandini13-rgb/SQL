with cte as (SELECT 
             to_date(week_date, 'dd/mm/yy') as week_date,
             region,
             platform,
             segment,
             customer_type,
             transactions,
             sales
FROM data_mart.weekly_sales),
temp as (select week_date,
               extract(week from week_date) as week_number,
               extract(month from week_date) as month_number,
               extract(year from week_date) as calendar_year,
               region,
               platform,
               case when segment = 'null' then 'unknown'
               else segment
               end as segment,
               case when segment like '%1' then 'Young Adults'
               when segment like '%2' then 'Middle Aged'
               when segment like '%3' or segment like '%4' then 'Retirees'
               else 'unknown' 
               end as age_band,
               case when segment like 'C%' then 'Couples'
               when segment like 'F%' then 'Families'
               else 'unknown'
               end as demographic,
               customer_type,
               transactions,
         round(sales/transactions,2) as avg_transactions,
         sales
from cte)
--1 
select distinct(extract(dow from week_date)) from temp;
--2
select distinct(week_number)from temp
order by 1;

--3
select calendar_year, count(transactions) as total_transactions from temp
group by calendar_year;
--4
select region, month_number, sum(sales) as total_sales
from temp
group by region, month_number
order by month_number, region
--5
select platform, count(transactions) as total_transactions from temp group by platform
--6
    sales as (
select month_number, 
  sum(case when platform = 'Retail' then sales end) as retail_sales,
sum(case when platform = 'Shopify' then sales end) as shopify_sales,
sum(sales) as total_sales
from temp
group by month_number)
select month_number, 
  100.00*retail_sales/total_sales*1.00 as  retails, 
100.00*shopify_sales/total_sales*1.00 as shopify
  from sales
order by 1
  
--7
  sales as (
select month_number, 
  sum(case when demographic = 'Couples' then sales end) as Couple_sales,
sum(case when demographic = 'Families' then sales end) as Family_sales,
sum(sales) as total_sales
from temp
group by month_number)
select month_number, 
  100.00*Couple_sales/total_sales*1.00 as Couples, 
100.00*Family_sales/total_sales*1.00 as Family
from sales
order by 1
--8
sales as (
  select age_band,
  demographic,
  sum(case when platform = 'Retail' 
      then sales
      end) as retail_Sales
  from temp
  where platform = 'Retail'
  group by age_band,
  demographic
order by retail_Sales desc)
  select * from sales limit 1
--9
select calendar_year, platform,
round(sum(sales)/sum(transactions),2) as correct_avg,
avg(avg_transactions) as wrong_avg
from temp
group by calendar_year, platform
order by calendar_year, platform


C
--1
select sum(case when week_date < '2020-06-15' and week_date > (date '2020-06-15' - interval '4 weeks') then 
           sales    
          end) as befor_sales,
          sum(case when week_date > '2020-06-15' and week_date <(date '2020-06-15' + interval '4 weeks')  then 
           sales
          end) as after_sales 
          from temp;

--2
select sum(case when week_date < '2020-06-15' and week_date > (date '2020-06-15' - interval '12 month') then 
           sales    
          end) as befor_sales,
          sum(case when week_date > '2020-06-15' and week_date <(date '2020-06-15' + interval '12 month')  then 
           sales
          end) as after_sales 
          from temp;


before_after_sales as (
select sum(case when week_date < '2020-06-15' and week_date > (date '2020-06-15' - interval '4 weeks') then 
           sales    
          end) as before_sales,
          sum(case when week_date > '2020-06-15' and week_date <(date '2020-06-15' + interval '4 weeks')  then 
           sales
          end) as after_sales 
          from temp)
select *,
after_sales - before_sales as variance,
round(100*(after_sales-before_sales)::numeric/ before_sales,2) as percentage
from before_after_sales;



--bonus question
before_after_sales as (
select region, sum(case when week_date < '2020-06-15' and week_date > (date '2020-06-15' - interval '12 month') then 
           sales    
          end) as before_sales,
          sum(case when week_date > '2020-06-15' and week_date < (date '2020-06-15' + interval '12 month') then 
           sales
          end) as after_sales 
          from temp
group by region)
select *
from before_after_sales;
   
