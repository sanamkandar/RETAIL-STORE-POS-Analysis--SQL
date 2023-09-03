create database RetailStore_db
										-- then, imported CSV files into database
use RetailStore_db


-------------- DATA PREP. & UNDERSTANDING
--1
select 'Customer' as [Tables], count(*) as [Total number of rows] from Customer
union all
select 'prod_cat_info', count(*) from prod_cat_info
union all
select 'Transactions', count(*) from Transactions
 

--2

select count(*) as [Total number of returned transactions]  from Transactions
where Qty<0


--3

begin tran
update Transactions
set tran_date = REPLACE(tran_date,'/','-')
where tran_date like '%/%/%'

commit


--update date format as per sql fromat (trans date COL)
begin tran
update Transactions
set tran_date = convert(date,tran_date,105)

commit

alter table Transactions
alter column tran_date date

select * from Transactions

----------------------------
--update date format as per sql fromat (DOB COL)
begin tran
update Customer
set DOB = CONVERT(date, DOB, 105)
commit

alter table Customer
alter column DOB date

select * from Customer


--4

SELECT DATEDIFF(DD,
	(select top 1 tran_date from Transactions
	order by tran_date),
	(select top 1 tran_date from Transactions
	order by tran_date desc)) as [time range in days],

	DATEDIFF(MM,
	(select top 1 tran_date from Transactions
	order by tran_date),
	(select top 1 tran_date from Transactions
	order by tran_date desc)) as [time range in months],

	DATEDIFF(YYYY,
	(select top 1 tran_date from Transactions
	order by tran_date),
	(select top 1 tran_date from Transactions
	order by tran_date desc)) as [time range in year]


-- 5
select prod_cat from prod_cat_info
where prod_subcat = 'DIY'


--------------------------- DATE ANALYSIS-----
--1

select top 1 Store_type ,count(*) as [count of trans. by channel] from Transactions
group by Store_type
order by [count of trans. by channel] desc


--2

select Gender, count(*) as [Gender-wise count] from Customer
where Gender in ('M','F')
group by Gender



--3

select top 1 city_code, count(*) as [max_count_of_customer] from Customer
group by city_code
order by [max_count_of_customer] desc



--4

select count(prod_subcat) as [No. of sub-categories under books] from prod_cat_info
where prod_cat = 'Books'



--5

select distinct prod_cat, max(Qty) as [Max quantity ever order] from Transactions as T
inner join prod_cat_info as P
on T.prod_cat_code = P.prod_cat_code
group by prod_cat


--6

-- third, after joining revenue tb (F_tb) and loss/returned tb (L_tb)
-- subracted loss/returned amt from revenue amt and round them with 2 decimal places

select F_tb.prod_cat,
round(revenue_amt,2) as [revenue__amt],
round(returned_amt,2) as [returned__amt],
round(revenue_amt-abs(returned_amt),2) as [net__revenue] 

from
(
-- first sub-query, find out sum of revenue from non-returned records of 'Electronics', 'Books'
select distinct prod_cat,sum(cast(total_amt as float)) as revenue_amt from Transactions as T
inner join prod_cat_info as P
on T.prod_cat_code = P.prod_cat_code
where prod_cat in ('Electronics', 'Books') and cast(total_amt as float)>0
group by prod_cat
) as F_tb                          -- named non-returned tb as F_tb for joining with returned tb

inner join                         -- join           

(
-- second sub-query, find out sum of loss from returned records of 'Electronics', 'Books'
select distinct prod_cat,sum(cast(total_amt as float)) as returned_amt from Transactions as T
inner join prod_cat_info as P
on T.prod_cat_code = P.prod_cat_code
where prod_cat in ('Electronics', 'Books') and cast(total_amt as float)<0
group by prod_cat) as S_tb           -- named returned tb as S_tb for joining with non-returned tb

on F_tb.prod_cat = S_tb.prod_cat        -- joined on prod_cat basis



--7

select T_tb.cust_id,count(*) as [count of transactions] from Transactions as T_tb
inner join Customer as C_tb
on T_tb.cust_id = C_tb.customer_Id
where cast(total_amt as float)>0
group by cust_id
having count(*) > 10



-- 8
select 'Clothing, Electronics' as [Flagship store], round(sum(cast(total_amt as float)),2) as [Combined revenue ] from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_cat_code = P_tb.prod_cat_code
where Store_type ='Flagship store' and prod_cat in ('Clothing','Electronics') and cast(total_amt as float)>0



-- 9

select prod_subcat, round(sum(cast(total_amt as float)),2) as [Revenue] from Transactions as T_tb
inner join Customer as C_tb
on T_tb.cust_id = C_tb.customer_Id
inner join prod_cat_info as P_tb
on T_tb.prod_subcat_code = P_tb.prod_sub_cat_code
where prod_cat = 'Electronics' and Gender = 'M' and cast(total_amt as float)>0
group by prod_subcat



-- 10

select top 5 sales_tb.prod_subcat, [sales %], [returns %]

from
-- Sub-query 1, output: tb of % sales
(select prod_subcat,
round((sum(cast(total_amt as float))/(select sum(cast(total_amt as float)) from Transactions where cast(total_amt as float)>0))*100,2) as [sales %]

from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_subcat_code = P_tb.prod_sub_cat_code
where cast(total_amt as float)>0                      -- filtered positive total_amt (successfull sales)
group by prod_subcat
) as sales_tb

inner join                                            -- join both tb (tb of % sales,tb of % returns)

-- Sub-query 2, output: tb of % returns
(select prod_subcat,
round((sum(abs(cast(total_amt as float)))/(select sum(abs(cast(total_amt as float))) from Transactions where cast(total_amt as float)<0))*100,2) as [returns %]

from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_subcat_code = P_tb.prod_sub_cat_code
where cast(total_amt as float)<0                      -- filtered negative total_amt (returns)
group by prod_subcat
) as returns_tb

on sales_tb.prod_subcat = returns_tb.prod_subcat      -- join on prod_subcat basis
order by [sales %] desc



-- 11

select [total revenue]-return_amt as [Net total revenue] from
(
select sum(cast(total_amt as float)) as [total revenue] from                          -- actual sale table, output: sum of revenue
-- 
	(select *,
		case 
			when MONTH(GETDATE()) < MONTH(DOB) 
							then DATEDIFF(year, DOB, getdate())-1
			when MONTH(GETDATE()) = MONTH(DOB) and DAY(getdate()) < DAY(DOB) 
							then DATEDIFF(year, DOB, getdate())-1
			else
				DATEDIFF(year, DOB, getdate())

				end as [Age]

	from Transactions T_tb
	inner join Customer C_tb
	on T_tb.cust_id = C_tb.customer_Id
	where tran_date >= (select DATEADD(DAY,-30, max(tran_date)) from Transactions)
	) as CT_tb
	--
where Age between 25 and 35  and cast(total_amt as float)>0 
) as [total_revenue_tb]

inner join
                                                                          -- returns table, output: sum of return amt
(
select sum(cast(abs(total_amt) as float))  as [return_amt] from
-- 
	(select *,
		case 
			when MONTH(GETDATE()) < MONTH(DOB) 
							then DATEDIFF(year, DOB, getdate())-1
			when MONTH(GETDATE()) = MONTH(DOB) and DAY(getdate()) < DAY(DOB) 
							then DATEDIFF(year, DOB, getdate())-1
			else
				DATEDIFF(year, DOB, getdate())

				end as [Age]

	from Transactions T_tb
	inner join Customer C_tb
	on T_tb.cust_id = C_tb.customer_Id
	where tran_date >= (select DATEADD(DAY,-30, max(tran_date)) from Transactions)
	) as CT_tb
	--
where Age between 25 and 35  and cast(total_amt as float)<0 
) as [returns_tb]

on total_revenue_tb.[total revenue] = returns_tb.return_amt or total_revenue_tb.[total revenue] <> returns_tb.return_amt



-- 12
                             -- calculated field for return value by product categories

select top 1 P_tb.prod_cat, round(sum(cast(abs(total_amt) as float)),2) as [return_value] from      

(                                                         -- sub-query 1, which fetch data of last 3 months
select * from Transactions
where tran_date >= (select DATEADD(month,-3,max(tran_date)) from Transactions) 
) as three_month_tb

inner join prod_cat_info P_tb                             -- joined 3 month_data_tb with product_tb                 
on three_month_tb.prod_cat_code = P_tb.prod_cat_code

where cast(total_amt as float)<0                          -- filter for returns data
group by P_tb.prod_cat                                    -- return value by product categories
order by return_value desc                                -- sort max to min




-- 13

select Store_type, sum(cast(Qty as int)) as [Quantity sold], round(sum(cast(total_amt as float)),2) as [Sales amt] from Transactions
where cast(total_amt as float)>0
group by Store_type
order by [Quantity sold] desc, [Sales amt]



-- 14

select prod_cat, avg(cast(total_amt as float)) as [average revenue > overall revenue] from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_cat_code= P_tb.prod_cat_code
where cast(total_amt as float)>0 
group by prod_cat
                                      -- sub-query pass for comparison operation, output: overall revenue
having avg(cast(total_amt as float)) > (select avg(cast(total_amt as float)) from Transactions as T_tb
										inner join prod_cat_info as P_tb
										on T_tb.prod_cat_code= P_tb.prod_cat_code
										where cast(total_amt as float)>0)


--15

select revenue_tb.prod_subcat,
round(avg(cast(total_amt as float)),2) as [Avg revenue],
round(sum(cast(total_amt as float)),2) as [Total revenue] 

from
(select transaction_id,cust_id,tran_date,Qty,total_amt,P_tb.prod_cat,P_tb.prod_subcat from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_cat_code= P_tb.prod_cat_code
where cast(total_amt as float)>0
) as revenue_tb

inner join 

(select top 5 prod_cat as [top_p_cat], sum(cast(Qty as int)) as [Qty_Sold] from Transactions as T_tb
inner join prod_cat_info as P_tb
on T_tb.prod_subcat_code = P_tb.prod_sub_cat_code
where cast(total_amt as float)>0
group by prod_cat
order by Qty_Sold desc
) as Top_cat_tb

on  revenue_tb.prod_cat = Top_cat_tb.top_p_cat
group by revenue_tb.prod_subcat

