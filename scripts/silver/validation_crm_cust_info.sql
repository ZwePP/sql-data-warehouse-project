-- Check for nulls or duplicates in Primary Key
-- Expectation: No result
SELECT cst_id, COUNT(*) FROM silver.crm_cust_info
GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- CHECK FOR UNWATED SPACES
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info;

