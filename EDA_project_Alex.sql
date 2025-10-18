select * from layoffs_staging2;
	# add coulmn of the number of the employee who is not laid off
alter table layoffs_staging2
add column employees_not_laid_off int ;
update layoffs_staging2
SET employees_not_laid_off = (total_laid_off / percentage_laid_off) - total_laid_off
WHERE total_laid_off IS NOT NULL AND percentage_laid_off IS NOT NULL;


									### Company
select distinct company from layoffs_staging2 order by 1 ;
	# the companies which laid off all its employee
select  *
from layoffs_staging2
where percentage_laid_off=1 ;

	# summary statistics for total laid off by company
select company , min(total_laid_off) ,max(total_laid_off),
 avg(total_laid_off),count(company) as number_appear , sum(total_laid_off)
from layoffs_staging2 
group by 1
order by 1;

	# summary statistics for funds_raised by company
select company , min(funds_raised) ,max(funds_raised),
 avg(funds_raised),count(company) as number_appear , sum(funds_raised)
from layoffs_staging2 
group by 1;

	# Change the number of order by to have the rank of company at each year 
select company,
sum( case when year(date)= 2020 then total_laid_off else 0 end) laid_off_2020,
sum(case when year(date)=2021 then total_laid_off else 0 end)laid_off_2021,
sum(case when year(date)=2022 then total_laid_off else 0 end)laid_off_2022,
sum(case when year(date)=2023 then total_laid_off else 0 end)laid_off_2023,
sum(case when year(date)=2024 then total_laid_off else 0 end)laid_off_2024,
sum(case when year(date)=2025 then total_laid_off else 0 end)laid_off_2025
from layoffs_staging2
group by 1
order by 5 desc;

	# the highest 5 companies in laid off for each year
with rank_CTE (company, years,total) as(
select company , year(date) , sum(total_laid_off)
from layoffs_staging2 
group by 1,2
order by 3 desc),
company_year_rank as(
select * , dense_rank() over(partition by years order by total desc) as ranking
from rank_CTE  
order by ranking)
select * 
from company_year_rank
where ranking<=5
order by years;

	#each company and its funds over years
select company , 
sum(case when year(date)=2020 then funds_raised end)as funds_2020,
sum(case when year(date)=2021 then funds_raised end)as funds_2021,
sum(case when year(date)=2022 then funds_raised end)as funds_2022,
sum(case when year(date)=2023 then funds_raised end)as funds_2023,
sum(case when year(date)=2024 then funds_raised end)as funds_2024,
sum(case when year(date)=2025 then funds_raised end)as funds_2025
from layoffs_staging2
group by 1 ;


										#Industry
select distinct industry from layoffs_staging2 order by 1 ;
	# summary statistics for total laid off by industry
select industry , min(total_laid_off) ,max(total_laid_off),
 avg(total_laid_off),count(industry) as number_appear , sum(total_laid_off),count(company)
from layoffs_staging2 
group by 1
order by 1;

	# summary statistics for funds_raised by industry
select industry , min(funds_raised) ,max(funds_raised),
 avg(funds_raised),count(industry) as number_appear , sum(funds_raised),count(company)
from layoffs_staging2 
group by 1
order by 1;

	# sum of the total by industry over the number of the company this industry have
select industry , sum(total_laid_off) , count(company), (sum(total_laid_off) / count(company))as average_by_industry
from layoffs_staging2
group by industry
order by 2 desc;

	# the highest industries have employees
select industry , sum(employees_not_laid_off) as Number_of_employees
from layoffs_staging2 
group by 1
order by 2 desc;

	# each industry and the most country have employee at it
with country_CTE as ( 
select industry , country ,location, sum(employees_not_laid_off) as total_employee, 
row_number() over(partition by industry order by sum(employees_not_laid_off ) desc) as row_num
from layoffs_staging2 
group by industry , country,location
), country_CTE2 as(
select industry, country , location , total_employee
from country_CTE 
where row_num = 1)
select  industry, concat(country, ', ', location ) as the_place , total_employee
from country_CTE2 ; 

	# Change the number of order_by to have the rank of industry at each year and the no. of companies by industry
select industry , count(company),
sum( case when year(date)= 2020 then total_laid_off else 0 end) laid_off_2020,
sum(case when year(date)=2021 then total_laid_off else 0 end)laid_off_2021,
sum(case when year(date)=2022 then total_laid_off else 0 end)laid_off_2022,
sum(case when year(date)=2023 then total_laid_off else 0 end)laid_off_2023,
sum(case when year(date)=2024 then total_laid_off else 0 end)laid_off_2024,
sum(case when year(date)=2025 then total_laid_off else 0 end)laid_off_2025
from layoffs_staging2
group by 1
order by 1 desc;

	# the highest 5 industries in laid off for each year
with industry_year (industry, years , total) as(
select industry , year(date) , sum(total_laid_off)
from layoffs_staging2
group by industry , year(date)),
industry_rank as(
select * , dense_rank() over(partition by years order by total ) as ranking
from industry_year)
select * from industry_rank 
order by ranking;

	# the commen stage 
with stage_CTE as(
select industry, stage ,count(company) as the_most_commen_stage ,
row_number() over(partition by industry order by count(company) desc) as row_num
from layoffs_staging2 
group by industry, stage ),
stage_CTE2 as(
select industry ,stage 
 from stage_CTE 
 where row_num =2)
select s1.industry,
case when s1.stage = 'Unknown' then s2.stage 
else s1.stage
ENd the_most_commen_stage
from stage_CTE s1
join stage_CTE2 s2
on s1.industry = s2.industry
where row_num =1 ;

	# the 3rd commen stage by each industry
with stage_CTE as(
select industry, stage ,count(company) as commen_stage ,
row_number() over(partition by industry order by count(company) desc) as row_num
from layoffs_staging2 
group by industry, stage )
select industry ,stage ,commen_stage ,row_num
 from stage_CTE 
 where row_num <=3;


	# the commen stages of industries over years
WITH base AS (
SELECT industry,YEAR(date) AS y,stage,COUNT(*) AS cnt
FROM layoffs_staging2
GROUP BY industry, YEAR(date), stage),
ranked AS (
SELECT industry, y, stage, cnt, ROW_NUMBER() OVER (PARTITION BY industry, y ORDER BY cnt DESC) AS rn
FROM base),
winner AS (
SELECT industry, y, stage AS stage1
FROM ranked
WHERE rn = 1),
runner AS (
SELECT industry, y, stage AS stage2
FROM ranked
WHERE rn = 2),
final_stage AS (
SELECT w.industry, w.y,
CASE WHEN w.stage1 = 'Unknown' THEN r.stage2 ELSE w.stage1 END AS stage_final
FROM winner w
LEFT JOIN runner r
ON w.industry = r.industry AND w.y = r.y)
SELECT
    industry,
    MAX(CASE WHEN y = 2020 THEN stage_final END) AS the_most_common_stage2020,
    MAX(CASE WHEN y = 2021 THEN stage_final END) AS the_most_common_stage2021,
    MAX(CASE WHEN y = 2022 THEN stage_final END) AS the_most_common_stage2022,
    MAX(CASE WHEN y = 2023 THEN stage_final END) AS the_most_common_stage2023,
    MAX(CASE WHEN y = 2024 THEN stage_final END) AS the_most_common_stage2024,
    MAX(CASE WHEN y = 2025 THEN stage_final END) AS the_most_common_stage2025
FROM final_stage
GROUP BY industry
ORDER BY industry;

#each industry and its funds over years
select industry , 
sum(case when year(date)=2020 then funds_raised end)as funds_2020,
sum(case when year(date)=2021 then funds_raised end)as funds_2021,
sum(case when year(date)=2022 then funds_raised end)as funds_2022,
sum(case when year(date)=2023 then funds_raised end)as funds_2023,
sum(case when year(date)=2024 then funds_raised end)as funds_2024,
sum(case when year(date)=2025 then funds_raised end)as funds_2025
from layoffs_staging2
group by industry ;

									# DATE
	# the highest laid off happen at which quarter of the year
select  quarter(date) , sum(total_laid_off)
from layoffs_staging2 
group by 1
order by 2 desc;

	# laid off by year
select year(date) as year_only  ,sum(total_laid_off)
from layoffs_staging2
group by year_only
order by 2 desc; 
	# rolling sum of laid off over months and total laid off per month
with month_year_CTE as(
select substring(date, 1,7) as month_year , sum(total_laid_off) as total
from layoffs_staging2 
where  substring(date, 1,7) is not null 
group by 1
order by 1)
select month_year ,total, sum(total) over(order by month_year) as rolling_sum
from  month_year_CTE
 ;
 
										# location 
select distinct location from layoffs_staging2 ;

	# the emount of employee by location
select location , sum(employees_not_laid_off) as total_employee
from layoffs_staging2
group by 1
having total_employee is not null
order by 2 desc ;

	# each country & location and the industry with the highest number of employee
WITH industry_location_cte AS (
SELECT location,country,industry,SUM(employees_not_laid_off) AS total_employee,
ROW_NUMBER() OVER (PARTITION BY location ORDER BY SUM(employees_not_laid_off) DESC) AS rn
FROM layoffs_staging2
GROUP BY location , country, industry 
)
SELECT  country,location , industry 
FROM industry_location_cte
WHERE rn = 1 and location is not null
order by country;

	# call it by the location to have the industry with the highest number of employee at this location
DELIMITER $$
CREATE PROCEDURE Max_Industry_By_Location(enter_location VARCHAR(255))
BEGIN
WITH Industry_Totals AS (
SELECT location, industry, SUM(employees_not_laid_off) AS total_employee
FROM layoffs_staging2
WHERE location = enter_location
GROUP BY location, industry
),
Rank_Industries AS (
SELECT location, industry, total_employee,
RANK() OVER (PARTITION BY location ORDER BY total_employee DESC) AS ranking
fROM Industry_Totals
)
SELECT location, industry, total_employee
FROM Rank_Industries
WHERE ranking = 1;
END $$
DELIMITER ;

	/*to try the procedure
Helsinki,Non-U.S.
SF Bay Area
Dublin,Non-U.S.
Toronto,Non-U.S.
Los Angeles
---------------------------------------------------*/
call Max_Industry_By_Location('Toronto,Non-U.S.');

	# the most locations has employee
select country, location , sum(employees_not_laid_off) as total_employee
from layoffs_staging2
group by country , location 
having total_employee is not null
order by 3 desc;

											#source
select distinct source from layoffs_staging2 ;

    # show all sites names only
SELECT DISTINCT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(source, '/', 3), '/', -1) AS site_name
FROM layoffs_staging2;
	
    # remove 'www.' if exist and show the number of the articals at each site and rank by amount of articals 
with source_CTE as(
SELECT 
    SUBSTRING_INDEX(SUBSTRING_INDEX(source, '/', 3), '/', -1) AS site_name
FROM layoffs_staging2),
source_CTE2 as (
select site_name,
case when site_name like 'www.%' then right(site_name,(length(site_name)-4)) 
	else site_name
	end as site_name2
from source_CTE)
select site_name2 , count(site_name2) , dense_rank() over(order by count(site_name2) desc)
from source_CTE2
group by site_name2 ;

	# the most industry each site write about
with source_CTE as(
SELECT source,
    SUBSTRING_INDEX(SUBSTRING_INDEX(source, '/', 3), '/', -1) AS site_name
FROM layoffs_staging2),
source_CTE2 as (
select site_name, source ,
case 
    when site_name like 'www.%' 
    then  right(site_name,(length(site_name)-4))
     else site_name
     end as site_name2
from source_CTE),
source_CTE3 as(
select c.site_name2 , l.industry , c.source ,count(*) ,
row_number() over(partition by c.site_name2 order by count(*) desc) as rum_num
from source_CTE2 c
join layoffs_staging2 l
  ON c.source = l.source
group by c.site_name2 , l.industry ,c.source)

select site_name2 , industry 
from source_CTE3 
where rum_num =1 ;

									#stage
select distinct stage from layoffs_staging2  ;
/*من Seed → Series A → Series B … Series J = مراحل النمو بتمويل مستمر.
Acquired / Subsidiary = الشركة بقت مملوكة لحد تاني.
Post-IPO = الشركة نزلت البورصة.
Private Equity = ممسوكة من شركات استثمارية.*/
 
	# the total laid off for each stage
select sum(total_laid_off) , stage
from layoffs_staging2
group by stage
having stage is not null and stage !='Unknown'
order by 1 ;

	# the stages of the companies laid off all its employees
select distinct stage 
from layoffs_staging2
where percentage_laid_off = 1 ;

	# the total funds of each stage
select sum(funds_raised) , stage
from layoffs_staging2
group by stage
having stage is not null and stage !='Unknown'
order by 1 desc;
	# the 5TH high industry funds for each year 
with rank_CTE as (
select year(date) as years,industry  , sum(funds_raised) as total_funds
from layoffs_staging2
group by industry ,year(date)),
 rank_CTE2 as(
 select *, dense_rank() over(partition by years order by total_funds desc) as row_rank
 from rank_CTE
 )
 select *
 from rank_CTE2 
 where row_rank <=5
order by years
;
							#funds rasied & laid off
# there is correlation is Close to 0 so, no linear relation.
SELECT
    (AVG(funds_raised * total_laid_off) - AVG(funds_raised) * AVG(total_laid_off)) /
    (SQRT(AVG(funds_raised * funds_raised) - POW(AVG(funds_raised), 2)) *
     SQRT(AVG(total_laid_off * total_laid_off) - POW(AVG(total_laid_off), 2))) 
    AS correlation
FROM layoffs_staging2
WHERE funds_raised IS NOT NULL
  AND total_laid_off IS NOT NULL;

	# summary statistics for funds_raised & laid off
(select 'funds' as label, min(funds_raised) as Minimum ,max(funds_raised) as Maximum,
 avg(funds_raised) as Average , sum(funds_raised) as Summation
from layoffs_staging2 

)
union 
(select 'laid_off' as label, min(total_laid_off) ,max(total_laid_off),
 avg(total_laid_off), sum(total_laid_off)
from layoffs_staging2 
);

	# detect lower and upper outliers in funds_raised
WITH ordered AS (
    SELECT 
        funds_raised,
        NTILE(4) OVER (ORDER BY funds_raised) AS quartile
    FROM layoffs_staging2
    WHERE funds_raised IS NOT NULL
),
q AS (
    SELECT 
        MAX(CASE WHEN quartile = 1 THEN funds_raised END) AS q1,
        MAX(CASE WHEN quartile = 3 THEN funds_raised END) AS q3
    FROM ordered
),
low_up_CTE as(
SELECT l.*,
       CASE 
           WHEN l.funds_raised < q.q1 - 1.5*(q.q3 - q.q1) THEN 'Lower Outlier'
           WHEN l.funds_raised > q.q3 + 1.5*(q.q3 - q.q1) THEN 'Upper Outlier'
           ELSE 'Normal'
       END AS outlier_flag
FROM layoffs_staging2 l
JOIN q)
select *
from low_up_CTE
where outlier_flag = 'Lower Outlier' OR outlier_flag = 'Upper Outlier'
;

	# detect lower and upper outliers in total_laid_off
WITH ordered AS (
    SELECT 
        total_laid_off,
        NTILE(4) OVER (ORDER BY total_laid_off) AS quartile
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
),
q AS (
    SELECT 
        MAX(CASE WHEN quartile = 1 THEN total_laid_off END) AS q1,
        MAX(CASE WHEN quartile = 3 THEN total_laid_off END) AS q3
    FROM ordered
),
low_up_CTE as(
SELECT l.*,
       CASE 
           WHEN l.total_laid_off < q.q1 - 1.5*(q.q3 - q.q1) THEN 'Lower Outlier'
           WHEN l.total_laid_off > q.q3 + 1.5*(q.q3 - q.q1) THEN 'Upper Outlier'
           ELSE 'Normal'
       END AS outlier_flag
FROM layoffs_staging2 l
JOIN q)
select *
from low_up_CTE
where outlier_flag = 'Lower Outlier' OR outlier_flag = 'Upper Outlier';