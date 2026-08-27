-- Data transformation
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


		
