/*
Script purpose:
This script creates a new database names 'DataWarehouse'.
And, sets up 3 schemas within the database: 'bronze', 'silver', and 'gold'.
*/

-- Creating Database
CREATE DATABASE DataWarehouse

-- Creating Schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
