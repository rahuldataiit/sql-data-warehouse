/*
===============================================================================
Script Name    : load_bronze.sql
Purpose        : Loads raw source data into the Bronze layer tables.

Description    :
    This stored procedure prepares and loads the Bronze layer of the data
    warehouse. It performs the following steps:

    1. Drops and recreates CRM and ERP Bronze tables.
    2. Loads raw data from CSV files using BULK INSERT.
    3. Prints progress messages for each table load.
    4. Captures loading duration for each table.
    5. Uses TRY...CATCH error handling to capture and display load failures.

Tables Created and Loaded:
    CRM Source Tables:
        - bronze.crm_cust_info
        - bronze.crm_prd_info
        - bronze.crm_sales_info

    ERP Source Tables:
        - bronze.erp_cust_az12
        - bronze.erp_loc_a101
        - bronze.erp_px_cat_g1v2

Important Notes:
    - This procedure currently uses local file paths:
          D:\WAREHOUSE PROJECT\

    - SQL Server must have permission to access this folder.
    - CSV files must exist in the specified location before running this procedure.
    - This script drops and recreates the Bronze tables every time it runs.
      Any existing data in these tables will be deleted.
    - This procedure is intended for development or learning purposes.
      For production, consider using staging tables, audit logs, and safer
      table reload strategies.

Warning:
    Running this procedure will permanently remove existing data from the
    listed Bronze tables because it uses DROP TABLE IF EXISTS.

Execution:
    EXEC bronze.load_bronze;
===============================================================================
*/

USE master;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @batch_start_time DATETIME,
        @batch_end_time   DATETIME,
        @start_time       DATETIME,
        @end_time         DATETIME;

    SET @batch_start_time = GETDATE();

    BEGIN TRY
        PRINT '===================================';
        PRINT 'Loading Bronze Layer';
        PRINT '===================================';

        PRINT '***********************************';
        PRINT 'Creating CRM Tables';
        PRINT '***********************************';

        DROP TABLE IF EXISTS bronze.crm_cust_info;

        CREATE TABLE bronze.crm_cust_info
        (
            cst_id             INT,
            cst_key            VARCHAR(50),
            cst_firstname      VARCHAR(50),
            cst_lastname       VARCHAR(50),
            cst_marital_status VARCHAR(10),
            cst_gndr           VARCHAR(10),
            cst_create_date    DATE
        );

        DROP TABLE IF EXISTS bronze.crm_prd_info;

        CREATE TABLE bronze.crm_prd_info
        (
            prd_id       INT,
            prd_key      VARCHAR(50),
            prd_nm       VARCHAR(50),
            prd_cost     INT,
            prd_line     VARCHAR(5),
            prd_start_dt DATE,
            prd_end_dt   DATE
        );

        DROP TABLE IF EXISTS bronze.crm_sales_info;

        CREATE TABLE bronze.crm_sales_info
        (
            sls_ord_num  VARCHAR(50),
            sls_prd_key  VARCHAR(50),
            sls_cust_id  INT,
            sls_order_dt VARCHAR(50),
            sls_ship_dt  VARCHAR(50),
            sls_due_dt   VARCHAR(50),
            sls_sales    INT,
            sls_quantity INT,
            sls_price    INT
        );

        PRINT '***********************************';
        PRINT 'Loading CRM Tables';
        PRINT '***********************************';

        PRINT 'Loading table: bronze.crm_cust_info';
        SET @start_time = GETDATE();

        BULK INSERT bronze.crm_cust_info
        FROM 'D:\WAREHOUSE PROJECT\cust_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        PRINT 'Loading table: bronze.crm_prd_info';
        SET @start_time = GETDATE();

        BULK INSERT bronze.crm_prd_info
        FROM 'D:\WAREHOUSE PROJECT\prd_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        PRINT 'Loading table: bronze.crm_sales_info';
        SET @start_time = GETDATE();

        BULK INSERT bronze.crm_sales_info
        FROM 'D:\WAREHOUSE PROJECT\sales_details.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        PRINT '***********************************';
        PRINT 'Creating ERP Tables';
        PRINT '***********************************';

        DROP TABLE IF EXISTS bronze.erp_cust_az12;

        CREATE TABLE bronze.erp_cust_az12
        (
            CID   VARCHAR(50),
            BDATE DATE,
            GEN   VARCHAR(10)
        );

        DROP TABLE IF EXISTS bronze.erp_loc_a101;

        CREATE TABLE bronze.erp_loc_a101
        (
            CID   VARCHAR(30),
            CNTRY VARCHAR(30)
        );

        DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

        CREATE TABLE bronze.erp_px_cat_g1v2
        (
            ID          VARCHAR(30),
            CAT         VARCHAR(30),
            SUBCAT      VARCHAR(30),
            MAINTENANCE VARCHAR(30)
        );

        PRINT '***********************************';
        PRINT 'Loading ERP Tables';
        PRINT '***********************************';

        PRINT 'Loading table: bronze.erp_cust_az12';
        SET @start_time = GETDATE();

        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\WAREHOUSE PROJECT\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        PRINT 'Loading table: bronze.erp_loc_a101';
        SET @start_time = GETDATE();

        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\WAREHOUSE PROJECT\LOC_A101.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        PRINT 'Loading table: bronze.erp_px_cat_g1v2';
        SET @start_time = GETDATE();

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\WAREHOUSE PROJECT\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>>> Loading duration: ' 
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) 
              + ' seconds';

        SET @batch_end_time = GETDATE();

        PRINT '===================================';
        PRINT 'Bronze Layer Load Completed Successfully';
        PRINT 'Total Batch Duration: ' 
              + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) 
              + ' seconds';
        PRINT '===================================';

    END TRY

    BEGIN CATCH
        PRINT '###################################';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT 'Error Line   : ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT '###################################';
    END CATCH;
END;




