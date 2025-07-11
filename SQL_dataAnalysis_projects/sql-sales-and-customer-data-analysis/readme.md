# sql-data-analytics-project
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

A comprehensive collection of SQL scripts for data exploration, analytics, and reporting. These scripts cover various analyses such as database exploration, measures and metrics, time-based trends, cumulative analytics, segmentation, and more. This repository contains SQL queries designed to help data analysts and BI professionals quickly explore, segment, and analyze data within a relational database. Each script focuses on a specific analytical theme and demonstrates best practices for SQL queries.

# Project Roadmap
<img width="2141" height="833" alt="Project Roadmap" src="https://github.com/user-attachments/assets/ed045877-ee60-4bb9-b70b-2ee3136bd259" />
# Data Analysis Approach and Strategy
## 🧠 Data Analysis Strategy & SQL Approach
### 🏗️ Database Design & Schema Modeling:
Created a new gold schema to store cleaned and analysis-ready tables (dim_customers1, dim_products, and fact_sales) that follow a star schema structure, optimizing the data warehouse for analytical queries.

## 🔍 Metadata & Structure Exploration:
Explored database structure using INFORMATION_SCHEMA queries to retrieve all available tables and inspect column metadata for dimensional and fact tables, ensuring clear understanding of data attributes and types.

## 🌍 Dimension Table Profiling:
Performed categorical exploration (e.g., distinct countries, product categories) to validate data consistency, identify categorical hierarchies, and uncover dimension diversity.

## 📅 Temporal Scope Analysis:
Assessed the temporal coverage of the dataset using MIN(), MAX(), and PERIOD_DIFF() to determine the first and last order dates, customer age ranges, and overall data span.

## 📈 Key Metrics Calculation:
Used aggregate functions (SUM, COUNT, AVG) to compute essential KPIs such as total sales, total quantity sold, number of distinct orders, and total customers, laying the foundation for high-level business insights.

## 📊 Magnitude Analysis by Dimension:
Grouped and aggregated metrics across key dimensions like country, gender, and product category to understand distribution, demand hotspots, and revenue drivers.

## 🏆 Ranking-Based Insights:
Applied ORDER BY with LIMIT clauses to rank top-performing and low-performing products, subcategories, and customers, aiding in performance benchmarking and outlier detection.

## 📆 Trend Analysis Over Time:
Analyzed sales trends, customer acquisition, and product performance across both yearly and monthly granularity using date functions and aggregations to detect seasonality and growth patterns.

## 📉 Cumulative and Moving Average Analysis:
Leveraged window functions (SUM() OVER(), AVG() OVER()) to compute running totals and moving averages, helping visualize progressive performance over time.

## 📈 Year-over-Year & Benchmarking Analysis:
Built a performance benchmarking model using LAG() and AVG() OVER() to assess product performance against historical and average sales, enabling year-over-year growth insights and relative benchmarking.

## 📊 Part-to-Whole Contribution Analysis:
Used window functions to compute each category’s share of total sales, facilitating a Pareto-style understanding of which segments contribute most to revenue.

## 🧩 Data Segmentation & Customer Profiling:
Applied CASE logic to segment products by cost range and customers into behavioral categories (VIP, Regular, New), supporting targeted marketing and personalized strategies.

## 📋 Comprehensive Customer Reporting (View):
Created a reusable SQL view customer_report consolidating:

Demographics, total sales, orders, quantity, product count

Derived KPIs like lifespan, recency, average order value, and monthly average spend

Segmentation by customer behavior and age group

## 📦 Product-Level Reporting (View):
Constructed product_report view summarizing:

Product category details, average selling price, total orders and quantity

Customer count, sales recency, lifespan, average revenue per order

Sales segmentation into Low, Mid, and High Performers for strategic inventory decisions

## 📌 View-Based Reporting for Reusability & BI Integration:
Final output was encapsulated into SQL views (customer_report, product_report) to enable seamless integration with BI tools and downstream reporting workflows.
