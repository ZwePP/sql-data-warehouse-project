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
