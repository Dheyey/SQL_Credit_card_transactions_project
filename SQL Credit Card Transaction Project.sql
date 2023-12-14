--1 write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte as(
select top 5 City, count(*) as No_of_transactions , sum(amount) as Total_amt          
from [DHYEY].[dbo].[credit_card_transcations]
group by city
order by Total_amt desc
),
cte2 as(
select distinct city, sum(cast(amount as bigint)) over() as total_spend from [DHYEY].[dbo].[credit_card_transcations])

select c1.city, c1.total_amt, round((c1.total_amt * 1.0 *100/c2.total_spend),2) as percentage
from cte c1
join cte2 c2 
on c1.city = c2.city
order by percentage desc


--2 write a query to print highest spend month and amount spent in that month for each card type

with cte as(
select card_type, sum(amount) as Total_amt, month(transaction_date) as month,  year(transaction_date) as year
from [DHYEY].[dbo].[credit_card_transcations]
group by card_type, month(transaction_date), year(transaction_date)
),

cte2 as(
select *, rank() over(partition by card_type order by total_amt desc) as rn
from cte)

select card_type,month as Highest_month_spend, total_amt as Total_spend, year
from cte2 
where rn = 1
order by Highest_month_spend desc


--3 write a query to print the transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as(
select *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as cumm_sum
from [DHYEY].[dbo].[credit_card_transcations])

select * from (select *, rank() over(partition by card_type order by cumm_sum) as rn  
from cte where cumm_sum >= 1000000) a where rn=1

--4 write a query to find city which had lowest percentage spend for gold card type

with cte as(
select city, sum(amount) as Total_amt
from [DHYEY].[dbo].[credit_card_transcations]
where card_type = 'Gold'
group by city)

select top 1*, (cast((total_amt*1.0*100)/sum(cast(total_amt as decimal(18,2))) over() as decimal(18,5))) as percentage
from cte
order by percentage 

-- 5 write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

select city,max(case when amount > 0  then exp_type end) as highest_expense_type,
          min(case when amount > 0  then exp_type end) as Lowest_expense_type, max(amount)
from [DHYEY].[dbo].[credit_card_transcations]
group by city
order by city


-- 6 write a query to find percentage contribution of spends by females for each expense type
with cte as(
select exp_type, sum(amount) as total_Fspend
from [DHYEY].[dbo].[credit_card_transcations]
where gender = 'F'
group by exp_type),

cte2 as(
select exp_type, sum(amount) as total_spend
from [DHYEY].[dbo].[credit_card_transcations]
group by exp_type)

select c1.exp_type, ((total_Fspend*1.0) *100) / total_spend as percentage
from cte c1
join cte2 c2
on c1.exp_type = c2.exp_type
order by percentage desc


-- 7 which card and expense type combination saw highest month over month growth in Jan-2014
with cte as(
select card_type,exp_type,month(transaction_date) as month,year(transaction_date) as year, sum(amount) as amount
from [DHYEY].[dbo].[credit_card_transcations]
group by card_type,exp_type,month(transaction_date),year(transaction_date)
),
cte2 as(
select *,lag(amount) over(partition by card_type,exp_type order by year,month) amt,amount - lag(amount) over(partition by card_type,exp_type order by year,month) as diff
from cte),
cte3 as(
select card_type,exp_type, diff,rank() over(order by diff desc) as rn
from cte2
where month = 1 and year = 2014)

select card_type,exp_type from cte3 where rn = 1

--8 during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, sum(amount) as total_spend, count(*) total_no_of_transcations, (sum(amount)* 1.0*100 / count(*)) ratio
from [DHYEY].[dbo].[credit_card_transcations]
where DATEPART(WEEKDAY, transaction_date) IN (1, 7)
group by city
order by ratio desc

-- 10 which city took least number of days to reach its 500th transaction after the first transaction in that city

-- Method 1

with cte as(
select city,transaction_date as last_date
from (
       select *, row_number() over(partition by city order by transaction_date,transaction_id) as rn
       from [DHYEY].[dbo].[credit_card_transcations]) X
       where city in (select city 
					  from [DHYEY].[dbo].[credit_card_transcations] 
		              where rn in (500))
),
cte2 as(
select city,transaction_date as first_date
from (
       select *, row_number() over(partition by city order by transaction_date,transaction_id) as rn
       from [DHYEY].[dbo].[credit_card_transcations]) X
       where city in (select city 
                      from [DHYEY].[dbo].[credit_card_transcations] 
                      where rn in (1)))
select top 1 c1.city  , c1.last_date,  c2.first_date, datediff(day,c2.first_date, c1.last_date)
from cte c1
join cte2 c2
on c1.city = c2.city
order by datediff(day,c2.first_date, c1.last_date) 

--Method 2

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from [DHYEY].[dbo].[credit_card_transcations])
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 



























