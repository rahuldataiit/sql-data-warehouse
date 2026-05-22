/*
===============================================================================
 Script Name : 01_create_database_and_schemas.sql
 Purpose     : This script creates the DataWarehouse database and sets up the
               initial schema structure for the Medallion Architecture.

 Description :
               The database is organized into three layers:

               1. bronze - Stores raw data loaded directly from source systems.
               2. silver - Stores cleaned, standardized, and transformed data.
               3. gold   - Stores business-ready data for reporting and analytics.

 Usage       : Run this script first before creating tables or loading data.
===============================================================================
*/

-- Create the DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

-- Switch context to the DataWarehouse database
USE DataWarehouse;
GO

-- Create schema for raw/source data
CREATE SCHEMA bronze;
GO

-- Create schema for cleaned/transformed data
CREATE SCHEMA silver;
GO

-- Create schema for analytics/reporting data
CREATE SCHEMA gold;
GO
