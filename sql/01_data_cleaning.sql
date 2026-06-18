/*===============================================================================
PROJECT : Healthcare Supply Chain & Drug Access Analytics
SCRIPT  : 01_data_cleaning.sql
PURPOSE : Prepare the FDA drug shortage and CMS Medicare Part D data for
          analysis by staging, cleaning, checking, and removing duplicates.
AUTHOR  : Ann Kariuki  (github.com/annk-analytics)
ENGINE  : Microsoft SQL Server (SSMS)
DATABASE: PortfolioProject

PROJECT OBJECTIVE
To identify high-utilization drugs affected by FDA shortages and measure their impact 
on Medicare spending and patient access, and reveal where drug supply 
risk is most concentrated across the United States.

BUSINESS CONTEXT
Drug shortages can disrupt patient access to essential medications and increase
healthcare system vulnerability.This project integrates FDA shortage data 
with Medicare utilization data to identify drugs with both high demand and 
shortage risk, helping stakeholders understand potential impacts on patients,
spending, and healthcare access.

DATASETS
- Shortages_FDA      : FDA drug shortage records (~1,600 rows)
- Medicare_Geo_Drug  : CMS Medicare Part D drug utilization by geographic area 
                       (~116,000 rows)

DATA SOURCES
- FDA Drug Shortages  : fda.gov drug shortage database
- Medicare Part D Prescriber public use file (CMS) : data.cms.gov

WHAT THIS SCRIPT DOES
1. Explores at the raw datasets and validate row counts
2. Checks for missing values and blanks
3. Explores join keys accross the datasets
4. Creates staging copies (preserve raw data)
5. Standardize text formatting
6. Validate cleaned data quality
7. Finds and removes duplicate rows
8. Checks dates and numbers look correct

WHY STAGING TABLES
All cleaning is done on the *_stagging copies. The original raw tables remain unchanged
,so the whole process can be repeated from scratch at any time.
===============================================================================*/
/*-------------------------------------------------------------------------------
STEP 1 | DATA EXPLORATION AND ROW VALIDATION
Preview the datasets and validate record count before data cleaning
-------------------------------------------------------------------------------*/

SELECT TOP 10 * FROM PortfolioProject..Shortages_FDA;
SELECT TOP 10 * FROM PortfolioProject..Medicare_Geo_Drug;

SELECT COUNT(*) AS fda_row_count      FROM PortfolioProject..Shortages_FDA;
SELECT COUNT(*) AS medicare_row_count FROM PortfolioProject..Medicare_Geo_Drug;

/*-------------------------------------------------------------------------------
STEP 2 | CHECK FOR MISSING VALUES
Count missing values on important columns of each table to identify data quality 
issues before cleaning
-------------------------------------------------------------------------------*/

-- FDA shortages: missing values by column
SELECT
    COUNT(*)                                                          AS total_rows,
    SUM(CASE WHEN Generic_Name          IS NULL THEN 1 ELSE 0 END)    AS null_generic_name,
    SUM(CASE WHEN Company_Name          IS NULL THEN 1 ELSE 0 END)    AS null_company_name,
    SUM(CASE WHEN Therapeutic_Category  IS NULL THEN 1 ELSE 0 END)    AS null_therapeutic_category,
    SUM(CASE WHEN Reason_for_Shortage   IS NULL THEN 1 ELSE 0 END)    AS null_reason_for_shortage,
    SUM(CASE WHEN Status                IS NULL THEN 1 ELSE 0 END)    AS null_status,
    SUM(CASE WHEN Change_Date           IS NULL THEN 1 ELSE 0 END)    AS null_change_date,
    SUM(CASE WHEN Date_Discontinued     IS NULL THEN 1 ELSE 0 END)    AS null_date_discontinued,
    SUM(CASE WHEN Initial_Posting_Date  IS NULL THEN 1 ELSE 0 END)    AS null_initial_posting_date
FROM PortfolioProject..Shortages_FDA;

-- Medicare Geo-Drug: missing values by column
SELECT
    COUNT(*)                                                          AS total_rows,
    SUM(CASE WHEN Gnrc_Name             IS NULL THEN 1 ELSE 0 END)    AS null_gnrc_name,
    SUM(CASE WHEN Brnd_Name             IS NULL THEN 1 ELSE 0 END)    AS null_brnd_name,
    SUM(CASE WHEN Prscrbr_Geo_Lvl       IS NULL THEN 1 ELSE 0 END)    AS null_geo_level,
    SUM(CASE WHEN Prscrbr_Geo_Cd        IS NULL THEN 1 ELSE 0 END)    AS null_geo_code,
    SUM(CASE WHEN Prscrbr_Geo_Desc      IS NULL THEN 1 ELSE 0 END)    AS null_geo_description,
    SUM(CASE WHEN Tot_Clms              IS NULL THEN 1 ELSE 0 END)    AS null_total_claims,
    SUM(CASE WHEN Tot_30day_Fills       IS NULL THEN 1 ELSE 0 END)    AS null_total_30day_fills,
    SUM(CASE WHEN Tot_Drug_Cst          IS NULL THEN 1 ELSE 0 END)    AS null_total_drug_cost,
    SUM(CASE WHEN Tot_Benes             IS NULL THEN 1 ELSE 0 END)    AS null_total_beneficiaries,
    SUM(CASE WHEN GE65_Tot_Clms         IS NULL THEN 1 ELSE 0 END)    AS null_ge65_total_claims,
    SUM(CASE WHEN GE65_Tot_Benes        IS NULL THEN 1 ELSE 0 END)    AS null_ge65_total_beneficiaries,
    SUM(CASE WHEN Opioid_Drug_Flag      IS NULL THEN 1 ELSE 0 END)    AS null_opioid_flag,
    SUM(CASE WHEN Antbtc_Drug_Flag      IS NULL THEN 1 ELSE 0 END)    AS null_antibiotic_flag,
    SUM(CASE WHEN Antpsyct_Drug_Flag    IS NULL THEN 1 ELSE 0 END)    AS null_antipsychotic_flag
FROM PortfolioProject..Medicare_Geo_Drug;

/*-------------------------------------------------------------------------------
STEP 3 | CHECK BLANKS AND EXPLORE THE JOIN COLUMNS
Identify empty text values and evaluate unique join keys to link the tables.
This confirms drug column name can be used to link FDA and Medicare datasets.
-------------------------------------------------------------------------------*/

-- Check for blank drug names in the FDA table
SELECT COUNT(*) AS blank_generic_name
FROM PortfolioProject..Shortages_FDA
WHERE Generic_Name = '';

-- Count unique drug names in the FDA table
SELECT COUNT(DISTINCT Generic_Name) AS unique_fda_drugs
FROM PortfolioProject..Shortages_FDA;

-- Count unique drug names in the Medicare table
SELECT COUNT(DISTINCT Gnrc_Name) AS unique_medicare_drugs
FROM PortfolioProject..Medicare_Geo_Drug;

/*-------------------------------------------------------------------------------
STEP 4 | CREATE STAGING TABLES
Creating staging copies to perform the cleaning to preserve raw data integrity.
-------------------------------------------------------------------------------*/
SELECT *
INTO shortages_FDA_stagging
FROM dbo.Shortages_FDA;

SELECT *
INTO Medicare_Geo_Drug_stagging
FROM dbo.Medicare_Geo_Drug;

/*-------------------------------------------------------------------------------
  STEP 5 | STANDARDIZE TEXT FORMATING
  Make text consistent by removing extra spaces and converting it to uppercase to 
  improve join accuracy
-------------------------------------------------------------------------------*/
-- FDA shortages
UPDATE PortfolioProject..shortages_FDA_stagging
SET
    Generic_Name         = UPPER(TRIM(Generic_Name)),
    Company_Name         = UPPER(TRIM(Company_Name)),
    Therapeutic_Category = UPPER(TRIM(Therapeutic_Category)),
    Reason_for_Shortage  = UPPER(TRIM(Reason_for_Shortage)),
    Status               = UPPER(TRIM(Status));

-- Medicare Geo-Drug
UPDATE PortfolioProject..Medicare_Geo_Drug_stagging
SET
    Gnrc_Name        = UPPER(TRIM(Gnrc_Name)),
    Brnd_Name        = UPPER(TRIM(Brnd_Name)),
    Prscrbr_Geo_Lvl  = UPPER(TRIM(Prscrbr_Geo_Lvl)),
    Prscrbr_Geo_Desc = UPPER(TRIM(Prscrbr_Geo_Desc));

/*-------------------------------------------------------------------------------
  STEP 6 | VALIDATE CLEANED DATA
  Validate after cleaning to make sure there are no remaining blanks and missing values 
  in the key analytical columns.
-------------------------------------------------------------------------------*/

-- Blank checks: FDA shortages
SELECT
    SUM(CASE WHEN TRIM(Generic_Name)         = '' THEN 1 ELSE 0 END) AS blank_generic_name,
    SUM(CASE WHEN TRIM(Company_Name)         = '' THEN 1 ELSE 0 END) AS blank_company_name,
    SUM(CASE WHEN TRIM(Therapeutic_Category) = '' THEN 1 ELSE 0 END) AS blank_therapeutic_category,
    SUM(CASE WHEN TRIM(Status)               = '' THEN 1 ELSE 0 END) AS blank_status
FROM PortfolioProject..shortages_FDA_stagging;

-- Blank checks: Medicare Geo-Drug
SELECT
    SUM(CASE WHEN TRIM(Gnrc_Name)        = '' THEN 1 ELSE 0 END) AS blank_gnrc_name,
    SUM(CASE WHEN TRIM(Brnd_Name)        = '' THEN 1 ELSE 0 END) AS blank_brnd_name,
    SUM(CASE WHEN TRIM(Prscrbr_Geo_Desc) = '' THEN 1 ELSE 0 END) AS blank_geo_desc
FROM PortfolioProject..Medicare_Geo_Drug_stagging;

-- Check remaining missing values: FDA shortages
SELECT *
FROM PortfolioProject..shortages_FDA_stagging
WHERE Generic_Name         IS NULL
   OR Company_Name         IS NULL
   OR Therapeutic_Category IS NULL;

--check remaining missing values: Medicare Geo-Drug
SELECT *
FROM PortfolioProject..Medicare_Geo_Drug_stagging
WHERE Gnrc_Name       IS NULL
   OR Tot_Clms        IS NULL
   OR Tot_30day_Fills IS NULL
   OR Tot_Drug_Cst    IS NULL;

/*-------------------------------------------------------------------------------
  STEP 7 | FIND AND REMOVE DUPLICATE ROWS
  Identify duplicate rows then keep one copy and delete the extras using window functions 
-------------------------------------------------------------------------------*/

-- 7a. FDA shortages: preview groups that appears more than once
SELECT
    Generic_Name,
    Company_Name,
    Therapeutic_Category,
    Status,
    Initial_Posting_Date,
    COUNT(*) AS duplicate_count
FROM PortfolioProject..shortages_FDA_stagging
GROUP BY
    Generic_Name,
    Company_Name,
    Therapeutic_Category,
    Status,
    Initial_Posting_Date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 7b. FDA shortages: number the repeated rows so duplicates can be seen
WITH CTE_shortages_fda AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                Generic_Name,
                Company_Name,
                Presentation,
                Therapeutic_Category,
                Status,
                Initial_Posting_Date
            ORDER BY Generic_Name
        ) AS row_num
    FROM PortfolioProject..shortages_FDA_stagging
)
SELECT *
FROM CTE_shortages_fda
WHERE row_num > 1;

-- 7c. FDA shortages: delete the duplicates, keeping the first copy
WITH CTE_shortages_fda AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                Generic_Name,
                Company_Name,
                Presentation,
                Therapeutic_Category,
                Status,
                Initial_Posting_Date
            ORDER BY Generic_Name
        ) AS row_num
    FROM PortfolioProject..shortages_FDA_stagging
)
DELETE
FROM CTE_shortages_fda
WHERE row_num > 1;

-- 7d. Medicare Geo-Drug: preview groups that appear more than once
SELECT
    Gnrc_Name,
    Brnd_Name,
    Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Cd,
    COUNT(*) AS duplicate_count
FROM PortfolioProject..Medicare_Geo_Drug_stagging
GROUP BY
    Gnrc_Name,
    Brnd_Name,
    Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Cd
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


/*-------------------------------------------------------------------------------
  STEP 8 | DATA AND NUMBERS VALIDATION
  Confirm dates pull the right year and month, and number columns are consistent. 
  Tot_Clms is converted to BIGINT so large totals aggregations without overflow.
-------------------------------------------------------------------------------*/

-- Date check: FDA shortages
SELECT TOP 10
    Initial_Posting_Date,
    YEAR(Initial_Posting_Date)  AS posting_year,
    MONTH(Initial_Posting_Date) AS posting_month
FROM PortfolioProject..shortages_FDA_stagging;

-- Number check: Medicare Geo-Drug
SELECT
    SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
    AVG(Tot_Drug_Cst)             AS avg_drug_cost,
    MAX(Tot_30day_Fills)          AS max_fills
FROM PortfolioProject..Medicare_Geo_Drug_stagging;


/*===============================================================================
END OF SCRIPT

OUTPUT
Cleaned and validated datasets ready for analysis.

Next step: 02_exploratory_analysis.sql
===============================================================================*/
