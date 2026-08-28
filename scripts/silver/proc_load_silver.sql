-- ===============================================================================
-- Stored Procedure: silver.load_silver
-- Description: 
--     Executes the full ETL pipeline to populate the Silver Layer (Data Warehouse)
--     from the raw Bronze Layer sources (CRM and ERP systems).
--
-- Actions Performed:
--     1. Truncates all target tables in the 'silver' schema.
--     2. Applies data transformation, normalization, and cleansing rules:
--        - crm_cust_info   : Deduplicates customer records using ROW_NUMBER() and standardizes genders/marital statuses.
--        - crm_prd_info    : Extracts category IDs, standardizes product lines, and derives historical end dates using LEAD().
--        - crm_sales_details: Standardizes YYYYMMDD integers to DATE types and recalculates missing/invalid sales & unit prices.
--        - erp_cust_az12   : Strips 'NAS' prefixes from customer IDs, sets future birth dates to NULL, standardizes gender codes.
--        - erp_loc_a101    : Cleans hyphens/spaces from customer keys and maps country abbreviations (DE, US) to full names.
--        - erp_px_cat_g1v2 : Loads raw product category mappings.
--     3. Logs execution metrics (individual table load durations and total batch time).
--     4. Includes basic PL/pgSQL exception handling for graceful error logging.
--
-- Parameters: None
-- Usage: CALL silver.load_silver();
-- ===============================================================================

CREATE OR REPLACE PROCEDURE silver.load_silver()
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
	RAISE NOTICE 'Loading Silver Layer';
	RAISE NOTICE '====================================';

	RAISE NOTICE '------------------------------------';
	RAISE NOTICE 'Loading CRM Tables';
	RAISE NOTICE '------------------------------------';
	
	-- Truncate silver.crm_cust_info
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info (Full Load)';
	INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
	SELECT 
		cst_id, 
		cst_key, 
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE 
			WHEN UPPER(TRIM(cst_martial)) = 'M' THEN 'Married'
			WHEN UPPER(TRIM(cst_martial)) = 'S' THEN 'Single'
			ELSE 'n/a'
		END AS cst_marital_status,
		CASE 
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END AS cst_gndr,
		cst_create_date
		FROM(
			SELECT *, ROW_NUMBER() 
			OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC)
			AS flag_last FROM bronze.crm_cust_info) subq
		WHERE flag_last = 1;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	-- Truncate silver.crm_prd_info
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info (Full Load)';
	INSERT INTO silver.crm_prd_info (
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
		SUBSTRING(prd_key,7, LENGTH(prd_key)) AS prd_key,
		prd_nm,
		COALESCE(prd_cost, 0) AS prd_cost,
		CASE TRIM(UPPER(prd_line))  
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
			ELSE'N/A'
		END AS prd_line,
		prd_start_dt,
		LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt
	FROM bronze.crm_prd_info;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	-- Truncate crm_sales_details
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details (Full Load)';
	INSERT INTO silver.crm_sales_details(
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
		CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		
		CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		
		CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,
		
		CASE WHEN sls_sales IS NULL 
			OR sls_sales <= 0 
			OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
		
		sls_quantity,
		
		CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price -- Derive price if original value is invalid
		END AS sls_price
		
	FROM bronze.crm_sales_details;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';


	RAISE NOTICE '------------------------------------';
	RAISE NOTICE 'Loading ERP Tables';
	RAISE NOTICE '------------------------------------';
	-- Truncate erp_cust_az12
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12 (Full Load)';	
	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen
	)
	SELECT
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid)) 
		ELSE cid
	END AS cid,
	
	CASE 
		WHEN bdate > NOW() THEN NULL
		ELSE bdate
	END AS bdate,
	
	CASE 
		WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
	FROM bronze.erp_cust_az12;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	-- Truncate erp_loc_a101
	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101 (Full Load)';	
	INSERT INTO silver.erp_loc_a101(
	cid,
	cntry
	)
	SELECT DISTINCT
		CASE
			WHEN LENGTH(TRIM(cid)) != 10 THEN REPLACE(TRIM(cid), '-','')
			ELSE TRIM(cid)
		END AS cid,
		CASE 
			WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
			WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
			WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry
	FROM bronze.erp_loc_a101;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2 (Full Load)';	
	INSERT INTO silver.erp_px_cat_g1v2(
		px_id,
		cat,
		subcat,
		maintenance
	)
	SELECT
		px_id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;
	end_time := clock_timestamp();
	RAISE NOTICE '>> Load Duration: % ms', EXTRACT(EPOCH FROM (end_time - start_time))* 1000;
	RAISE NOTICE '------------------------------------';
	batch_end_time := clock_timestamp();
	RAISE NOTICE '>> Total Duration: % ms', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time))* 1000;
	RAISE NOTICE '------------------------------------';

	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE 'ERROR OCCURED DURING LOADING SILVER LAYER';
		RAISE NOTICE 'ERROR MESSAGE: %', SQLERRM;
		
END;
$$



		
