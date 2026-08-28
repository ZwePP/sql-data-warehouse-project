-- Identify out-of-ranges dates
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
OR bdate > NOW();

-- data standardization & consistency
SELECT DISTINCT gen
FROM silver.erp_cust_az12;

-- OVERALL CHECK
SELECT * FROM silver.erp_cust_az12;
