create database hranalystics;
use hranalystics;

select * from hr;

-- data cleaning and preprocessing

-- changing employee id columns name 
alter table hr rename column ï»¿id to emp_id; -- change columns name only
alter table hr modify column emp_id varchar(20) null;
-- ALTER TABLE hr CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL; --  this will change columns name and also change the datatype

select * from hr;
desc hr;


-- 2nd = In birthdate columns - some dates are having "-" and some having "/" . so we need to update into one format
--  data_format - The date_format function is used to format a date or datetime value into a specific string format in MySQL

SET sql_safe_updates = 0;
UPDATE hr
SET birthdate = CASE
		WHEN birthdate LIKE '%/%' THEN date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
        WHEN birthdate LIKE '%-%' THEN date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
        ELSE NULL
		END;
-- update datatype of data
alter table hr modify column birthdate date;


-- 3rd =  -- change the data format and datatype of hire_date column

update hr
set hire_date  = case
when hire_date like '%/%' then date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
when hire_date like '%-%' then date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
else null
end;

select * from hr;
desc hr;
alter table hr modify column hire_date date;

-- 4th we need tp change termdate columns 
-- date is already convert in date format so we change it into date_format
update hr
set termdate = date_format(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC'), '%Y/%m/%d %H:%i:%s UTC')
where termdate is not null and termdate!= '';

update hr
set termdate = date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC'))
where termdate is not null and termdate!= '';

update hr
set termdate = date_format(str_to_date(termdate,'%Y/%m/%d %H:%i:%s UTC'), '%Y-%m-%d %H:%i:%s UTC')
where termdate is not null and termdate!= '';

UPDATE hr
SET termdate = NULL
WHERE termdate = '';

select * from hr;


-- add new columns age in table
alter table hr add column age int after birthdate;
update hr 
set age = timestampdiff(year,birthdate,curdate());
select * from hr;
 
select min(age),max(age) from hr;


-- add new column -  full name

alter table hr add column Full_name varchar(30) after last_name ;
alter table hr drop column Full_name;

update hr
set Full_name = concat(first_name, ' ',last_name );
select * from hr;


## Questions

-- 1. What is the gender breakdown of employees in the company?
-- 2. What is the race/ethnicity breakdown of employees in the company?
-- 3. What is the age distribution of employees in the company?
-- 4. How many employees work at headquarters versus remote locations?
-- 5. What is the average length of employment for employees who have been terminated?
-- 6. How does the gender distribution vary across departments and job titles?
-- 7. What is the distribution of job titles across the company?
-- 8. Which department has the highest turnover rate?
-- 9. What is the distribution of employees across locations by city and state?
-- 10. How has the company's employee count changed over time based on hire and term dates?


-- Q1
select gender,count(*) from hr  group by gender;
select gender,count(*) from hr where termdate is null  group by gender; --  this give count od employee who is currently working
 
-- Q2
select * from hr;
select race,count(race) from hr where termdate is null group by race;  --  this give count od employee who is currently working

--  Q3

select min(age),max(age),count(age) from hr where age >= 18;

select
case
    when age>=18 and age<=24 then '18-24'
    when age>=25 and age<=34 then '25-34'
    when age>=35 and age<=44 then '35-44'
    when age>=45 and age<=54 then '45-54'
    when age>=55 and age<=64 then '55-64'
    else '65+'
    end as group_age,
    count(age) as count
    from hr
    where termdate is null
    group by group_age
    order by group_age
    desc;
    
    
  -- Q4
  select * from hr;
  select location, count(*) from hr where termdate is null group by location; 
    
 -- Q5
 select year(termdate) from hr;
select year(hire_date) from hr;
select avg(year(termdate)- year(hire_date)) as yearcount from hr where termdate is not null and termdate <= curdate();
select round(avg(year(termdate)- year(hire_date))) as yearcount from hr where termdate is not null and termdate <= curdate();
  
  
-- Q6
select department, jobtitle,gender, count(*) as gender_distru 
from hr 
where termdate is not null
group by department, jobtitle,gender
order by department, jobtitle,gender;

select department,gender, count(*) as gender_distru 
from hr 
where termdate is not null
group by department, gender
order by department, gender;
  
 
-- Q7
SELECT jobtitle, COUNT(*) AS count
FROm hr
WHERE termdate IS NULL
GROUP BY jobtitle;

select * from hr;


-- Q8

        
select department ,
       count(*) as total_count,
       count(case when termdate is not null and termdate <= curdate() then 1 end) as terminated_count ,
        
        round((count(case when termdate is not null and termdate <= curdate() then 1 end )/count(*))*100,2) as terminateed_rate
        from hr  GROUP BY department
        ORDER BY terminateed_rate DESC;


-- Q9

SELECT location_state, COUNT(*) AS count
FROm hr
WHERE termdate IS NULL
GROUP BY location_state;

SELECT location_city, COUNT(*) AS count
FROm hr
WHERE termdate IS NULL
GROUP BY location_city;



-- Q10
-- In subquery first inner quert get excuted then outer

SELECT year,
		hires,
        terminations,
        hires-terminations AS net_change,
        (terminations/hires)*100 AS change_percent
	FROM(
			SELECT YEAR(hire_date) AS year,
            COUNT(*) AS hires,
            SUM(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY YEAR(hire_date)) AS subquery
GROUP BY year
ORDER BY year;


-- Q11
 -- How long do employees work in each department before they leave or are made to leave?

select year from hr;
SELECT department, round(avg(datediff(termdate,hire_date)/365),0) AS avg_tenure
FROM hr
WHERE termdate IS NOT NULL AND termdate<= curdate()
GROUP BY department;

-- Q12
-- Termination and hire breakdown gender wisw
SELECT gender,
		hires,
        terminations,
        round((terminations/hires)*100,2) as termination_rate 
	FROM(
			SELECT gender,
            COUNT(*) AS hires,
            count(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY gender) AS subquery
GROUP BY gender;



SELECT age,
		hires,
        terminations,
        round((terminations/hires)*100,2) as termination_rate 
	FROM(
			SELECT age,
            COUNT(*) AS hires,
            count(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY age) AS subquery
GROUP BY age;


SELECT department,
		hires,
        terminations,
        round((terminations/hires)*100,2) as termination_rate 
	FROM(
			SELECT department,
            COUNT(*) AS hires,
            count(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY department) AS subquery
GROUP BY department;



SELECT race,
		hires,
        terminations,
        round((terminations/hires)*100,2) as termination_rate 
	FROM(
			SELECT race,
            COUNT(*) AS hires,
            count(CASE 
					WHEN termdate IS NOT NULL AND termdate <= curdate() THEN 1 
				END) AS terminations
			FROM hr
            GROUP BY race) AS subquery
GROUP BY race;

