-- Creating database 
/*
=============================================================
Create Schemas
=============================================================
Script Purpose:
    This script creates a new schema named 'gold'. This schema will be containing out tables on which we 
    will be doing our analysis and genrate final view 
*/
CREATE SCHEMA gold;

-- Creating tables
CREATE TABLE gold.dim_customers1(
	customer_key int,
	customer_id int,
	customer_number LONGTEXT,
	first_name LONGTEXT,
	last_name LONGTEXT,
	country LONGTEXT,
	marital_status LONGTEXT,
	gender LONGTEXT,
	birthdate date,
	create_date date
);

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number varchar(50) ,
	product_name varchar(50) ,
	category_id varchar(50) ,
	category varchar(50) ,
	subcategory varchar(50) ,
	maintenance varchar(50) ,
	cost int,
	product_line varchar(50),
	start_date date 
);

CREATE TABLE gold.fact_sales(
	order_number varchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity int,
	price int 
);

/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/

-- List all tables along with their schema and type in MySQL
SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Retrieve all columns for a specific table.
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME = 'dim_customers1';

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME = 'dim_products';

SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold' AND TABLE_NAME = 'fact_sales';

/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/
  -- Exploraing all countries our customers are coming from 
  SELECT DISTINCT country FROM gold.dim_customers1;
  
  -- Exploring all categories "The major division"
  SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products order by 1,2,3;
 
/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/
  -- find the date of first order and last order
  
  -- How many years of sales are available
  SELECT MIN(order_date) AS first_order_date, MAX(order_date) AS last_order_date, 
  PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM MAX(order_date)), EXTRACT(YEAR_MONTH FROM MIN(order_date))) AS order_range_month
  FROM gold.fact_sales;
  
  -- Finding the oldest and youngest customer
  SELECT MIN(birthdate) AS youngest_customer, MAX(birthdate) AS oldest_customer FROM gold.dim_customers1;
  
  -- age of youngest and oldest customer
  SELECT TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age, 
  TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age
  FROM gold.dim_customers1;

/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/
  -- Find the total sales.
     SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;
  -- Find how many otems are sold
    SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;
  -- find the average selling price
     SELECT ROUND(AVG(price),2) AS avg_price FROM gold.fact_sales;
  -- Find the total number of products 
    SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales;
    SELECT COUNT(DISTINCT order_number) AS distinct_no_of_orders FROM gold.fact_sales;
  -- Find the total number of product
	SELECT COUNT(product_name) AS total_products FROM gold.dim_products;
	SELECT COUNT(DISTINCT product_name) AS total_products FROM gold.dim_products;
 -- Find the total number of customer
    SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers1; 
 -- Find total number of customers who has placed orders
     SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;
 -- Generate a report that shows all key metrics of the business
     SELECT 'Total sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
     UNION ALL
     SELECT 'Total quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
     UNION ALL
     SELECT 'Average Price' AS measure_name, ROUND(AVG(price),2) AS measure_value FROM gold.fact_sales
     UNION ALL 
     SELECT 'Total Order' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
     UNION ALL
     SELECT 'Product Name' AS measure_name, COUNT(product_name) AS measure_value FROM gold.dim_products
     UNION ALL
     SELECT 'Customer Key' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers1;
     
/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/
  -- Find total customer by countries.
     SELECT country, COUNT(customer_key) as Total_customer
     FROM gold.dim_customers1
     GROUP BY 1;
  -- Find total customer by gender
	 SELECT gender, COUNT(customer_key) as Total_customer
     FROM gold.dim_customers1
     GROUP BY 1;
  -- Average cost in each category
      SELECT category, AVG(cost) as avg_cost
     FROM gold.dim_products
     GROUP BY 1;
  -- Total products by category
       SELECT category, COUNT(product_key) as total_product
     FROM gold.dim_products
     GROUP BY 1
     ORDER BY total_product DESC;
  -- Total Revenue by each category
	 SELECT p.category, SUM(f.sales_amount) AS total_revenue
     FROM gold.fact_sales f  LEFT JOIN gold.dim_products p
     ON f.product_key = p.product_key
     GROUP BY 1 ORDER BY 2 DESC ;
  -- Total revenue by each customer
     SELECT c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS total_revenue
     FROM gold.fact_sales f  LEFT JOIN gold.dim_customers1 c
     ON f.customer_key = c.customer_key
     GROUP BY 1,2,3 ORDER BY 4 DESC ;
  -- Distribution of sold items accross countires
      SELECT c.country, SUM(f.quantity) AS total_item_sold
     FROM gold.fact_sales f  LEFT JOIN gold.dim_customers1 c
     ON f.customer_key = c.customer_key
     GROUP BY 1 ORDER BY 2 DESC ;

/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/

   -- Top 5 products which generates the highest revenue
	  SELECT p.product_name, SUM(f.sales_amount) AS total_revenue
	  FROM gold.fact_sales f  LEFT JOIN gold.dim_products p
	  ON f.product_key = p.product_key
      GROUP BY 1 ORDER BY 2 DESC LIMIT 5;
   -- Top 5 worst performing products in terms of sales
       SELECT p.product_name, SUM(f.sales_amount) AS total_revenue
	  FROM gold.fact_sales f  LEFT JOIN gold.dim_products p
	  ON f.product_key = p.product_key
      GROUP BY 1 ORDER BY 2 LIMIT 5;
   -- top 5 sub-categories with highest revenue
	  SELECT p.subcategory, SUM(f.sales_amount) AS total_revenue
	  FROM gold.fact_sales f  LEFT JOIN gold.dim_products p
	  ON f.product_key = p.product_key
      GROUP BY 1 ORDER BY 2 DESC LIMIT 5;
    -- Top 5 worst performing sub-categories in terms of sales   
       SELECT p.subcategory, SUM(f.sales_amount) AS total_revenue
	  FROM gold.fact_sales f  LEFT JOIN gold.dim_products p
	  ON f.product_key = p.product_key
      GROUP BY 1 ORDER BY 2 LIMIT 5;
	-- Top 10 customers who have generated highest revenue and 3 customers with fewest orders placed
	   SELECT c.customer_key, c.first_name, c.last_name, SUM(f.sales_amount) AS total_revenue
     FROM gold.fact_sales f  LEFT JOIN gold.dim_customers1 c
     ON f.customer_key = c.customer_key
     GROUP BY 1,2,3 ORDER BY 4 DESC LIMIT 10 ;
     
     SELECT c.customer_key, c.first_name, c.last_name, COUNT(DISTINCT order_number) AS total_orders
     FROM gold.fact_sales f  LEFT JOIN gold.dim_customers1 c
     ON f.customer_key = c.customer_key
     GROUP BY 1,2,3 ORDER BY 4 LIMIT 3 ;