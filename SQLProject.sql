SELECT * from credit_card_transcations

select min(transaction_date), max(transaction_date) from credit_card_transcations --2013/10 - 2015/05

select distinct(exp_type) from credit_card_transcations --Entertainment, Food, Bills , Fuel, Travel, Grocery

select distinct(card_type) from credit_card_transcations -- silver , signature, gold , platinum

--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

select top 5 city, sum(amount) as spend,
round(100*(sum(cast(amount as bigint))*1.0/(select sum(cast(amount as bigint))*1.0 from credit_card_transcations)),2) 
from credit_card_transcations
group by city
order by spend desc 

--write a query to print highest spend month and amount spent in that month for each card type

with cte as (select card_type,month(transaction_date) as mnth, sum(amount) as spend from credit_card_transcations
group by card_type, MONTH(transaction_date))
, cte2 as (select *, rank() over(partition by card_type order by spend desc) as rnk from cte)
select * from cte2 where rnk =1

--write a query to print the transaction details(all columns from the table) for each card type when it 
--reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (select *, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as cum_sum from credit_card_transcations)
select * from ( tition by card_type order by cum_sum) as rnk from cte where cum_sum>1000000) as a 
where rnk= 1

--write a query to find city which had lowest percentage spend for gold card type

with cte as (select city, 
sum(amount) as tot_spend, 100*(sum(amount)*1.0/ (select sum(cast(amount as bigint))*1.0 from credit_card_transcations)) as percen
from credit_card_transcations
where card_type = 'Gold'
group by city )
select city from cte where percen = (select min(percen) from cte)

--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (select city, exp_type, sum(amount) as spend from credit_card_transcations
group by city, exp_type)
, cte2 as (select * from (select *, rank() over(partition by city order by spend) as min_max , rank() over(partition by city order by spend desc) as max_min from cte) as a
where min_max = 1 or max_min=1)

select city, max(case when max_min = 1 then exp_type end) as best_type, min(case when min_max = 1 then exp_type end )as worst_type from cte2 
group by city

--write a query to find percentage contribution of spends by females for each expense type

with cte as (select exp_type, sum( case when gender = 'F' then amount end) as fspend, sum( case when gender = 'M' then amount end) as mspend
from credit_card_transcations 
group by exp_type)
select exp_type , round(100*((fspend*1.0) /(fspend+mspend)*1.0),2) as total from cte

--which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (select card_type, exp_type,year(transaction_date) as yt,month(transaction_date) as mt, sum(amount) as spend from credit_card_transcations
group by card_type, exp_type, year(transaction_date), month(transaction_date))
select top 1 *, (spend - prev_spend)*1.0/prev_spend as yoy_growth from (select *, lag(spend) over (partition by card_type, exp_type order by yt, mt) as prev_spend from cte) as tab
where prev_spend is not null and yt=2014 and mt=1
order by yoy_growth desc

--during weekends which city has highest total spend to total no of transcations ratio
with cte as (select city ,sum(amount) as spend, count(*) as cnt, sum(amount)*1.0/count(*) as growth from credit_card_transcations
where DATENAME(WEEKDAY, transaction_date) in ('Saturday','Sunday')
group by city )
select top 1 city,growth from cte order by growth desc

--which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (select *, row_number() over (partition by city order by transaction_date) as rn from credit_card_transcations)
, cte2 as (select city , min(transaction_date) as mn, max(transaction_date) as mx, DATEDIFF(DAY, min(transaction_date) ,  max(transaction_date)) as dif from cte where rn = 1 or rn = 500 group  by city having count(1) = 2)

select top 1 * from cte2 order by dif
