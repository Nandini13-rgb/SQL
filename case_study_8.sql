-- Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

alter table fresh_segments.interest_metrics alter column month_year type varchar(15);
update fresh_segments.interest_metrics set  month_year = to_date(month_year, 'MM-YYYY');
alter table fresh_segments.interest_metrics alter column month_year type date using month_year :: date;

-- What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT to_date(month_year, 'MM-YYYY') as month_year, count(*) FROM fresh_segments.interest_metrics 
group by 1
order by month_year nulls first;

-- What do you think we should do with these null values in the fresh_segments.interest_metrics
We could delete these rows
or we could these values with the relative data
delete from fresh_segments.interest_metrics where month_year is null;

--What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
with cte as(
  SELECT cast(interest_id as integer) as interest_id,
  _month,
  _year,
  month_year,
  composition,
  index_value,
  ranking,
  percentile_ranking
  FROM
  fresh_segments.interest_metrics 
  ),
  temp as(
  select c.*,
  m.*
  from cte c
  left join fresh_segments.interest_map m
  on c.interest_id = m.id)
  select * from temp where interest_id = 21246;
--Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
alter table fresh_segments.interest_metrics alter column month_year type varchar(15);
update fresh_segments.interest_metrics set  month_year = to_date(month_year, 'MM-YYYY');
alter table fresh_segments.interest_metrics alter column month_year type date using month_year :: date;
with cte as(
  SELECT cast(interest_id as integer) as interest_id,
  _month,
  _year,
  month_year,
  composition,
  index_value,
  ranking,
  percentile_ranking
  FROM
  fresh_segments.interest_metrics 
  ),
  temp as(
  select c.*,
  m.*
  from cte c
  left join fresh_segments.interest_map m
  on c.interest_id = m.id)
  select * from temp where month_year < created_at;

This could not be valid because how a client could interact with a interest_id which is not even created.

-- Which interests have been present in all month_year dates in our dataset?
alter table fresh_segments.interest_metrics alter column month_year type varchar(15);
update fresh_segments.interest_metrics set  month_year = to_date(month_year, 'MM-YYYY');
alter table fresh_segments.interest_metrics alter column month_year type date using month_year :: date;
with cte as(
  SELECT cast(interest_id as integer) as interest_id,
  _month,
  _year,
  month_year,
  composition,
  index_value,
  ranking,
  percentile_ranking
  FROM
  fresh_segments.interest_metrics 
  )
  select interest_id, count(month_year) from cte
  group by interest_id
  having count(month_year) = (select count(distinct month_year) from cte)
-- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
 temp as(
  select interest_id, count(month_year) from cte
  group by interest_id
  having count(month_year) < (select count(distinct month_year) from cte))
  select count(interest_id) from temp
--After removing these interests - how many unique interests are there for each month?
alter table fresh_segments.interest_metrics alter column month_year type varchar(15);
update fresh_segments.interest_metrics set  month_year = to_date(month_year, 'MM-YYYY');
alter table fresh_segments.interest_metrics alter column month_year type date using month_year :: date;
with cte as(
  SELECT cast(interest_id as integer) as interest_id,
  _month,
  _year,
  month_year,
  composition,
  index_value,
  ranking,
  percentile_ranking
  FROM
  fresh_segments.interest_metrics 
  ),
   temp as(
  select interest_id, count(month_year) from cte
  group by interest_id
  having count(month_year) < (select count(distinct month_year) from cte))
  delete from fresh_segments.interest_metrics  where cast(interest_id as integer) in (select interest_id from temp);
    select extract(month from month_year), count(distinct cast(interest_id as integer))
    from fresh_segments.interest_metrics 
    group by extract(month from month_year);

--Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest
 with max_composition as (select month_year, interest_id,
    max(composition) as max_composition
    from fresh_segments.interest_metrics 
    group by interest_id, month_year)
    (select * from max_composition
    order by max_composition desc
    limit 10)
    union
    (select  * from max_composition
    order by max_composition asc
    limit 10)

-- Which 5 interests had the lowest average ranking value?  
with avg_ranking as (select interest_id,
    round(avg(ranking),2) as ranking_value
    from fresh_segments.interest_metrics 
    group by interest_id)
    select * from avg_ranking
    order by ranking_value 
    limit 5
    ;
-- Which 5 interests had the largest standard deviation in their percentile_ranking value?  
with standard_deviation_ranking as (select interest_id,
   stddev(percentile_ranking) as ranking_value
    from fresh_segments.interest_metrics 
    group by interest_id)
    select * from standard_deviation_ranking
    order by ranking_value DESC
    limit 5
-- For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
  with standard_deviation_ranking as (
  select interest_id,
   stddev(percentile_ranking) as ranking_value
    from fresh_segments.interest_metrics 
    group by interest_id),
    
largest_stdev as(
    select * from 
  standard_deviation_ranking
  where ranking_value is not null
    order by ranking_value DESC
    limit 5
  )
select s.interest_id,
    max(m.percentile_ranking) as  max_percentile_ranking,            
    min(m.percentile_ranking) as min_percentile_ranking,
    s.ranking_value
    from largest_stdev s
    left join fresh_segments.interest_metrics m
    on s.interest_id = m.interest_id
    group by s.interest_id, s.ranking_value

  
    ;

-- What is the top 10 interests by the average composition for each month?
alter table fresh_segments.interest_metrics alter column month_year type varchar(15);
update fresh_segments.interest_metrics set  month_year = to_date(month_year, 'MM-YYYY');
alter table fresh_segments.interest_metrics alter column month_year type date using month_year :: date;
with avg_composition as(
select interest_id, month_year,
round((composition/index_value)::numeric, 2) as avg_composition
from fresh_segments.interest_metrics),
top as (
  select interest_id,
  month_year,
  extract(month from month_year) as month,
  avg_composition,
  rank()over(partition by extract(month from month_year) order by avg_composition desc) as rn
  from  avg_composition)
  select * from top
  where rn <= 10

-- For all of these top 10 interests - which interest appears the most often?
most_often as (  select t.interest_id,
  m.interest_name,
  count(t.interest_id) as most_often
  from top_10 t
  join fresh_segments.interest_map m
  on t.interest_id = m.id
  group by t.interest_id, m.interest_name)
  
  select * from most_often
  where most_often = (select max(most_often) from most_often)


-- What is the average of the average composition for the top 10 interests for each month?
avg_avg_composition as (
  select 
  month,
  avg(avg_composition) as avg_avg_composition
  from top_10 
group by month )
  select * from avg_avg_composition
