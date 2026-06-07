```sql
/*==============================================================================
 Project Name : Sales Data Warehouse - Exploratory Data Analysis
 Database     : DataWarehouse
 Schema       : gold
 Author       : Rahul Pandey
 Description  : 
    This script performs exploratory data analysis on a sales data warehouse.
    It includes customer analysis, product analysis, sales KPIs, revenue trends,
    ranking analysis, running totals, and customer/product segmentation.

 Important Notes:
    1. This script is written for SQL Server / SSMS.
    2. The script assumes the following tables exist:
        - gold.dim_customers
        - gold.dim_product
        - gold.fact_sales
    3. DATETRUNC() is used in some queries.
       Warning: DATETRUNC() is available in SQL Server 2022 and later.
    4. Always validate column names and data types before running in a new database.
==============================================================================*/


/*==============================================================================
 1. CUSTOMER COUNTRY LIST
 Purpose:
    Identify all unique countries where customers are located.
==============================================================================*/

SELECT DISTINCT
    country AS customer_country
FROM gold.dim_customers
ORDER BY customer_country;


/*==============================================================================
 2. PRODUCT CATEGORIES, SUBCATEGORIES, AND PRODUCTS
 Purpose:
    Understand the different product categories and products available.
==============================================================================*/

SELECT DISTINCT
    product_category,
    product_subcategory,
    product_name
FROM gold.dim_product
ORDER BY 
    product_category,
    product_subcategory,
    product_name;


/*==============================================================================
 3. ORDER DATE RANGE
 Purpose:
    Identify the oldest and latest order dates in the sales data.
==============================================================================*/

SELECT
    MIN(order_date) AS oldest_order_date,
    MAX(order_date) AS latest_order_date
FROM gold.fact_sales;


/*==============================================================================
 4. CUSTOMER AGE RANGE
 Purpose:
    Identify oldest and youngest customers based on birthdate.

 Important Logic:
    - Oldest customer = minimum birthdate
    - Youngest customer = maximum birthdate
    - Age is calculated in years using DATEDIFF(YEAR, birthdate, GETDATE())

 Warning:
    DATEDIFF(YEAR) gives an approximate age because it counts year boundaries.
==============================================================================*/

SELECT
    MIN(birthdate) AS oldest_customer_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_customer_age_years,

    MAX(birthdate) AS youngest_customer_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_customer_age_years
FROM gold.dim_customers;


/*==============================================================================
 5. HIGH-LEVEL SALES KPIs
 Purpose:
    Calculate core business performance metrics.
==============================================================================*/

-- Total Revenue
SELECT
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales;


-- Total Items Sold
SELECT
    SUM(quantity) AS total_items_sold
FROM gold.fact_sales;


-- Average Revenue per Sales Line
-- Note: This is the average sales_amount per row, not necessarily product price.
SELECT
    AVG(sales_amount) AS average_sales_amount
FROM gold.fact_sales;


-- Number of Orders
SELECT
    COUNT(DISTINCT order_number) AS number_of_orders
FROM gold.fact_sales;


-- Total Number of Products
SELECT
    COUNT(DISTINCT product_id) AS number_of_products
FROM gold.dim_product;


-- Total Number of Customers
SELECT
    COUNT(DISTINCT customer_key) AS number_of_customers
FROM gold.dim_customers;


/*==============================================================================
 6. GENERIC KPI REPORT
 Purpose:
    Combine multiple business KPIs into one summary report.

 Benefit:
    Useful for dashboard summary cards or quick business review.
==============================================================================*/

SELECT
    'Total Revenue' AS measure_name,
    CAST(SUM(sales_amount) AS DECIMAL(18,2)) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Total Items Sold' AS measure_name,
    CAST(SUM(quantity) AS DECIMAL(18,2)) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Average Sales Amount' AS measure_name,
    CAST(AVG(sales_amount) AS DECIMAL(18,2)) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Number of Orders' AS measure_name,
    CAST(COUNT(DISTINCT order_number) AS DECIMAL(18,2)) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Number of Products' AS measure_name,
    CAST(COUNT(DISTINCT product_id) AS DECIMAL(18,2)) AS measure_value
FROM gold.dim_product

UNION ALL

SELECT
    'Number of Customers' AS measure_name,
    CAST(COUNT(DISTINCT customer_key) AS DECIMAL(18,2)) AS measure_value
FROM gold.dim_customers;


/*==============================================================================
 7. TOTAL CUSTOMERS BY COUNTRY
 Purpose:
    Identify customer distribution by country.
==============================================================================*/

SELECT
    country,
    COUNT(DISTINCT customer_id) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;


/*==============================================================================
 8. TOTAL CUSTOMERS BY GENDER
 Purpose:
    Identify customer distribution by gender.
==============================================================================*/

SELECT
    gender,
    COUNT(DISTINCT customer_id) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;


/*==============================================================================
 9. TOTAL PRODUCTS BY CATEGORY
 Purpose:
    Count number of products in each product category.
==============================================================================*/

SELECT
    product_category,
    COUNT(DISTINCT product_id) AS total_products
FROM gold.dim_product
GROUP BY product_category
ORDER BY total_products DESC;


/*==============================================================================
 10. AVERAGE PRODUCT COST BY CATEGORY
 Purpose:
    Compare average product cost across categories.
==============================================================================*/

SELECT
    product_category,
    AVG(product_cost) AS average_product_cost
FROM gold.dim_product
GROUP BY product_category
ORDER BY average_product_cost DESC;


/*==============================================================================
 11. TOTAL REVENUE BY PRODUCT
 Purpose:
    Identify products generating the highest revenue.
==============================================================================*/

SELECT
    product_key,
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales
GROUP BY product_key
ORDER BY total_revenue DESC;


/*==============================================================================
 12. TOTAL REVENUE BY PRODUCT CATEGORY
 Purpose:
    Identify which product categories generate the most revenue.

 Join Logic:
    fact_sales.product_key joins dim_product.product_key
==============================================================================*/

SELECT
    p.product_category,
    SUM(s.sales_amount) AS total_revenue
FROM gold.dim_product AS p
LEFT JOIN gold.fact_sales AS s
    ON p.product_key = s.product_key
GROUP BY p.product_category
ORDER BY total_revenue DESC;


/*==============================================================================
 13. TOTAL REVENUE BY CUSTOMER
 Purpose:
    Identify top customers based on revenue contribution.
==============================================================================*/

SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
    ON s.customer_key = c.customer_key
GROUP BY 
    c.customer_key,
    CONCAT(c.first_name, ' ', c.last_name)
ORDER BY total_revenue DESC;


/*==============================================================================
 14. TOTAL ITEMS SOLD BY COUNTRY
 Purpose:
    Analyze quantity sold by customer country.

 Important Correction:
    Use SUM(quantity), not COUNT(product_key), because quantity shows actual items sold.
==============================================================================*/

SELECT
    c.country,
    SUM(s.quantity) AS total_items_sold
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
    ON s.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_items_sold DESC;


/*==============================================================================
 15. TOP 5 PRODUCTS BY REVENUE
 Purpose:
    Identify the top 5 products generating the highest revenue.
==============================================================================*/

SELECT
    p.product_name,
    t.total_revenue
FROM
(
    SELECT TOP 5
        product_key,
        SUM(sales_amount) AS total_revenue
    FROM gold.fact_sales
    GROUP BY product_key
    ORDER BY total_revenue DESC
) AS t
LEFT JOIN gold.dim_product AS p
    ON t.product_key = p.product_key
ORDER BY t.total_revenue DESC;


/*==============================================================================
 16. BOTTOM 5 PRODUCTS BY REVENUE
 Purpose:
    Identify the bottom 5 products generating the lowest revenue.

 Note:
    This includes only products that exist in fact_sales.
==============================================================================*/

SELECT
    p.product_name,
    t.total_revenue
FROM
(
    SELECT TOP 5
        product_key,
        SUM(sales_amount) AS total_revenue
    FROM gold.fact_sales
    GROUP BY product_key
    ORDER BY total_revenue ASC
) AS t
LEFT JOIN gold.dim_product AS p
    ON t.product_key = p.product_key
ORDER BY t.total_revenue ASC;


/*==============================================================================
 17. YEARLY SALES TREND WITH YEAR-OVER-YEAR CHANGE
 Purpose:
    Analyze total sales by year and compare with previous year.
==============================================================================*/

SELECT
    YEAR(order_date) AS sales_year,
    SUM(sales_amount) AS total_sales,

    LAG(SUM(sales_amount)) OVER 
        (ORDER BY YEAR(order_date)) AS previous_year_sales,

    SUM(sales_amount)
        - LAG(SUM(sales_amount)) OVER 
            (ORDER BY YEAR(order_date)) AS yoy_change
FROM gold.fact_sales
GROUP BY YEAR(order_date)
ORDER BY sales_year;


/*==============================================================================
 18. MONTHLY SALES TREND WITH MONTH-OVER-MONTH CHANGE
 Purpose:
    Analyze monthly sales trend over time.

 Important Correction:
    Grouping only by DATEPART(MONTH, order_date) combines January of all years.
    This query groups by actual year-month instead.
==============================================================================*/

WITH monthly_sales AS
(
    SELECT
        DATETRUNC(MONTH, order_date) AS sales_month,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    GROUP BY DATETRUNC(MONTH, order_date)
)
SELECT
    sales_month,
    total_sales,

    LAG(total_sales) OVER 
        (ORDER BY sales_month) AS previous_month_sales,

    total_sales 
        - LAG(total_sales) OVER 
            (ORDER BY sales_month) AS mom_change
FROM monthly_sales
ORDER BY sales_month;


/*==============================================================================
 19. DAILY SALES TREND WITH DAY-OVER-DAY CHANGE
 Purpose:
    Analyze sales trend by actual date.

 Important Correction:
    Grouping only by DATEPART(DAY, order_date) combines the 1st day of every month.
    This query groups by the actual order date.
==============================================================================*/

WITH daily_sales AS
(
    SELECT
        CAST(order_date AS DATE) AS sales_date,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    GROUP BY CAST(order_date AS DATE)
)
SELECT
    sales_date,
    total_sales,

    LAG(total_sales) OVER 
        (ORDER BY sales_date) AS previous_day_sales,

    total_sales
        - LAG(total_sales) OVER 
            (ORDER BY sales_date) AS dod_change
FROM daily_sales
ORDER BY sales_date;


/*==============================================================================
 20. YEARLY RUNNING TOTAL OF SALES
 Purpose:
    Calculate cumulative sales over years.
==============================================================================*/

SELECT
    YEAR(order_date) AS sales_year,
    SUM(sales_amount) AS total_sales,

    SUM(SUM(sales_amount)) OVER 
        (ORDER BY YEAR(order_date)) AS running_total_sales
FROM gold.fact_sales
GROUP BY YEAR(order_date)
ORDER BY sales_year;


/*==============================================================================
 21. MONTHLY RUNNING TOTAL OF SALES WITHIN EACH YEAR
 Purpose:
    Calculate cumulative monthly sales for each year.

 Note:
    Running total resets every year because of PARTITION BY YEAR(order_date).
==============================================================================*/

SELECT
    YEAR(order_date) AS sales_year,
    DATETRUNC(MONTH, order_date) AS sales_month,

    SUM(sales_amount) AS total_sales,

    SUM(SUM(sales_amount)) OVER
    (
        PARTITION BY YEAR(order_date)
        ORDER BY DATETRUNC(MONTH, order_date)
    ) AS running_total_sales
FROM gold.fact_sales
GROUP BY
    YEAR(order_date),
    DATETRUNC(MONTH, order_date)
ORDER BY
    sales_year,
    sales_month;


/*==============================================================================
 22. PRODUCT SEGMENTATION BY COST RANGE
 Purpose:
    Segment products into cost-based groups.

 Business Logic:
    <= 100   : Affordable
    <= 500   : Premium
    <= 1000  : Expensive
    <= 1500  : Luxury
    > 1500   : Ultra Luxury
==============================================================================*/

WITH product_segment_count AS
(
    SELECT
        product_id,
        product_cost,

        CASE
            WHEN product_cost <= 100 THEN 'Affordable'
            WHEN product_cost <= 500 THEN 'Premium'
            WHEN product_cost <= 1000 THEN 'Expensive'
            WHEN product_cost <= 1500 THEN 'Luxury'
            ELSE 'Ultra Luxury'
        END AS product_segment
    FROM gold.dim_product
)
SELECT
    product_segment,
    COUNT(*) AS number_of_products
FROM product_segment_count
GROUP BY product_segment
ORDER BY number_of_products DESC;


/*==============================================================================
 23. CUSTOMER SEGMENTATION
 Purpose:
    Segment customers into VIP, Regular, and New Customer groups.

 Business Logic:
    VIP:
        Total spending > 5000 
        AND customer history >= 12 months

    Regular:
        Total spending <= 5000 
        AND customer history >= 12 months

    New Customer:
        Customer history < 12 months

 Important Note:
    Customer history is calculated from the customer's first order date.
==============================================================================*/

WITH customer_spending AS
(
    SELECT
        customer_key,
        SUM(sales_amount) AS total_spending,
        DATEDIFF(MONTH, MIN(order_date), GETDATE()) AS customer_since_months
    FROM gold.fact_sales
    GROUP BY customer_key
),
customer_segments AS
(
    SELECT
        customer_key,
        total_spending,
        customer_since_months,

        CASE
            WHEN total_spending > 5000 
                 AND customer_since_months >= 12 
                THEN 'VIP'

            WHEN total_spending <= 5000 
                 AND customer_since_months >= 12 
                THEN 'Regular'

            ELSE 'New Customer'
        END AS customer_type
    FROM customer_spending
)
SELECT
    customer_type,
    COUNT(customer_key) AS number_of_customers
FROM customer_segments
GROUP BY customer_type
ORDER BY number_of_customers DESC;


/*==============================================================================
 End of Script
==============================================================================*/
```
