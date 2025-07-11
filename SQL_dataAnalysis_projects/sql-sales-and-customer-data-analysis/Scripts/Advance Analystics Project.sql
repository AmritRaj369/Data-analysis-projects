/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

   -- Analysis of  measures change over time
      -- measure changes over year
         SELECT YEAR(order_date) AS order_year, SUM(sales_amount), COUNT(DISTINCT customer_key)AS total_customer, 
         SUM(quantity) AS total_quantity
         FROM gold.fact_sales
         WHERE YEAR(order_date) IS NOT NULL
         GROUP BY 1 ORDER BY 1 DESC;
	  -- measure chnage over month
         SELECT YEAR(order_date) AS order_year, 
         MONTH(order_date) AS order_month, SUM(sales_amount), COUNT(DISTINCT customer_key)AS total_customer, 
         SUM(quantity) AS total_quantity
         FROM gold.fact_sales
         WHERE YEAR(order_date) IS NOT NULL
         GROUP BY 1, 2 ORDER BY 1 DESC, 2;
/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/
   -- Running sales overtime
   SELECT order_month, total_sales, SUM(total_sales) OVER( ORDER BY order_month) AS cummulative_sales, 
   ROUND(AVG(total_sales) OVER( ORDER BY order_month), 0) AS moving_avg_sales  
   FROM(SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month, SUM(sales_amount) AS total_sales, ROUND(AVG(sales_amount),2) AS average_sales
   FROM gold.fact_sales WHERE order_date IS NOT NULL GROUP BY 1) AS t;
   
   SELECT  DISTINCT DATE_FORMAT(order_date, '%Y-%m-01') AS  order_month, 
   sales_amount,SUM(sales_amount) OVER( partition by YEAR(order_date) ORDER BY MONTH(order_date)) AS cummulative_sales 
   FROM gold.fact_sales WHERE  order_date IS NOT NULL;
   
/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/
   -- Analysis of yearly performance of products by comparing their sales to both 
   -- the average sales performance of the product and previous year sales
   WITH yearly_product_sales AS(
    SELECT YEAR(f.order_date) AS order_year, p.product_name AS product_name, SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f  LEFT JOIN gold.dim_products p    ON f.product_key = p.product_key 
    WHERE  order_date IS NOT NULL
    GROUP BY 1,2)
    SELECT order_year, product_name, current_sales
    , ROUND(AVG(current_sales) OVER(PARTITION BY product_name), 0) AS average_sales,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS avg_diff,
    CASE
    WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
	WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
	ELSE 'Avg'
    END AS avg_chnage,
    -- Year over Year analysis
    LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
	current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_diff,
	CASE
    WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
	WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year)  < 0 THEN 'Decrease'
	ELSE 'Same'
    END AS py_chnage
    FROM yearly_product_sales
    ORDER BY 2,1 ;

/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
   -- Analyzing how individual part is performing as compared to overall, allowing us to understand which catagory has the greatest
   -- impact on business
   
   -- Which catagory contributes the most to overall sales
     WITH category_sales AS(SELECT p.category AS category, SUM(f.sales_amount) AS category_sales
      FROM gold.fact_sales f  LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
      GROUP BY p.category
    )
    SELECT category, category_sales, SUM(category_sales) OVER() AS overall_sales,
    CONCAT(ROUND((category_sales/SUM(category_sales) OVER())*100, 2), "%") AS percentage_sales FROM category_sales;
    
    -- We can do similar things for other measures like quantity.
    
    
/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/
  /*Segment products into cost ranges and count how many products fall into each segemnt*/
  WITH cost_segment AS
  (SELECT product_key, product_name, cost,
  CASE 
  WHEN cost<100 THEN 'Below 100'
  WHEN cost BETWEEN 100 AND 500 THEN "Between 100 and 500"
  WHEN cost BETWEEN 500 AND 1000 THEN "Between 500 and 1000"
  else 'above 1000'
  END AS cost_range
  FROM gold.dim_products)
  SELECT cost_range, COUNT(product_key) FROM cost_segment
  GROUP BY 1 ORDER BY 2 desc;
   
  /*Group customer into 3 segements based on there spending behaviour 
     - VIP : Customer with atleast 12 month of history and spends more than 5000 euros
     - Regular : Customer  with atleast 12 month of history and spends less than or equal to 5000 euros
     - New : Customer with life span of less than 12 months
     and find total number of customer for each group
  */
  WITH customers_details AS(SELECT c.customer_key, SUM(f.sales_amount) AS total_sales, MIN(f.order_date) AS first_order,
  MAX(f.order_date) AS last_order, TIMESTAMPDIFF(month, MIN(f.order_date), MAX(f.order_date)) AS time_span
  FROM gold.fact_sales f LEFT JOIN gold.dim_customers1 c 
  ON f.customer_key = c.customer_key WHERE f.order_date IS NOT NULL
  GROUP BY 1 ), customer_segment_details AS(
  SELECT customer_key, total_sales, CASE
  WHEN time_span >= 12 AND total_sales > 5000 THEN 'VIP Customer'
  WHEN time_span >= 12 AND total_sales <= 5000 THEN 'Regular Customer'
  ELSE 'New Customer'
  END AS customer_segments
  FROM customers_details
   ) SELECT customer_segments, COUNT(customer_key) AS customer_count FROM customer_segment_details 
   GROUP BY 1 ORDER BY 2 DESC;
   
   /*
   =====================================================================================================================================
   Customer Report
   =====================================================================================================================================
   Purposes:
     - This report consolidates key customer metrics and behaviours
   Hightlight:
	   1. Gather essential field such as names, ages and transaction details.
       2. Segment customer into categories(VIP, Regular, New) and age group
       3. Aggregate customer-level metrics:
          - total order 
          - total sales
          - total quantity purchased
          - total products
          - lifespan (in months)
	   4. Calculates Valueble KPIs
          - recency (month since last order)
          - average order value
          - average monthly spend
	====================================================================================================================================
*/
CREATE VIEW gold.customer_report AS
WITH base_query AS(
/*---------------------------------------------------------------------------
Base Query : Retrievs core columns form tables
-----------------------------------------------------------------------------*/
SELECT f.order_number, f.product_key,f.order_date, f.sales_amount, f.quantity
,c.customer_key, c.customer_number, CONCAT(c.first_name, ' ' ,c.last_name) AS customer_name,
TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
FROM gold.fact_sales f LEFT JOIN gold.dim_customers1 c
ON f.customer_key = c.customer_key ), 
customer_aggregation AS(
/*---------------------------------------------------------------------------
Customer Aggregation : Summarizes key metrics at the customer level
-----------------------------------------------------------------------------*/
SELECT customer_key, customer_number, customer_name,age,
COUNT(DISTINCT order_number) AS total_orders, SUM(sales_amount) AS total_sales, 
SUM(quantity) AS total_quantity, COUNT(DISTINCT product_key) AS total_product,
MAX(order_date) AS last_order, TIMESTAMPDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 1,2,3,4)
SELECT  customer_key, customer_number, customer_name,age,
total_sales, 
CASE
WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP Customer'
WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular Customer'
ELSE 'New Customer'
END AS customer_segments,
CASE
WHEN age < 20 THEN "Under 20"
WHEN age BETWEEN 20 AND 29 THEN "20-29"
WHEN age BETWEEN 30 AND 39 THEN "30-39"
WHEN age BETWEEN 40 AND 49 THEN "40-49"
ELSE "50 and above"
END AS age_group,
total_product,
lifespan, last_order,
TIMESTAMPDIFF(MONTH, last_order, CURDATE()) AS recency,
ROUND(CASE WHEN total_orders = 0 THEN 0
ELSE total_sales/total_orders 
END,2 ) AS avg_order_val,
CASE WHEN lifespan = 0 THEN total_sales
ELSE total_sales/lifespan END AS mothly_avg_sales
FROM customer_aggregation;

SELECT * FROM gold.customer_report;

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/


CREATE VIEW gold.product_report AS
WITH base_query AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
SELECT 
     p.product_key, 
     p.product_name, 
     p.category, 
     p.subcategory, 
     p.cost, 
     f.sales_amount, 
     f.order_number, 
     f.customer_key, 
     f.order_date, 
     f.quantity
FROM gold.dim_products p 
LEFT JOIN gold.fact_sales f 
ON p.product_key = f.product_key 
WHERE f.order_date IS NOT NULL
), 
product_aggregation AS(
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT 
  product_key, 
  product_name, 
  category, 
  subcategory, 
  cost, 
  COUNT(DISTINCT order_number) AS total_order, 
  SUM(sales_amount) AS total_sales, 
  SUM(quantity) AS total_quantity, 
  COUNT(DISTINCT customer_key) AS total_customer, 
  MAX(order_date) AS last_sale_date, 
  TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
  ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price 
  FROM base_query
  GROUP BY  1,2,3,4,5
)  
/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
     product_key, 
     product_name, 
     category, 
     subcategory, 
     cost, 
     avg_selling_price, 
     total_order, 
     total_sales, 
     total_quantity, 
     total_customer, 
     TIMESTAMPDIFF(MONTH, last_sale_date, CURDATE()) AS Recency, 
     lifespan, 
     ROUND(CASE WHEN total_order = 0 THEN 0 ELSE total_sales/total_order END, 2) AS avg_order_revenue, 
     ROUND(CASE WHEN lifespan = 0  THEN total_sales ELSE total_sales/lifespan END, 2) AS monthly_avg_sales, 
     CASE WHEN total_sales < 90000 THEN "Low Performer" WHEN total_sales > 700000 THEN "Mid-performer" ELSE "High Performer" END AS product_segment 
 FROM product_aggregation;
 
 SELECT * FROM gold.product_report;




   
   
   
   
   
   
   