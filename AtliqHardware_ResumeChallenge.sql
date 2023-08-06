
      -- 1.Get distinct market from dim_customer
select distinct market from dim_customer
where customer = "Atliq exclusive" and region = "APAC"

      -- 2.calculate percentage of product increase from 2020 to 2021
with ct as (select count(distinct p.product_code) as unique_products_2020 from dim_product p
join fact_sales_monthly m on p.product_code = m.product_code
where m.fiscal_year = 2020 ),
ct1 as (select count(distinct p.product_code) as unique_products_2021 from dim_product p
join fact_sales_monthly m on p.product_code = m.product_code
where m.fiscal_year = 2021 )
select *,round(((unique_products_2021-unique_products_2020)/ unique_products_2020)*100,2) as percentage_chg from ct,ct1


		-- 3.Product_count by segment  
select segment, count(distinct product_code) as product_count from dim_product
group by segment
order by product_count desc

        -- 4.Get difference of Product_code_2021 and Product_code_2020 
select t1.segment,t1.product_count_2020,t2.product_count_2021,(t2.product_count_2021 - t1.product_count_2020) as difference from
(select pp.segment,count(distinct pp.product_code) as product_count_2020 from dim_product pp
join fact_sales_monthly ss on pp.product_code = ss.product_code
where ss.fiscal_year = 2020
group by pp.segment) as t1
join
(select p.segment,count(distinct p.product_code) as product_count_2021 from dim_product p 
join fact_sales_monthly s on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.segment) as t2
on t1.segment = t2.segment

           -- 5.Products with highest and lowest cost
select p.product,p.product_code,m.manufacturing_cost from dim_product p 
join fact_manufacturing_cost m on p.product_code = m.product_code
where manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
union
select p.product,p.product_code,m.manufacturing_cost from dim_product p 
join fact_manufacturing_cost m on p.product_code = m.product_code
where manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)

		  -- 6. Top 5 Indian customers who got average high pre_invoice_discount_per in year 2021
select c.customer_code,c.customer,avg(pre_invoice_discount_pct) as percent from fact_pre_invoice_deductions d
join dim_customer c on d.customer_code = c.customer_code
where d.fiscal_year = 2021 and c.market = "India"
group by c.customer,c.customer_code
order by perc desc
limit 5

			-- 7.Gross sales by each month for Atliq Exclusive customer
select monthname(m.date) as Month,m.fiscal_year,sum(m.sold_quantity * p.gross_price) as gross_sales from fact_sales_monthly m
join fact_gross_price p on
m.product_code = p.product_code
join dim_customer c on c.customer_code = m.customer_code
where c.customer = "Atliq Exclusive"
group by Month,m.fiscal_year
order by m.fiscal_year
  
           -- 8.Get sold quantity for quarter in 2020
select fiscal_year,
sum(case when month(date) in (9,10,11) then sold_quantity end) as Q1 ,
sum(case when month(date) in (12,1,2) then sold_quantity end) as Q2,
sum(case when month(date) in (3,4,5) then sold_quantity end) as Q3 
from fact_sales_monthly
where fiscal_year = 2020
group by fiscal_year

           -- 9. Get the channel with highest contribution percentage
with cte as 
(select c.channel,concat(round(sum(m.sold_quantity * p.gross_price)/1000000,2),'M')as gross_sales from fact_sales_monthly m
join fact_gross_price p on
m.product_code = p.product_code
join dim_customer c on c.customer_code = m.customer_code
where m.fiscal_year = 2021
group by c.channel),
cte1 as (select sum(gross_sales) as total_gross_sales from cte )
select channel,gross_sales,concat(round((gross_sales/total_gross_sales)*100,2),'%') as percentage from cte,cte1
order by percentage desc

          -- 10. Get top 3 products from each division
with cte1 as (select  p.division,p.product_code,p.product,sum(s.sold_quantity) as total_sold_quantity
from dim_product p
join fact_sales_monthly s on p.product_code = s.product_code 
where s.fiscal_year = 2021
group by p.product,p.division,p.product_code),
cte2 as (select 
* ,dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order from cte1)
select * from cte2 where rank_order <= 3




