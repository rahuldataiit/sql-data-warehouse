/*
===============================================================================
 Script Name   : load_silver.sql
 Project       : Data Warehouse Project
 Layer         : Silver Layer
 Database      : DataWarehouse
 Author        : Rahul / Samradni
 Purpose       : 
    This stored procedure loads and cleans data from the Bronze layer into 
    the Silver layer.

    The Silver layer applies basic data cleaning, standardization, deduplication,
    date conversion, and business-rule-based transformations.

===============================================================================
 IMPORTANT INSTRUCTIONS
===============================================================================

1. Run this script only after the Bronze layer has been successfully loaded.

2. This procedure reads data from:
      - bronze.crm_cust_info
      - bronze.crm_prd_info
      - bronze.crm_sales_info
      - bronze.erp_cust_az12
      - bronze.erp_loc_a101
      - bronze.erp_px_cat_g1v2

3. This procedure loads cleaned data into:
      - silver.crm_cust_info
      - silver.crm_prd_info
      - silver.crm_sales_info
      - silver.erp_cust_az12
      - silver.erp_loc_a101
      - silver.erp_px_cat_g1v2

4. WARNING:
      This script uses DROP TABLE IF EXISTS for CRM Silver tables.
      Running this procedure will delete and recreate the following tables:
          - silver.crm_cust_info
          - silver.crm_prd_info
          - silver.crm_sales_info

5. WARNING:
      This script uses TRUNCATE TABLE for ERP Silver tables.
      Running this procedure will remove existing data from:
          - silver.erp_cust_az12
          - silver.erp_loc_a101
          - silver.erp_px_cat_g1v2

6. Do NOT drop or recreate Bronze tables inside this procedure.
      Bronze tables are the raw source layer and should remain unchanged.

7. Date Handling:
      - CRM sales dates are stored in integer format such as 20220514.
      - These are converted into proper DATE format using TRY_CONVERT.
      - Invalid dates or zero values are converted to NULL.

8. Product End Date Logic:
      - Product end date is calculated as one day before the next product start date.
      - DATEADD(DAY, -1, next_start_date) is used.
      - Do NOT use date - 1 because SQL Server will throw:
            Operand type clash: date is incompatible with int

9. Recommended:
      Test this procedure in a development database before running it in production.

===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time_batch DATETIME;
    DECLARE @end_time_batch   DATETIME;
    DECLARE @start_time       DATETIME;
    DECLARE @end_time         DATETIME;

    SET @start_time_batch = GETDATE();

    BEGIN TRY

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';


        /*========================================================================
          1. Load silver.crm_cust_info
        ========================================================================*/

        SET @start_time = GETDATE();

        DROP TABLE IF EXISTS silver.crm_cust_info;

        CREATE TABLE silver.crm_cust_info
        (
            cst_id              INT,
            cst_key             VARCHAR(50),
            cst_firstname       VARCHAR(50),
            cst_lastname        VARCHAR(50),
            cst_marital_status  VARCHAR(10),
            cst_gndr            VARCHAR(10),
            cst_create_date     DATE
        );

        PRINT '>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info
        (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,

            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,

            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date
        FROM
        (
            SELECT
                *,
                ROW_NUMBER() OVER 
                (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        /*========================================================================
          2. Load silver.crm_prd_info
        ========================================================================*/

        SET @start_time = GETDATE();

        DROP TABLE IF EXISTS silver.crm_prd_info;

        CREATE TABLE silver.crm_prd_info
        (
            prd_id          INT,
            cat_id          NVARCHAR(50),
            prd_key         VARCHAR(50),
            prd_nm          VARCHAR(50),
            prd_cost        INT,
            prd_line        VARCHAR(20),
            prd_start_dt    DATE,
            prd_end_dt      DATE
        );

        PRINT '>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info
        (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

            prd_nm,

            ISNULL(prd_cost, 0) AS prd_cost,

            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            DATEADD
            (
                DAY,
                -1,
                LEAD(prd_start_dt) OVER 
                (
                    PARTITION BY prd_key 
                    ORDER BY prd_start_dt
                )
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        /*========================================================================
          3. Load silver.crm_sales_info
        ========================================================================*/

        SET @start_time = GETDATE();

        DROP TABLE IF EXISTS silver.crm_sales_info;

        CREATE TABLE silver.crm_sales_info
        (
            sls_ord_num     VARCHAR(50),
            sls_prd_key     VARCHAR(50),
            sls_cust_id     INT,
            sls_order_dt    DATE,
            sls_ship_dt     DATE,
            sls_due_dt      DATE,
            sls_sales       INT,
            sls_quantity    INT,
            sls_price       INT
        );

        PRINT '>> Inserting Data Into: silver.crm_sales_info';

        INSERT INTO silver.crm_sales_info
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            CASE
                WHEN sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR(20))) != 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CAST(sls_order_dt AS VARCHAR(8)), 112)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt = 0 OR LEN(CAST(sls_ship_dt AS VARCHAR(20))) != 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CAST(sls_ship_dt AS VARCHAR(8)), 112)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt = 0 OR LEN(CAST(sls_due_dt AS VARCHAR(20))) != 8 THEN NULL
                ELSE TRY_CONVERT(DATE, CAST(sls_due_dt AS VARCHAR(8)), 112)
            END AS sls_due_dt,

            CASE
                WHEN sls_sales IS NULL 
                     OR sls_sales <= 0 
                     OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_info;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';


        /*========================================================================
          4. Load silver.erp_cust_az12
        ========================================================================*/

        SET @start_time = GETDATE();

        IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NULL
        BEGIN
            CREATE TABLE silver.erp_cust_az12
            (
                cid     VARCHAR(50),
                bdate   DATE,
                gen     VARCHAR(10)
            );
        END;

        PRINT '>> Truncating Table: silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        /*========================================================================
          5. Load silver.erp_loc_a101
        ========================================================================*/

        SET @start_time = GETDATE();

        IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NULL
        BEGIN
            CREATE TABLE silver.erp_loc_a101
            (
                cid     VARCHAR(50),
                cntry   VARCHAR(50)
            );
        END;

        PRINT '>> Truncating Table: silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,

            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        /*========================================================================
          6. Load silver.erp_px_cat_g1v2
        ========================================================================*/

        SET @start_time = GETDATE();

        IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NULL
        BEGIN
            CREATE TABLE silver.erp_px_cat_g1v2
            (
                id              VARCHAR(50),
                cat             VARCHAR(50),
                subcat          VARCHAR(50),
                maintenance     VARCHAR(50)
            );
        END;

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ---------------------------------------------';


        SET @end_time_batch = GETDATE();

        PRINT '================================================';
        PRINT 'Silver Layer Loading Completed Successfully';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time_batch, @end_time_batch) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOADING';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line    : ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '================================================';

    END CATCH;

END;
GO
