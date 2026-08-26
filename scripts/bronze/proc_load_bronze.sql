/*
Stored Procedure: Load Bronze Layer (Source -> Bronze)
Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions:
    - Truncates the bronze table before loading data.
    - Uses the `BULK INSERT` command to load data from csv files to bronze tables.

Usage Example: 
  CALL bronze.load_bronze();
*/



-- FREQUENTLY USED SQL QUERY / Procedure --
CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$

DECLARE
		start_time TIMESTAMPTZ;
		end_time TIMESTAMPTZ;
		batch_start_time TIMESTAMPTZ;
		batch_end_time TIMESTAMPTZ;

BEGIN
	batch_start_time := clock_timestamp();
	RAISE NOTICE '====================================';
	RAISE NOTICE 'Loading Bronze Layer';
	RAISE NOTICE '====================================';

	RAISE NOTICE '------------------------------------';
	RAISE NOTICE 'Loading CRM Tables';
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Locking Table: bronze.crm_cust_info';
	LOCK TABLE bronze.crm_cust_info IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
	TRUNCATE TABLE bronze.crm_cust_info;
	RAISE NOTICE '>> Inserting Table: bronze.crm_cust_info';
	COPY bronze.crm_cust_info FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Locking Table: bronze.crm_prd_info';
	LOCK TABLE bronze.crm_prd_info IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
	TRUNCATE TABLE bronze.crm_prd_info;
	RAISE NOTICE '>> Inserting Table: bronze.crm_prd_info';
	COPY bronze.crm_prd_info FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';


	start_time := clock_timestamp();
	RAISE NOTICE '>> Locking Table: bronze.crm_sales_details';
	LOCK TABLE bronze.crm_sales_details IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';
	TRUNCATE TABLE bronze.crm_sales_details;
	RAISE NOTICE '>> Inserting Table: bronze.crm_sales_details';
	COPY bronze.crm_sales_details FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	RAISE NOTICE '------------------------------------';
	RAISE NOTICE 'Loading ERP Tables';
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Locking Table: bronze.erp_cust_az12';
	LOCK TABLE bronze.erp_cust_az12 IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';
	TRUNCATE TABLE bronze.erp_cust_az12;
	RAISE NOTICE '>> Inserting Table: bronze.erp_cust_az12';
	COPY bronze.erp_cust_az12 FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Locking Table: bronze.erp_loc_a101';
	LOCK TABLE bronze.erp_loc_a101 IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';
	TRUNCATE TABLE bronze.erp_loc_a101;
	RAISE NOTICE '>> Inserting Table: bronze.bronze.erp_loc_a101';
	COPY bronze.erp_loc_a101 FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();	
	RAISE NOTICE '>> Locking Table: erp_px_cat_g1v2';
	LOCK TABLE bronze.erp_px_cat_g1v2 IN EXCLUSIVE MODE;
	RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
	COPY bronze.erp_px_cat_g1v2 FROM 'D:\2025GRIND\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
	DELIMITER ',' CSV HEADER;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';
	
	
	
	batch_end_time := clock_timestamp();
	RAISE NOTICE '>> Total Duration: % ms', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time))* 1000;
	RAISE NOTICE '------------------------------------';
	
	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		RAISE NOTICE 'ERROR MESSAGE: %', SQLERRM; 
END;
$$
