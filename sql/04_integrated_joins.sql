/*===============================================================================
  PROJECT : Healthcare Supply Chain & Drug Access Analytics
  SCRIPT  : 04_integrated_joins.sql
  PURPOSE : Combine FDA shortage data and the Medicare data to understand
            how drug shortages connect to real-world use and spending.
  AUTHOR  : Ann Kariuki  (github.com/annk-analytics)
  DATABASE: PortfolioProject

  OVERVIEW
    The FDA and Medicare tables name drugs differently, so they are linked by
    matching on the first word of the drug name. Three questions are explored:

      Join 1 - Which heavily used drugs are also in active shortage?
      Join 2 - Which therapeutic categories face the most shortage pressure?
      Join 3 - Which drugs show high use and spending across both Medicare
               datasets,to the finding confirm?

  NOTE
    The FDA data is grouped first to avoid counting the same shortage more than once.
===============================================================================*/

/*-------------------------------------------------------------------------------
  JOIN 1 | which are the highly utilized drugs with active shortages?
-------------------------------------------------------------------------------*/
WITH medicare_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT)) AS total_medicare_claims,
        ROUND(SUM(Tot_Drug_Cst),2) AS total_medicare_cost
    FROM PortfolioProject..Medicare_Geo_Drug_stagging
    WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
    GROUP BY Gnrc_Name
  ),
fda_summary AS (
   SELECT
      Generic_Name,
      Therapeutic_Category,
      COUNT(*) AS shortage_records
    FROM PortfolioProject..shortages_FDA_stagging
    WHERE Status = 'CURRENT'
    GROUP BY
        Generic_Name,
        Therapeutic_Category
)
SELECT
    f.Generic_Name AS fda_drug_name,
    m.Gnrc_Name AS medicare_drug_name,
    m.total_medicare_claims,
    m.total_medicare_cost,
    f.Therapeutic_Category,
    f.shortage_records

FROM fda_summary f
  INNER JOIN medicare_summary m
  ON m.Gnrc_Name LIKE
    LEFT(
        f.Generic_Name,
        CHARINDEX(' ', f.Generic_Name + ' ') - 1
    ) + '%'
ORDER BY m.total_medicare_claims DESC;
-- Many heavily used drugs are facing active shortages, including
-- cardiovascular, respiratory, neurological, and pain management medications.
-- - These shortages may affect patient access to medications used by
-- large populations across the country.


/*-------------------------------------------------------------------------------
  JOIN 2 | Which therapeutic categories face frequent shortages?
-------------------------------------------------------------------------------*/
WITH medicare_summary AS (
    SELECT
        Gnrc_Name,
        SUM(CAST(Tot_Clms AS BIGINT)) AS total_medicare_claims,
        ROUND(SUM(Tot_Drug_Cst),2) AS total_medicare_cost
    FROM PortfolioProject..Medicare_Geo_Drug_stagging
    WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
    GROUP BY Gnrc_Name
),
fda_summary AS (
    SELECT
        Generic_Name,
        Therapeutic_Category,
        COUNT(*) AS shortage_records
    FROM PortfolioProject..shortages_FDA_stagging
    WHERE Status = 'CURRENT'
    GROUP BY
        Generic_Name,
        Therapeutic_Category
)
SELECT
    f.Therapeutic_Category,
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
GROUP BY f.Therapeutic_Category
ORDER BY total_claims DESC;
-- Cardiovascular drugs accounts to the highest use and spending among therapies
--with shortage risk.while anesthesia and psychiatry experience frequent shortages.
-- Shortage pressure varies across categories suggesting supply chain gaps
-- that put vulnerable patients at risk.


/*-------------------------------------------------------------------------------
  JOIN 3 | Which drugs show high spending and utilization across both Medicare datasets?
         
-------------------------------------------------------------------------------*/
WITH geo_summary AS (
  SELECT 
     Gnrc_Name,
     SUM(CAST(Tot_Clms AS BIGINT)) AS geo_total_claims,
     SUM(Tot_Drug_Cst) AS geo_total_drug_cost

  FROM PortfolioProject..Medicare_Geo_Drug_stagging
  WHERE Prscrbr_Geo_Lvl = 'NATIONAL'
  GROUP BY Gnrc_Name
  ),
medicare_utilization_summmary AS (
   SELECT 
   Gnrc_Name,
   SUM(CAST(Tot_Clms AS BIGINT)) AS utilization_total_claims,
   SUM(CAST(Tot_Benes AS BIGINT)) AS total_beneficiaries,
   ROUND(SUM(Tot_Spndng),2) AS utilization_total_spending

   FROM PortfolioProject..Medicare_DrugUtilization_Final_v2
   GROUP BY Gnrc_Name
   )
   SELECT TOP 20
     g.Gnrc_Name AS drug_name,

     g.geo_total_claims,
     g.geo_total_drug_cost,

     u.utilization_total_claims,
     u.total_beneficiaries,
     u.utilization_total_spending

   FROM geo_summary g
     INNER JOIN medicare_utilization_summmary u
             ON g.Gnrc_Name = u.Gnrc_Name

    WHERE   g.geo_total_claims > 100000
    ORDER BY g.geo_total_claims DESC;
-- Chronic disease drugs leads in Medicare use with high claims and more patients
-- Drugs used to manage blood pressure, cholesterol, and heart disease
-- show high demand.
-- Millions of patients rely on these medications, highlighting the importance of 
--stable access and affordability to treatment.
-- The two Medicare datasets show similar patterns,showing reliable findings.


/*===============================================================================
  END OF SCRIPT
  NEXT STEP : 05_views.sql
===============================================================================*/
