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
