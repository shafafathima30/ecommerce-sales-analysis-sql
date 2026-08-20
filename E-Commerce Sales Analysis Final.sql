-- =====================================================
-- E-COMMERCE SALES ANALYSIS
-- SQL Portfolio Project
-- =====================================================

CREATE DATABASE IF NOT EXISTS ecommerce_project; 
USE ecommerce_project;

-- =====================================================
-- 1. DATA CLEANING & PREPARATION
-- =====================================================

ALTER TABLE sales
RENAME COLUMN `Order Date` TO OrderDate,
RENAME COLUMN `Delivery Date` TO DeliveryDate,
RENAME COLUMN `Currency Code` TO CurrencyCode,
RENAME COLUMN `Order Number` TO OrderNumber,
RENAME COLUMN `Line Item` TO LineItem;

ALTER TABLE products
RENAME COLUMN `Product Name` TO ProductName,
RENAME COLUMN `Unit Cost USD` TO UnitCostUSD,
RENAME COLUMN `Unit Price USD` TO UnitPriceUSD;

ALTER TABLE customers
RENAME COLUMN `State Code` TO StateCode,
RENAME COLUMN `Zip Code` TO ZipCode;

ALTER TABLE stores
RENAME COLUMN `Square Meters` TO SquareMeters,
RENAME COLUMN `Open Date` TO OpenDate;

UPDATE products
SET UnitPriceUSD = REPLACE(UnitPriceUSD, '$',''),
    UnitCostUSD = REPLACE(UnitCostUSD, '$','');

ALTER TABLE products
MODIFY COLUMN UnitPriceUSD DECIMAL(10,2),
MODIFY COLUMN UnitCostUSD DECIMAL(10,2);

-- =====================================================
-- 2. SALES PERFORMANCE
-- =====================================================

-- Total units sold
SELECT SUM(Quantity) AS TOTAL_UNITS_SOLD
FROM sales;

-- Top-selling products by units sold
SELECT p.ProductName, SUM(s.Quantity) AS NUMBER_OF_UNITS_SOLD
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY p.ProductName
ORDER BY  NUMBER_OF_UNITS_SOLD DESC;

-- Product categories by units sold
 SELECT p.Category, SUM(s.Quantity) AS UNIT_SOLD
 FROM sales s 
 INNER JOIN products p 
 ON s.ProductKey=p.ProductKey
 GROUP BY p.Category
 ORDER BY UNIT_SOLD DESC;

-- Monthly units sold
SELECT MONTHNAME(STR_TO_DATE(OrderDate,'%m/%d/%y')) AS MONTH,
       SUM(Quantity) AS UNITS_SOLD
FROM sales
GROUP BY MONTH(STR_TO_DATE(OrderDate,'%m/%d/%y')),
         MONTHNAME(STR_TO_DATE(OrderDate,'%m/%d/%y'))
ORDER BY MONTH(STR_TO_DATE(OrderDate,'%m/%d/%y'));

-- =====================================================
-- 3. PRODUCT ANALYSIS
-- =====================================================

-- Top 5 products by total sales revenue
SELECT p.ProductName,SUM(s.Quantity * p.UnitPriceUSD) AS sales_revenue
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY p.ProductName,p.ProductKey
ORDER BY sales_revenue DESC
LIMIT 5;

-- Product category with highest total sales revenue
SELECT p.category,SUM(s.Quantity * p.UnitPriceUSD) AS total_sales_revenue
FROM sales s 
INNER JOIN products p 
ON s.ProductKey = p.ProductKey
GROUP BY p.category
ORDER BY total_sales_revenue DESC 
LIMIT 1;

-- Product with highest total profit
SELECT p.ProductName,SUM(s.Quantity * (p.UnitPriceUSD - p.UnitCostUSD)) AS total_profit
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY p.ProductName,p.ProductKey
ORDER BY total_profit DESC
LIMIT 1;

-- Product category with highest total profit
SELECT p.Category,SUM(s.Quantity * (p.UnitPriceUSD - p.UnitCostUSD)) AS total_profit
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY p.Category
ORDER BY total_profit DESC
LIMIT 1;

-- Highest-order category
SELECT p.category,COUNT(DISTINCT s.OrderNumber) AS number_of_orders
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY p.category
ORDER BY number_of_orders DESC
LIMIT 1;

-- =====================================================
-- 4. CUSTOMER ANALYSIS
-- =====================================================

-- Highest-revenue customer
SELECT c.Name,SUM(s.Quantity * p.UnitPriceUSD) AS total_sales_revenue
FROM sales s 
INNER JOIN products p 
ON s.ProductKey = p.ProductKey
INNER JOIN customers c 
ON s.CustomerKey = c.CustomerKey
GROUP BY c.Name,c.CustomerKey
ORDER BY total_sales_revenue DESC 
LIMIT 1;

--  Highest-average-order-value customer
SELECT Name,Customerkey,AVG(order_value) AS average_order_value 
FROM (
       SELECT c.Name,c.Customerkey,SUM(s.Quantity * p.UnitPriceUSD) AS order_value
       FROM sales s 
       INNER JOIN products p 
       ON s.ProductKey=p.ProductKey
       INNER JOIN customers c 
       ON s.CustomerKey=c.CustomerKey
       GROUP BY c.Name,c.Customerkey,OrderNumber
       ) AS order_total
GROUP BY Name,Customerkey
ORDER BY average_order_value DESC
LIMIT 1;

--  Customer with the highest number of orders
SELECT c.Name,COUNT(DISTINCT s.OrderNumber) AS number_of_order
FROM sales s
INNER JOIN customers c 
ON s.CustomerKey=c.CustomerKey
GROUP BY c.Name,c.CustomerKey
ORDER BY number_of_order DESC
LIMIT 1;

-- Highest-customer age group
SELECT
CASE 
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 26 AND 35 THEN '26-35'
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 36 AND 50 THEN '36-50'
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 51 AND 70 THEN '51-70'
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 71 AND 90 THEN '71-90'
WHEN TIMESTAMPDIFF(YEAR,STR_TO_DATE(Birthday, '%m/%d/%Y'),CURDATE()) BETWEEN 91 AND 100 THEN '91-100'
END AS age_group,COUNT(CustomerKey) AS number_of_customers
FROM customers
GROUP BY age_group
ORDER BY number_of_customers DESC
LIMIT 1;

-- Customers with multiple orders
SELECT CustomerKey,COUNT(DISTINCT OrderNUmber) AS NUMBER_OF_ORDERS_PLACED
FROM sales
GROUP BY CustomerKey
HAVING NUMBER_OF_ORDERS_PLACED >1;

-- Highest units purchased customer
SELECT c.Name,SUM(s.Quantity) AS number_of_units
FROM sales s 
INNER JOIN customers c 
ON s.CustomerKey=c.CustomerKey
GROUP BY c.Name ,c.CustomerKey
ORDER BY number_of_units DESC
LIMIT 1;

-- Highest average units per order customer
SELECT Name,AVG(number_of_units_purchased) AS average_number_of_units_purchased
FROM(
     SELECT c.Name,SUM(s.Quantity) AS number_of_units_purchased
     FROM sales s 
     INNER JOIN customers c 
     ON s.CustomerKey=c.CustomerKey
     GROUP BY c.Name,s.OrderNumber,c.CustomerKey
     )total_units
GROUP BY Name
ORDER BY average_number_of_units_purchased DESC 
LIMIT 1;

-- Top 5 customers by total sales revenue
SELECT c.Name,SUM(s.Quantity * p.UnitPriceUSD) AS sales_revenue
FROM sales s 
INNER JOIN customers c
ON s.CustomerKey=c.CustomerKey
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY c.Name,c.CustomerKey
ORDER BY sales_revenue DESC
LIMIT 5;

-- Customer with Highest Total Profit
SELECT c.Name,SUM(s.Quantity * (p.UnitPriceUSD - p.UnitCostUSD)) AS total_profit
FROM sales s 
INNER JOIN customers c
ON s.CustomerKey=c.CustomerKey
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY c.Name,c.CustomerKey
ORDER BY total_profit DESC
LIMIT 1;

-- ============================================================
-- 5. GEOGRAPHIC ANALYSIS
-- ============================================================

-- Country with the highest total sales revenue
SELECT c.Country,SUM(s.Quantity * p.UnitPriceUSD) AS total_sales_revenue
FROM sales s 
INNER JOIN products p 
ON s.ProductKey = p.ProductKey
INNER JOIN customers c 
ON s.CustomerKey = c.CustomerKey
GROUP BY c.Country
ORDER BY total_sales_revenue DESC 
LIMIT 1;

-- Highest-customer country
SELECT Country ,COUNT(CustomerKey) AS number_of_customer 
FROM Customers
GROUP BY Country
ORDER BY number_of_customer DESC
LIMIT 1;

-- City with the highest number of customers
SELECT City ,COUNT(CustomerKey) AS number_of_customer 
FROM Customers
GROUP BY City
ORDER BY number_of_customer DESC
LIMIT 1;

-- Country with the highest total number of units sold
SELECT c.Country,SUM(s.Quantity) AS number_of_units_sold
FROM sales s 
INNER JOIN customers c 
ON c.CustomerKey=s.CustomerKey
GROUP BY c.Country
ORDER BY number_of_units_sold DESC
LIMIT 1;

-- Country with the highest number of orders
SELECT c.Country,COUNT(DISTINCT s.OrderNumber) AS number_of_orders
FROM sales s 
INNER JOIN customers c 
ON s.CustomerKey=c.CustomerKey
GROUP BY c.Country
ORDER BY number_of_orders DESC
LIMIT 1;

-- Country with the highest average order value
SELECT Country,AVG(order_values) AS average_order_value
FROM
(
  SELECT c.Country,s.OrderNumber,SUM(s.Quantity * p.UnitPriceUSD) AS order_values
  FROM sales s 
  INNER JOIN products p 
  ON s.ProductKey=p.ProductKey
  INNER JOIN customers c
  ON c.CustomerKey=s.CustomerKey
  GROUP BY c.Country,s.OrderNumber 
  )AS Order_total
GROUP BY Country
ORDER BY average_order_value DESC
LIMIT 1;

-- Country with the highest average number of units per order
SELECT Country,AVG(number_of_units_per_order)
FROM(
     SELECT c.Country,SUM(s.quantity) AS number_of_units_per_order
     FROM sales s 
     INNER JOIN customers c
     ON s.CustomerKey=c.CustomerKey
     GROUP BY c.Country,s.OrderNumber
     )AS Total_units
GROUP BY Country
ORDER BY AVG(number_of_units_per_order) DESC
LIMIT 1;


-- ============================================================
-- 6. STORE ANALYSIS
-- ============================================================

-- Highest-revenue store
SELECT s.StoreKey,
       SUM(s.Quantity * p.UnitPriceUSD) AS TOTAL_SALES_REVENUE
FROM sales s
INNER JOIN products p
    ON s.ProductKey = p.ProductKey
WHERE  s.StoreKey <> 0   
GROUP BY s.StoreKey
ORDER BY TOTAL_SALES_REVENUE DESC
LIMIT 1;

-- Highest-profit store
SELECT s.StoreKey,
       SUM(s.Quantity * (p.UnitPriceUSD - p.UnitCostUSD)) AS TOTAL_PROFIT
FROM sales s
INNER JOIN products p
    ON s.ProductKey = p.ProductKey
WHERE  s.StoreKey <> 0      
GROUP BY s.StoreKey
ORDER BY TOTAL_PROFIT DESC
LIMIT 1;

-- Highest-average-order-value store
SELECT StoreKey,
       AVG(ORDER_VALUE) AS AVERAGE_ORDER_VALUE
FROM (
    SELECT s.StoreKey,
           s.OrderNumber,
           SUM(s.Quantity * p.UnitPriceUSD) AS ORDER_VALUE
    FROM sales s
    INNER JOIN products p
        ON s.ProductKey = p.ProductKey
    WHERE  s.StoreKey <> 0      
    GROUP BY s.StoreKey, s.OrderNumber
) AS STORE_ORDERS
GROUP BY StoreKey
ORDER BY AVERAGE_ORDER_VALUE DESC
LIMIT 1;

-- Highest average units per order store
SELECT StoreKey,AVG(number_of_units_purchased) AS average_number_of_units_purchased
FROM(
     SELECT st.StoreKey,SUM(s.Quantity) AS number_of_units_purchased
     FROM sales s 
     INNER JOIN stores st
     ON s.StoreKey=st.StoreKey
     WHERE  s.StoreKey <> 0  
     GROUP BY st.StoreKey,s.OrderNumber
     )total_units
GROUP BY StoreKey
ORDER BY average_number_of_units_purchased DESC 
LIMIT 1;


-- ============================================================
-- 7. SALES CHANNEL ANALYSIS
-- ============================================================

-- Online vs Store Sales
SELECT 
     CASE 
         WHEN s.StoreKey = 0 THEN 'Online'
         ELSE 'Stores'
     END AS sales_channel,
     SUM(s.Quantity * p.UnitPriceUSD) AS total_sales_revenue
FROM sales s
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY 
     CASE 
         WHEN s.StoreKey = 0 THEN 'Online'
         ELSE 'Stores'
     END
ORDER BY total_sales_revenue DESC;


-- ============================================================
-- 8. TIME & TREND ANALYSIS
-- ============================================================


-- Month with the highest total sales revenue
SELECT MONTHNAME(STR_TO_DATE(s.OrderDate,'%m/%d/%y')),SUM(s.Quantity * p.UnitPriceUSD) AS total_sales_revenue
FROM sales s 
INNER JOIN products p 
ON s.ProductKey=p.ProductKey
GROUP BY MONTHNAME(STR_TO_DATE(s.OrderDate,'%m/%d/%y'))
ORDER BY total_sales_revenue DESC
LIMIT 1;

-- Month with the highest number of orders
SELECT MONTHNAME(STR_TO_DATE(OrderDate,'%m/%d/%y')),COUNT(DISTINCT OrderNumber)AS number_of_orders
FROM sales 
GROUP BY MONTHNAME(STR_TO_DATE(OrderDate,'%m/%d/%y'))
ORDER BY number_of_orders DESC
LIMIT 1;







































































