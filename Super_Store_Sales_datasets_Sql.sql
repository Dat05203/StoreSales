USE master
GO

IF NOT EXISTS(select * from sys.databases where name = 'SuperStoreSales')
	CREATE DATABASE SuperStoreSales
GO

USE SuperStoreSales
GO

SELECT * FROM Super_Store_Sales
GO

---------------------------------------- DATA CLEANING -------------------------------------------------
-- Changing time from datetime to date
ALTER TABLE Super_Store_Sales
ALTER COLUMN Order_Date Date
Go
ALTER TABLE Super_Store_Sales
ALTER COLUMN Ship_Date Date
Go

-- Delete Order_Date column
/*ALTER TABLE Super_Store_Sales
DROP COLUMN Order_Date
Go*/

-- Check Null value in State or Region column
SELECT *
FROM Super_Store_Sales
WHERE Order_Date is null or Ship_Date is null
Go

-- Delete Order_Date or Ship_Date is NULL
DELETE FROM Super_Store_Sales
WHERE Order_Date is null or Ship_Date is null

--Changing null value in Customer_Name, Region to 'unknown'
UPDATE Super_Store_Sales
SET Customer_Name =  CASE WHEN Customer_Name is null THEN 'Unknown'
                     ELSE Customer_Name 
		             END
UPDATE Super_Store_Sales
SET Region =  CASE WHEN Region is null THEN 'Unknown'
                     ELSE Region 
		             END
select Order_Date from Super_Store_Sales
-- We remove duplicate values
WiTH temp_table AS(
SELECT *,
ROW_NUMBER() OVER(
    PARTITION BY Ship_Date, Ship_Mode, Customer_ID, Customer_Name,
	             Segment, Country, City, State, Postal_Code, Region, 
				 Product_ID, Category,Sub_Category, Product_Name, 
				 Sales, Quantity, Discount, Profit, CoGS
	ORDER BY     Order_ID) row_num
FROM Super_Store_Sales
) delete from temp_table where row_num > 1

------------------------------------------ EXPLORE DATA ------------------------------------------------
SELECT * FROM Super_Store_Sales

-- Which Category has the highest Sales, Profit and earn the most money?
WITH comparision AS(
    SELECT  Category,
	        SUM(Sales) as total_sales,
			COUNT(Order_ID) as number_order,
			SUM(profit) as total_profit
	FROM Super_Store_Sales
	GROUP BY Category
) 
SELECT 
       Category,
       ROUND((CAST(number_order as float) / CAST((select sum(number_order) from comparision) as float) * 100.0),2) as Per_number_order,
       ROUND(((total_sales/(select sum(total_sales) from comparision)) * 100.0),2) as Per_sales,
	   ROUND(((total_profit/(select sum(total_profit) from comparision)) * 100.0),2) as Per_profit
FROM   
       comparision
ORDER BY 
       Category

--> The highest number of orders is in Office Supplies products, but the highest sale is in Technology products.

-- Percentage of Sales value by Segment
WITH sales_segment as(
		select 
			Segment,
			SUM(Sales) as Total_Sales
		from
			Super_Store_Sales
		group by 
			Segment
)
SELECT 
	Segment,
	ROUND(((Total_Sales/(select SUM(Sales) from Super_Store_Sales))*100.0),2) as Per_by_segment
FROM 
	sales_segment
--> We get the result the most sales from Consumer Segment(over 50%)

---- How many values does each product contribute to the total?
WITH Product AS(
	SELECT
		Segment,
		COUNT(Product_ID) as number_product
	FROM
		Super_Store_Sales
	GROUP BY
		Segment
)
SELECT
	Segment,
	number_product,
	ROUND((number_product / (SELECT SUM(number_product) FROM Product)) * 100,0) as per_num_produc_by_category
FROM
	Product
--> Most of the products distributed to customers are consumers, accounting for more than 50%

----What day of the week does the supermarket have the most sales?
SELECT 
	Dayofweek,
	AVG(Sales) as AVG_Sales
FROM (SELECT 
		DATENAME (Weekday,Order_Date) as Dayofweek,
		Sales
	FROM Super_Store_Sales) as by_day
GROUP BY Dayofweek
ORDER BY AVG_Sales DESC
--> Customers tend buy on the Friday the most. On the Tuesday and Wednesday have the lowest sales of the week.