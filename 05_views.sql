/*===============================================================================
  PROJECT : Healthcare Supply Chain & Drug Access Analytics
  SCRIPT  : 05_views.sql
  PURPOSE : Create reusable views for Power BI dashboards and analysis. 
            These views combine cleaned data into ready-to-use datasets for reporting and
            visualization.
  AUTHOR  : Ann Kariuki  (github.com/annk-analytics)
  ENGINE  : Microsoft SQL Server (SSMS)
  DATABASE: PortfolioProject

  VIEWS IN THIS SCRIPT
    1. vw_high_utilization_drug_shortages
         Highly used drugs that have active shortage.
    2. vw_therapeutic_shortage_risk
         Therapeautic categories with frequent shortages.
    3. vw_medicare_utilization_consistency
         Confirming use and spending across both Medicare datasets.
    4. vw_state_drug_spending
         State-level spending for only U.S. states.
    5. vw_high_utilization_opioids
         Opioid use and spending at the national level.

  NOTE
    - The FDA and Medicare tables name drugs differently, so they are linked by
      matching on the first word of the drug name.
   
===============================================================================*/


/*-------------------------------------------------------------------------------
VIEW 1 | vw_high_utilization_drug_shortages
Combines FDA shortages with Medicare data to identify medications
with both high utilization and active shortages.
-------------------------------------------------------------------------------*/
CREATE VIEW vw_high_utilization_drug_shortages AS

WITH medicare_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT)) AS total_medicare_claims,
        ROUND(SUM(Tot_Drug_Cst), 2) AS total_medicare_cost
    FROM PortfolioProject..Medicare_Geo_Drug_stagging
    WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
    GROUP BY Gnrc_Name
),

fda_summary AS (
    SELECT
        Generic_Name,
        Primary_Therapeutic_Category,
        COUNT(*) AS shortage_records
    FROM PortfolioProject..shortages_FDA_stagging
    WHERE Status = 'CURRENT'
    GROUP BY
        Generic_Name,
        Primary_Therapeutic_Category
)

SELECT
    f.Generic_Name AS fda_drug_name,
    m.Gnrc_Name AS medicare_drug_name,

    f.Primary_Therapeutic_Category AS Therapeutic_Category,

    m.total_medicare_claims,
    m.total_medicare_cost,

    f.shortage_records

FROM fda_summary f
INNER JOIN medicare_summary m
    ON m.Gnrc_Name LIKE
       LEFT(
           f.Generic_Name,
           CHARINDEX(' ', f.Generic_Name + ' ') - 1
       ) + '%'

WHERE m.total_medicare_claims > 100000;


/*-------------------------------------------------------------------------------
VIEW 2 | vw_therapeutic_shortage_risk
Summarizes shortage activity, utilization, and spending across therapeutic categories.
-------------------------------------------------------------------------------*/
CREATE VIEW vw_therapeutic_shortage_risk AS

WITH medicare_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT)) AS total_medicare_claims,
        ROUND(SUM(Tot_Drug_Cst), 2) AS total_medicare_cost
    FROM PortfolioProject..Medicare_Geo_Drug_stagging
    WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
    GROUP BY Gnrc_Name
),

fda_summary AS (
    SELECT
        Generic_Name,
        Primary_Therapeutic_Category,
        COUNT(*) AS shortage_records
    FROM PortfolioProject..shortages_FDA_stagging
    WHERE Status = 'CURRENT'
    GROUP BY
        Generic_Name,
        Primary_Therapeutic_Category
)

SELECT
    f.Primary_Therapeutic_Category AS Therapeutic_Category,
    COUNT(DISTINCT f.Generic_Name) AS drugs_in_shortage,
    SUM(m.total_medicare_claims) AS total_claims,
    SUM(m.total_medicare_cost) AS total_drug_cost,
    SUM(f.shortage_records) AS shortage_records

FROM fda_summary f
INNER JOIN medicare_summary m
    ON m.Gnrc_Name LIKE
       LEFT(
           f.Generic_Name,
           CHARINDEX(' ', f.Generic_Name + ' ') - 1
       ) + '%'

WHERE m.total_medicare_claims > 100000

GROUP BY
    f.Primary_Therapeutic_Category;


/*-------------------------------------------------------------------------------
VIEW 3 | vw_medicare_utilization_consistency
Compares two Medicare datasets to confirm similar patterns in
utilization and spending.
-------------------------------------------------------------------------------*/
CREATE VIEW vw_medicare_utilization_consistency AS
WITH geo_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT))        AS geo_total_claims,
        SUM(Tot_Drug_Cst)                    AS geo_total_drug_cost,
        SUM(CAST(COALESCE(Tot_Benes, 0)
            AS BIGINT))                      AS total_beneficiaries
    FROM PortfolioProject..Medicare_Geo_Drug_stagging
    WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
    GROUP BY Gnrc_Name
),
medicare_utilization_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT))        AS utilization_total_claims,
        ROUND(SUM(Tot_Spndng), 2)            AS utilization_total_spending
    FROM PortfolioProject..Medicare_DrugUtilization_Final_v2
    GROUP BY Gnrc_Name
)
SELECT
    g.Gnrc_Name                AS drug_name,
    g.geo_total_claims,
    g.geo_total_drug_cost,
    g.total_beneficiaries,
    u.utilization_total_claims,
    u.utilization_total_spending
FROM geo_summary g
INNER JOIN medicare_utilization_summary u
    ON g.Gnrc_Name = u.Gnrc_Name
WHERE g.geo_total_claims > 100000;


/*-------------------------------------------------------------------------------
  VIEW 4 | vw_state_drug_spending
  State-level claims, spending, and beneficiaries.Regions and
  territories outside the U.S are excluded.
-------------------------------------------------------------------------------*/
CREATE VIEW vw_state_drug_spending AS
SELECT
    Prscrbr_Geo_Desc AS state,
    SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
    ROUND(SUM(Tot_Drug_Cst),2) AS total_drug_cost,
    SUM(CAST(COALESCE(Tot_Benes,0) AS BIGINT)) AS total_beneficiaries
FROM PortfolioProject..Medicare_Geo_Drug_stagging
WHERE Prscrbr_Geo_Lvl = 'STATE'
AND Prscrbr_Geo_Desc NOT IN (
    'UNKNOWN',
    'FOREIGN COUNTRY',
    'ARMED FORCES EUROPE',
    'ARMED FORCES PACIFIC',
    'ARMED FORCES CENTRAL/SOUTH AMERICA',
    'VIRGIN ISLANDS',
    'GUAM',
    'NORTHERN MARIANA ISLANDS',
    'AMERICAN SAMOA'
)
GROUP BY 
    Prscrbr_Geo_Desc;


/*-------------------------------------------------------------------------------
VIEW 5 | vw_high_utilization_opioids
Summarizes opioid claims, spending, and beneficiary counts
at the national level.
-------------------------------------------------------------------------------*/
CREATE VIEW vw_high_utilization_opioids AS

SELECT
     Gnrc_Name AS drug_name,
     SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
     ROUND(SUM(Tot_Drug_Cst),2) AS total_drug_cost,
     SUM(Tot_Benes) AS total_beneficiaries
    
FROM PortfolioProject..Medicare_Geo_Drug_stagging
WHERE Opioid_Drug_Flag = 1
AND Prscrbr_Geo_Lvl = 'NATIONAL'
GROUP BY Gnrc_Name;


/*===============================================================================
 END OF SCRIPT
 These five views provide reusable datasets Power BI dashboard pages:
    - Executive Summary
    - Drug Shortage Risk Analysis
    - Geographic Exposure & Spending
===============================================================================*/
