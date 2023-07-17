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
