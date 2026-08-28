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
