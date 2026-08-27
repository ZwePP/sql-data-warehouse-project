-- Checking duplicates and null of primary key
SELECT prd_id, COUNT(*) FROM silver.crm_prd_info
GROUP BY prd_id HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- check whitespaces
SELECT prd_nm FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)


-- check for negative or null numbrs
SELECT prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- product line
SELECT DISTINCT prd_line FROM silver.crm_prd_info;


-- Check for invalid date orders: End date must not be earlier than start date
SELECT * FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- select all
SELECT * FROM silver.crm_prd_info
