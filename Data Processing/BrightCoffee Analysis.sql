-- Databricks notebook source
-- DBTITLE 1,Cell 1
-- ==========================================================
-- Bright Coffee Shop Sales Analysis
-- Data Cleaning & Transformation
-- Author: Charlotte Turya
-- ==========================================================

CREATE OR REPLACE VIEW vw_coffee_sales AS

WITH coffee_sales_clean AS (

    SELECT
        transaction_id,
        transaction_date,
        transaction_time,
        transaction_qty,
        store_id,
        store_location,
        product_id,

        -- Convert unit_price from string to numeric
        CAST(REPLACE(unit_price, ',', '.') AS DOUBLE) AS unit_price,

        product_category,
        product_type,
        product_detail,

        -- Calculate Total Sales Amount
        transaction_qty * CAST(REPLACE(unit_price, ',', '.') AS DOUBLE) AS total_amount,

        -- Extract Hour from Transaction Time
        HOUR(transaction_time) AS transaction_hour

    FROM workspace.default.coffee_sales_clean

),

coffee_sales_enriched AS (

    SELECT
        *,

        -- Time of Day Buckets
        CASE
            WHEN transaction_hour BETWEEN 0 AND 11 THEN 'Morning'
            WHEN transaction_hour BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN transaction_hour BETWEEN 18 AND 24 THEN 'Evening'
            ELSE 'Very Late'
        END AS transaction_time_bucket,

        -- Sales Category
        CASE
            WHEN total_amount < 10 THEN 'Small Purchase'
            WHEN total_amount BETWEEN 10 AND 20 THEN 'Medium Purchase'
            ELSE 'Large Purchase'
        END AS sales_category,

        -- Day of Week
        DATE_FORMAT(transaction_date, 'EEEE') AS day_of_week,

        -- Month Name
        DATE_FORMAT(transaction_date, 'MMMM') AS month_name,

        -- Weekend / Weekday
        CASE
            WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type

    FROM coffee_sales_clean

)

SELECT *
FROM coffee_sales_enriched;


-----------------------------------Answering the CEO's questions------------------------------------

-----Query 1: Total Revenue ( This becomes a KPI Card in Power BI)
SELECT
    ROUND(SUM(transaction_qty * CAST(REPLACE(unit_price, ',', '.') AS DOUBLE)), 2) AS total_revenue
FROM coffee_sales_clean;


----Query 2: Revenue by Product Category (Visualization: Horizontal Bar Chart)

SELECT
    product_category,
    ROUND(SUM(transaction_qty * CAST(REPLACE(unit_price, ',', '.') AS DOUBLE)), 2) AS revenue
FROM coffee_sales_clean
GROUP BY product_category
ORDER BY revenue DESC;

---Query 3: Best-Selling Products (Column Chart)
SELECT
    product_detail,
    SUM(transaction_qty) AS quantity_sold
FROM coffee_sales_clean
GROUP BY product_detail
ORDER BY quantity_sold DESC
LIMIT 10;

-----Query 4: Revenue by Product Type (Visualization: Top 10 Bar Chart)
SELECT
    product_type,
    ROUND(SUM(transaction_qty * CAST(REPLACE(unit_price, ',', '.') AS DOUBLE)), 2) AS revenue
FROM coffee_sales_clean
GROUP BY product_type
ORDER BY revenue DESC
LIMIT 10;


------Query 5: Peak Sales Time(Visualization: Column Chart)
SELECT
    CASE
        WHEN HOUR(transaction_time) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN HOUR(transaction_time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN HOUR(transaction_time) BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS transaction_time_bucket,
    ROUND(SUM(transaction_qty * CAST(REPLACE(unit_price, ',', '.') AS DOUBLE)), 2) AS revenue
FROM coffee_sales_clean
GROUP BY transaction_time_bucket
ORDER BY revenue DESC;



-----Query 6: Revenue by Store(Visualization: Bar Chart)
SELECT
    store_location,
    ROUND(SUM(total_amount), 2) AS revenue
FROM coffee_sales_clean
GROUP BY store_location
ORDER BY revenue DESC;

---Query 7: Sales Category Distribution(Visualization: Donut Chart or Stacked Bar Chart)
SELECT
    CASE
        WHEN total_amount < 10 THEN 'Small Purchase'
        WHEN total_amount BETWEEN 10 AND 20 THEN 'Medium Purchase'
        ELSE 'Large Purchase'
    END AS sales_category,
    COUNT(*) AS transactions,
    ROUND(SUM(total_amount),2) AS revenue
FROM coffee_sales_clean
GROUP BY sales_category
ORDER BY revenue DESC;

-----Query 8: Revenue by Store and Product Category (Visualization: Stacked Bar Chart)

SELECT
    store_location,
    product_category,
    ROUND(SUM(total_amount),2) AS total_revenue
FROM coffee_sales_clean
GROUP BY store_location, product_category
ORDER BY store_location, total_revenue DESC;

------Query 9: Which store performs best?(Bar Chart)
SELECT
    store_location,
    ROUND(SUM(total_amount),2) AS total_revenue,
    SUM(transaction_qty) AS quantity_sold,
    RANK() OVER (ORDER BY SUM(total_amount) DESC) AS store_rank
FROM vw_coffee_sales
GROUP BY store_location
ORDER BY store_rank;


-----Query 10:Best-selling products by store
SELECT
    store_location,
    product_detail,
    ROUND(SUM(total_amount),2) AS total_revenue,
    RANK() OVER (
        PARTITION BY store_location
        ORDER BY SUM(total_amount) DESC
    ) AS product_rank
FROM vw_coffee_sales
GROUP BY
    store_location,
    product_detail
ORDER BY
    store_location,
    product_rank
LIMIT 5;


-----Query 11: When are sales at their highest?
SELECT
    transaction_time_bucket,
    COUNT(*) AS total_transactions,
    ROUND(SUM(total_amount),2) AS total_revenue
FROM vw_coffee_sales
GROUP BY transaction_time_bucket
ORDER BY total_revenue DESC;


--------# Key Business Insights------------

---The highest revenue comes from...
----- The best-selling product is...
----- Peak sales occur during...
-------The best-performing store is...
--------Most transactions fall into the Small Purchase category.