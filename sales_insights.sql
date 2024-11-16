
---  The Report should have the following fields
-- -- As a product owner, i want to generate a report of indivisual product sales
-- --  (agreegated on a monthly basis at the product code lavel) for croma india 
-- -- customer for FY=2021  so that i can track indivisual product sales and run
-- -- further product analytics on it in excel

-- month
-- product name
-- varient
-- sold quantity
-- gross price per item
-- gross price total


	select 
    s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price,
    round(s.sold_quantity*g.gross_price,2) as gross_price_total
    from  fact_sales_monthly s
    join dim_product p
    on p.product_code=s.product_code
    join fact_gross_price g on
    g.product_code=s.product_code and 
    g.fiscal_year=get_fiscal_year(s.date)
	where 
	customer_code = 90002002 and
	get_fiscal_year(date)=2021 and
    get_fiscal_quarter(date)="q4"
	order by date asc
    
    
    -- gross monthly total sales report for croma
    -- as a product owner, i need an aggregate monthly gross sales report for croma india customer 
--     so that i can track how much sales this perticular customer is generating for AtliQ and manage our relationship
--     accordingly 
--     
--     the report should have the following fields 
--     1.month
--     2.total gross salesamount to croma india in this month

select
 s.date,
 sum(g.gross_price*s.sold_quantity) as gross_price_total 
from fact_sales_monthly s
join fact_gross_price g 
on
g.product_code=s.product_code and
g.fiscal_year=get_fiscal_year(s.date)
where customer_code= 90002002
group by s.date
order by s.date asc 

--  Generate a yearly report for Croma India where there are two columns

-- 	1. Fiscal Year
-- 	2. Total Gross Sales amount In that year from Croma

select 
get_fiscal_year(s.date) as fiscal_year,
 sum(g.gross_price*s.sold_quantity) as yearly_sales
 from fact_sales_monthly s
 join fact_gross_price g
 on
 s.product_code=g.product_code and
 g.fiscal_year=get_fiscal_year(s.date)
 where 
 customer_code=90002002
 group by get_fiscal_year(s.date)
 order by fiscal_year;
 
 
 
 -- created stored procedure  for monthly gross sales report
--  
--  as a data analyst, i want to create a stored procedure  for monthly  gross sales report so that i dont have to 
--  manually modify the query every time . stored procedure can be run by other user to  and they can generate 
--  this report without having to involve data analytics team

-- the report should have the following fields 
--     1.month
--     2.total gross salesamount to croma india in this month

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`(c_code int)
BEGIN
select
 s.date,
 sum(g.gross_price*s.sold_quantity) as gross_price_total 
from fact_sales_monthly s
join fact_gross_price g 
on
g.product_code=s.product_code and
g.fiscal_year=get_fiscal_year(s.date)
where customer_code= c_code
group by s.date
order by s.date asc ;
END 


-- create a stored procedure that can determine the market badge based on the following logic,
-- if total sold quantity > 5 million that marked is considered gold else it is in silver

-- my input will be 
-- market
-- fiscal year 

-- output

-- market badge

 CREATE DEFINER=`root`@`localhost` PROCEDURE `get_market_badge`(
 IN in_market varchar(45),
 IN  in_fiscal_year year,
 OUT out_badge varchar(45)
)
BEGIN
declare qty int default 0;
select sum(sold_quantity) into qty
from fact_sales_monthly s
join dim_customer c
on s.customer_code=c.customer_code
where get_fiscal_year(s.date)=2021 and market="India"
group by c.market ;

if qty > 5000000 then 
set out_badge = "Gold";
else
set out_badge = "silver";
end if;
END

-- The error you show above because this is a stored procedure which i make option available in left hand side and 
-- copy paste them year to see


-- As a product owner, i want a report for top markets, top products, customers by net sales for a given 
-- financial year so that i can have a view of sales performance and can take appropriate actions to address any potential 
-- issues

-- report for top market
-- report for top product
-- report for top customers

with cte1 as 
(select 
    s.date,s.product_code,p.product,p.variant,s.sold_quantity,g.gross_price,
    round(s.sold_quantity*g.gross_price,2) as gross_price_total,pre.pre_invoice_discount_pct
    from  fact_sales_monthly s
    join dim_product p
    on p.product_code=s.product_code
    join fact_gross_price g on
    g.product_code=s.product_code and 
    g.fiscal_year=get_fiscal_year(s.date)
    join fact_pre_invoice_deductions pre
    on
    pre.customer_code=s.customer_code and
    pre.fiscal_year=get_fiscal_year(s.date)
	where 
    s.customer_code=90002002 and
	get_fiscal_year(date)=2021 and
    get_fiscal_quarter(date)="q4"
	order by date asc)
    select *,
    (gross_price_total-gross_price_total*pre_invoice_discount_pct) as net_invoice_sales
    from cte1
-- created a view --
SELECT * FROM sales_preinv_discount;
------------------------------------------------
select *,
(gross_price_total-gross_price_total*pre_invoice_discount_pct) as net_invoice_sales,
(po.discounts_pct+po.other_deductions_pct) as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po
on s.date=po.date and
s.product_code=po.product_code and
s.customer_code=po.customer_code
----------------------------------------------------
 select 
 *,
(1-post_invoice_discount_pct)*net_invoice_sales as net_sales
from sales_postinv_discount;

------------------------------------------
-- Top Markets
select market,
round(sum(net_sales)/1000000,2) as net_sales_in_millions
from net_sales
where get_fiscal_year(date)=2021
group by market
order by net_sales_in_millions desc
limit 5

 --------------------------------------------
 
-- Top Customer

select customer,
round(sum(net_sales)/1000000,2) as net_sales_in_millions
from net_sales
where get_fiscal_year(date)=2021
group by customer
order by net_sales_in_millions desc
limit 5

-------------------------------------------------

-- Top Product
select product,
round(sum(net_sales)/1000000,2) as net_sales_in_millions
from net_sales
where get_fiscal_year(date)=2021
group by product
order by net_sales_in_millions desc
limit 5