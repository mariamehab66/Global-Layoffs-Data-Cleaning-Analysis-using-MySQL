use world_layoffs;
select * 
from layoffs;
  # make a copy from the original data to use  
create table layoffs_staging
like layoffs;

insert layoffs_staging 
select * from layoffs;

select * 
from layoffs_staging;

 # checking the exict of duplicates
with CTE_duplicated as(
select * , row_number() over(partition by 
company, location, total_laid_off, percentage_laid_off, industry, stage, funds_raised, country) as row_num
from layoffs_staging )
select * 
from CTE_duplicated
where row_num >1 ;

select * 
from layoffs_staging
where company ='Talkdesk';

  # remove the duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text,
   `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert into layoffs_staging2
select * , row_number() over(partition by 
company, location, total_laid_off, percentage_laid_off, industry, stage, funds_raised, country) as row_num
from layoffs_staging ;

select * from layoffs_staging2;
select * 
from layoffs_staging2
where row_num >1;

delete
from layoffs_staging2
where row_num >1 ;

 # standarizing the data 
    # remove uncessery spaces from data in some columns
select company,trim(company)
from layoffs_staging2;
update layoffs_staging2
set company = trim(company) ;

    # take a look on the all columns if there an duplicated industry with a wrong writed name
select distinct location
from layoffs_staging2
order by 1;
select *
from layoffs_staging2
where industry like 'crypto%';
update layoffs_staging2 
set industry = 'Crypto' 
where industry like 'crypto%';

select distinct country
from layoffs_staging2
order by 1;
update layoffs_staging2 
set country =  trim(trailing '.' from country )
where country like 'United States%' ;

	# emptycells handeling to change the datatype
select distinct country
from layoffs_staging2
order by 1;

UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = '';
UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = '';
UPDATE layoffs_staging2
SET funds_raised = NULL
WHERE funds_raised = '';
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
UPDATE layoffs_staging2
SET country = NULL
WHERE country = '';
update layoffs_staging2
set percentage_laid_off = null 
where percentage_laid_off = 0 ;
update layoffs_staging2
set industry = 'Other'
where industry is null  ;
update layoffs_staging2
set  stage = null
where stage='';

	# remove the % and $ to be able to use this columns as numbers and correct the date writing
select distinct percentage_laid_off
from layoffs_staging2
order by 1;
update layoffs_staging2 
set percentage_laid_off = replace(percentage_laid_off,'%','');
update layoffs_staging2 
set percentage_laid_off = (percentage_laid_off * 0.01);

select  funds_raised
from layoffs_staging2
order by 1;
update layoffs_staging2
set funds_raised = replace(funds_raised , '$','');

select distinct date
from layoffs_staging2
order by 1;
select date ,str_to_date(date_added , '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set date = str_to_date(date , '%m/%d/%Y');
update layoffs_staging2
set date_added = str_to_date(date_added , '%m/%d/%Y');


	# changing the datatype of the columns 
select *
from layoffs_staging2;

alter table layoffs_staging2
modify column date date;

alter table layoffs_staging2
modify column date_added date;

alter table layoffs_staging2
modify column total_laid_off int;

alter table layoffs_staging2
modify column percentage_laid_off decimal(5,2) ;

alter table layoffs_staging2
modify column funds_raised int;

	# NULL vules ,that we have a data about, handeling 
select * from layoffs_staging2
where industry is null ;
select * from layoffs_staging2
where company ='Appsmith';

select t1.industry  , t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company = t2.company 
    and t1.location = t2.location 
where (t1.industry is null ) and t2.industry is not null ;

update layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company = t2.company 
set t1.industry  = t2.industry
where (t1.industry is null ) and t2.industry is not null ;

	# NULL vules ,rows that don't tell us any measurable thing, Remove
select * 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null
and funds_raised is null;

delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null
and funds_raised is null;

delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

	# drop columns that we don't need 
alter table layoffs_staging2
drop column row_num;

select * 
from layoffs_staging2;
