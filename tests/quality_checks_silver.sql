-- ============================================================================
-- DATA QUALITY ASSURANCE SUITE: SILVER LAYER
-- Description: Unit and data quality tests for cleansed CRM and ERP tables.
-- Expectations: All validation queries should return 0 rows unless noted.
-- ============================================================================

-- ============================================================================
-- 1. Table: silver.crm_cust_info
-- ============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No results
SELECT 
    cst_id, 
    COUNT(*) AS duplicate_count 
FROM silver.crm_cust_info
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for Unwanted Spaces in Text Columns
-- Expectation: No results
SELECT 
    cst_id,
    cst_firstname,
    cst_lastname,
    cst_gndr
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname  != TRIM(cst_lastname)
   OR cst_gndr      != TRIM(cst_gndr);

-- Data Standardization & Consistency Check
-- Expectation: Inspect distinct values (e.g., 'Male', 'Female', 'n/a')
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;


-- ============================================================================
-- 2. Table: silver.crm_prd_info
-- ============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No results
SELECT 
    prd_id, 
    COUNT(*) AS duplicate_count 
FROM silver.crm_prd_info
GROUP BY prd_id 
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for Unwanted Spaces in Product Name
-- Expectation: No results
SELECT prd_id, prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for Invalid, Negative, or NULL Costs
-- Expectation: No results
SELECT prd_id, prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check Date Logic Integrity (Start Date > End Date)
-- Expectation: No results
SELECT * 
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- Data Standardization & Consistency Check
-- Expectation: Inspect distinct product categories
SELECT DISTINCT prd_line FROM silver.crm_prd_info;


-- ============================================================================
-- 3. Table: silver.crm_sales_details
-- ============================================================================

-- Check for Raw Date Formatting Errors (Bronze Source Verification)
-- Expectation: No results
SELECT sls_ord_num, sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
   OR LENGTH(sls_order_dt::VARCHAR) != 8;

-- Check Date Chronology (Order Date vs Ship/Due Date)
-- Expectation: No results
SELECT * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Financial Math & Value Validity
-- Expectation: No results
SELECT DISTINCT
    sls_ord_num,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != (sls_quantity * sls_price)
   OR sls_sales IS NULL    OR sls_quantity IS NULL    OR sls_price IS NULL
   OR sls_sales <= 0       OR sls_quantity <= 0       OR sls_price <= 0;


-- ============================================================================
-- 4. Table: silver.erp_cust_az12
-- ============================================================================

-- Identify Out-of-Range or Future Birth Dates
-- Expectation: No results
SELECT cid, bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CURRENT_DATE;

-- Data Standardization & Consistency Check
-- Expectation: Inspect distinct gender values
SELECT DISTINCT gen FROM silver.erp_cust_az12;


-- ============================================================================
-- 5. Table: silver.erp_loc_a101
-- ============================================================================

-- Data Standardization & Consistency Check
-- Expectation: Inspect distinct countries (e.g., 'Germany', 'United States')
SELECT DISTINCT cntry FROM silver.erp_loc_a101;
