-- List all columns from all tables including column name, data type, and position
SELECT
  table_name,
  column_name,
  data_type,
  ordinal_position
FROM
`bigquery-scaler-tutorial.Target_SQL_business_case_2025.INFORMATION_SCHEMA.COLUMNS`
ORDER BY
  table_name,
  ordinal_position;

-- Count number of columns in each table
SELECT table_name, COUNT(DISTINCT column_name) AS column_count FROM (
  SELECT
    table_name,
    column_name,
    data_type,
    ordinal_position
  FROM
  `bigquery-scaler-tutorial.Target_SQL_business_case_2025.INFORMATION_SCHEMA.COLUMNS`
  ORDER BY
    table_name,
    ordinal_position
) GROUP BY table_name;

-- Find first and last order purchase timestamps
SELECT MIN(order_purchase_timestamp) AS first_order_placed_date,
       MAX(order_purchase_timestamp) AS last_order_placed_date
FROM `Target_SQL_business_case_2025.orders`;

-- Count number of unique customer states and cities with orders
SELECT COUNT(DISTINCT customer_state) AS states,
       COUNT(DISTINCT customer_city) AS city
FROM `Target_SQL_business_case_2025.customers`
WHERE customer_id IN (
  SELECT customer_id FROM `Target_SQL_business_case_2025.orders`
);

-- Count monthly orders placed over years
SELECT EXTRACT(YEAR FROM order_purchase_timestamp) AS year_,
       EXTRACT(MONTH FROM order_purchase_timestamp) AS month_,
       COUNT(DISTINCT order_id) AS orders
FROM `Target_SQL_business_case_2025.orders`
GROUP BY 1, 2
ORDER BY 1, 2;

-- Analyze order distribution across parts of the day
SELECT
  SUM(CASE WHEN HOUR BETWEEN 0 AND 6 THEN orders END) AS dawn,
  SUM(CASE WHEN HOUR BETWEEN 7 AND 12 THEN orders END) AS Morning,
  SUM(CASE WHEN HOUR BETWEEN 13 AND 18 THEN orders END) AS afternoon,
  SUM(CASE WHEN HOUR BETWEEN 19 AND 24 THEN orders END) AS night
FROM (
  SELECT EXTRACT(HOUR FROM order_purchase_timestamp) AS HOUR,
         COUNT(DISTINCT order_id) AS orders
  FROM `Target_SQL_business_case_2025.orders`
  GROUP BY 1
);

-- Count monthly orders for each state
SELECT c.customer_state,
       EXTRACT(MONTH FROM o.order_purchase_timestamp) AS order_month,
       COUNT(DISTINCT o.order_id) AS orders
FROM `Target_SQL_business_case_2025.orders` o
JOIN `Target_SQL_business_case_2025.customers` c ON o.customer_id = c.customer_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Count customers per state
SELECT customer_state,
       COUNT(DISTINCT customer_id) AS customer_count
FROM `Target_SQL_business_case_2025.customers`
GROUP BY customer_state
ORDER BY customer_count DESC;

-- Calculate year-wise cost and percentage increase from 2017 to 2018
WITH base AS (
  SELECT EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year_,
         SUM(p.payment_value) AS cost
  FROM `Target_SQL_business_case_2025.orders` o
  JOIN `Target_SQL_business_case_2025.payments` p ON o.order_id = p.order_id
  WHERE (EXTRACT(YEAR FROM o.order_purchase_timestamp) BETWEEN 2017 AND 2018)
    AND (EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 8)
  GROUP BY 1
),
base1 AS (
  SELECT *, LEAD(cost, 1) OVER(ORDER BY year_) AS next_year_cost
  FROM base
)
SELECT *, ROUND((next_year_cost - cost) / cost * 100, 2) AS percentage_increase
FROM base1;

-- Total and average payment value per state
SELECT c.customer_state,
       ROUND(SUM(p.payment_value), 2) AS total_cost,
       ROUND(AVG(p.payment_value), 2) AS avg_cost
FROM `Target_SQL_business_case_2025.orders` o
JOIN `Target_SQL_business_case_2025.payments` p ON o.order_id = p.order_id
JOIN `Target_SQL_business_case_2025.customers` c ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 2 DESC, 3 DESC;

-- Total and average freight cost per state
SELECT c.customer_state,
       ROUND(SUM(oi.freight_value), 2) AS total_freight_cost,
       ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost
FROM `Target_SQL_business_case_2025.orders` o
JOIN `Target_SQL_business_case_2025.order_items` oi ON o.order_id = oi.order_id
JOIN `Target_SQL_business_case_2025.customers` c ON c.customer_id = o.customer_id
GROUP BY 1
ORDER BY 2 DESC, 3 DESC;

-- Calculate delivery time and estimated delivery difference per order
SELECT order_id,
       DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
       DATE_DIFF(order_delivered_customer_date, order_estimated_delivery_date, DAY) AS diff_estimated_delivery
FROM `Target_SQL_business_case_2025.orders`;

-- Top 5 states with highest and lowest average freight value
(SELECT c.customer_state,
        ROUND(AVG(oi.freight_value), 2) AS avg_freight_val
 FROM `Target_SQL_business_case_2025.orders` o
 JOIN `Target_SQL_business_case_2025.order_items` oi ON o.order_id = oi.order_id
 JOIN `Target_SQL_business_case_2025.customers` c ON c.customer_id = o.customer_id
 GROUP BY 1
 ORDER BY 2 DESC
 LIMIT 5)
UNION ALL
(SELECT c.customer_state,
        ROUND(AVG(oi.freight_value), 2) AS avg_freight_val
 FROM `Target_SQL_business_case_2025.orders` o
 JOIN `Target_SQL_business_case_2025.order_items` oi ON o.order_id = oi.order_id
 JOIN `Target_SQL_business_case_2025.customers` c ON c.customer_id = o.customer_id
 GROUP BY 1
 ORDER BY 2
 LIMIT 5);

-- Top 5 states with highest and lowest average delivery time
(SELECT c.customer_state,
        ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)), 2) AS avg_time_to_deliver
 FROM `Target_SQL_business_case_2025.orders` o
 JOIN `Target_SQL_business_case_2025.customers` c ON o.customer_id = c.customer_id
 GROUP BY 1
 ORDER BY 2 DESC
 LIMIT 5)
UNION ALL
(SELECT c.customer_state,
        ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)), 2) AS avg_time_to_deliver
 FROM `Target_SQL_business_case_2025.orders` o
 JOIN `Target_SQL_business_case_2025.customers` c ON o.customer_id = c.customer_id
 GROUP BY 1
 ORDER BY 2
 LIMIT 5);

-- Top 5 states where actual delivery was faster than estimated
SELECT c.customer_state,
       ROUND(AVG(DATE_DIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date, DAY)), 2) AS avg_diff_estimated_delivery
FROM `Target_SQL_business_case_2025.orders` o
JOIN `Target_SQL_business_case_2025.customers` c ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Count monthly orders by payment type
SELECT COUNT(DISTINCT o.order_id),
       EXTRACT(MONTH FROM o.order_purchase_timestamp) AS order_month,
       p.payment_type
FROM `Target_SQL_business_case_2025.payments` p
JOIN `Target_SQL_business_case_2025.orders` o ON p.order_id = o.order_id
GROUP BY 2, 3
ORDER BY 1 DESC, 2;

-- Count orders by number of payment installments
SELECT COUNT(DISTINCT o.order_id),
       p.payment_installments
FROM `Target_SQL_business_case_2025.payments` p
JOIN `Target_SQL_business_case_2025.orders` o ON p.order_id = o.order_id
GROUP BY 2
ORDER BY 1 DESC;
