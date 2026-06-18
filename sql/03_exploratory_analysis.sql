/*===============================================================================
  PROJECT : Healthcare Supply Chain & Drug Access Analytics
  SCRIPT  : 03_exploratory_analysis.sql
  PURPOSE : Explore the cleaned FDA shortage and Medicare drug utilization to identify
            patterns in drug shortages, utilization, spending, and access.
  AUTHOR  : Ann Kariuki  (github.com/annk-analytics)
  DATABASE: PortfolioProject

  OVERVIEW
  This script answers business questions across two areas:

   PART A - FDA Drug Shortages
   Which categories, manufacturers, and drugs are most affected, how
   shortages have changed over time, and which dosage forms are hit the most.

   PART B - Medicare Utilization & Spending
   Which drugs are used and cost the most, where spending is concentrated
   geographically, and how specific drug compare

  Each query is followed by an explanation of the finding.
===============================================================================*/


/*###############################################################################
  PART A | FDA DRUG SHORTAGES
###############################################################################*/

/*-------------------------------------------------------------------------------
  A1 | Which therapeutic categories have the most shortages?
-------------------------------------------------------------------------------*/
SELECT
 Therapeutic_Category,
 COUNT(*) as total_shortages
FROM dbo.shortages_FDA_stagging
GROUP BY Therapeutic_Category
ORDER BY total_shortages DESC;
-- Shortages are concentrated in critical categories: psychiatry, anesthesia,
-- and cardiovascular highlighting potential risk to patient access and 
--treatment continuity in mental and critical care.


/*-------------------------------------------------------------------------------
  A2 | Which manufacturers have the most shortages?
-------------------------------------------------------------------------------*/
SELECT
  Company_Name,
  COUNT(*) AS total_shortages
FROM dbo.shortages_FDA_stagging
GROUP BY Company_Name
ORDER BY total_shortages DESC;
-- Shortages are concentrated among a few manufacturers, suggesting supplier
-- dependency on a limited supplier base.


/*-------------------------------------------------------------------------------
  A3 | How have shortages changed over time?
-------------------------------------------------------------------------------*/
SELECT
  YEAR(Initial_Posting_Date) AS shortage_year,
  COUNT(*) AS total_shortages
FROM dbo.shortages_FDA_stagging
GROUP BY YEAR (Initial_Posting_Date)
ORDER BY shortage_year;
-- Shortages rise and fall over the years, with recent years having a spike
--suggesting increased supply chain instability and pressure.


/*-------------------------------------------------------------------------------
  A4 | What is the shortage status breakdown?
-------------------------------------------------------------------------------*/
SELECT
  Status,
  COUNT(*) AS total
FROM dbo.shortages_FDA_stagging
GROUP BY Status
ORDER BY total DESC;
-- Most drug shortages remained current with only a small portion resolved 
--showing persistence in supply disruptions and patient access risk.


/*-------------------------------------------------------------------------------
  A5 | Which drugs have the most recurring shortages?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Generic_Name,
  COUNT(*) AS total_shortage
FROM DBO.shortages_FDA_stagging
GROUP BY Generic_Name
 ORDER BY total_shortage DESC;
-- Recurring shortages are common among high-demand drugs including psychiatric,
--anesthesia,and injectable drugs.Indicating ongoing risk in critical care areas.


/*-------------------------------------------------------------------------------
  A6 | Which dosage forms are most affected?
-------------------------------------------------------------------------------*/
SELECT
   CASE
       WHEN Presentation LIKE '%Injection%' THEN 'Injection'
       WHEN Presentation LIKE '%Tablet%' THEN 'Tablet'
       WHEN Presentation LIKE '%Capsule%' THEN 'Capsule'
       WHEN Presentation LIKE '%Solution%' THEN 'Solution'
       ELSE 'Other'
    END AS dosage_form,
    COUNT(*) AS total_shortages
FROM dbo.shortages_FDA_stagging
GROUP BY
   CASE
        WHEN Presentation LIKE '%Injection%' THEN 'Injection'
        WHEN Presentation LIKE '%Tablet%' THEN 'Tablet'
        WHEN Presentation LIKE '%Capsule%' THEN 'Capsule'
        WHEN Presentation LIKE '%Solution%' THEN 'Solution'
        ELSE 'Other'
    END
ORDER BY total_shortages DESC;
-- Injectable drugs account to most shortages, pointing to manufacturing
-- vulnerability and higher costs for critical hospital medications.


/*###############################################################################
  PART B | MEDICARE UTILIZATION & SPENDING
###############################################################################*/

/*-------------------------------------------------------------------------------
  B1 | Which drugs have the highest utilization ?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Gnrc_Name,
  SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims
FROM DBO.Medicare_Geo_Drug_stagging
    GROUP BY Gnrc_Name
    ORDER BY total_claims DESC;
-- Cardiovascular and metabolic drugs show the highest use,reflecting a steady
-- nationwide demand and high exposure to shortages.


/*-------------------------------------------------------------------------------
  B2 | Which drugs contribute the most to Medicare spending?
-------------------------------------------------------------------------------*/
SELECT TOP 10
   Gnrc_Name,
   SUM(Tot_Drug_Cst) AS total_drug_cost
FROM DBO.Medicare_Geo_Drug_stagging
    GROUP BY Gnrc_Name
    ORDER BY total_drug_cost DESC;
-- Spending is concentrated in a few therapeutic areas including diabetes, 
--cardiovascular, autoimmune, and specialty drugs shortages could have 
--significant impact on financial and patient access.


/*-------------------------------------------------------------------------------
  B3 | Which drugs have the highest cost per beneficiary?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Gnrc_Name,
  SUM(Tot_Drug_Cst) / SUM(Tot_Benes) AS cost_per_beneficiary
FROM DBO.Medicare_Geo_Drug_stagging
WHERE Tot_Benes > 0
AND Prscrbr_Geo_Lvl = 'National'
   GROUP BY Gnrc_Name
   ORDER BY cost_per_beneficiary DESC;
-- The highest cost-per-patient drugs are rare disease and specialty therapies:
-- Financial burden is concentrated among a few high cost drugs despite serving 
--a small number of patients.


/*-------------------------------------------------------------------------------
  B4 | Are the most used drugs also the most expensive?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Gnrc_Name,
  SUM(CAST(Tot_Clms AS BIGINT))  AS total_claims,
  SUM(Tot_Drug_Cst) AS total_drug_cost
FROM DBO.Medicare_Geo_Drug_stagging
WHERE Prscrbr_Geo_Lvl = 'National'
  GROUP BY Gnrc_Name
  ORDER BY total_drug_cost DESC;
-- High Medicare spending comes from both widely used chronic medications and 
--high-cost speciality drugs.


/*-------------------------------------------------------------------------------
  B5 | Which states have the highest utilization and spending?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Prscrbr_Geo_Desc AS state,
  SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
  SUM (Tot_Drug_Cst) AS total_drug_cost
FROM Medicare_Geo_Drug_stagging
WHERE Prscrbr_Geo_Lvl = 'State'
   GROUP BY Prscrbr_Geo_Desc
   ORDER BY total_drug_cost DESC;
-- Spending is concentrated in large population states
--California, New York, Florida, and Texas 
--reflecting where healthcare demand and cost are highest.


/*-------------------------------------------------------------------------------
  B6 | Which opioids have the highest utilization and spending?
-------------------------------------------------------------------------------*/
SELECT TOP 10
  Gnrc_Name,
  SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
  ROUND(SUM(Tot_Drug_Cst),2) AS total_drug_cost
FROM DBO.Medicare_Geo_Drug_stagging
where Opioid_Drug_Flag = 1
AND Prscrbr_Geo_Lvl = 'National'
   GROUP BY Gnrc_Name
   ORDER BY total_claims DESC;
-- Hydrocodone, tramadol, and oxycodone show high utilization
--showing high demand and cost in pain management therapies.


/*-------------------------------------------------------------------------------
  B7 | Which antibiotics have the highest utilization and spending?
-------------------------------------------------------------------------------*/
 SELECT TOP 10
   Gnrc_Name,
   SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
   ROUND(SUM(Tot_Drug_Cst),2) AS total_drug_cost
FROM Medicare_Geo_Drug_stagging
WHERE Antbtc_Drug_Flag = 1
AND Prscrbr_Geo_Lvl ='National'
   GROUP BY Gnrc_Name
   ORDER BY total_claims DESC;
-- Amoxicillin, azithromycin, and cephalexin lead the most common outpatient
-- antibiotics, reflecting broad demand across the country.


/*-------------------------------------------------------------------------------
  B8 | Which antipsychotics have the highest utilization and spending?
-------------------------------------------------------------------------------*/
SELECT TOP 10
Gnrc_Name,
SUM(CAST(Tot_Clms AS BIGINT)) AS total_claims,
ROUND(SUM(Tot_Drug_Cst),2) AS total_drug_cost
FROM dbo.Medicare_Geo_Drug_stagging
WHERE Antpsyct_Drug_Flag = 1
AND Prscrbr_Geo_Lvl = 'National'
   GROUP BY Gnrc_Name
   ORDER BY total_claims DESC;
-- a small number of antipsychotic drugs;quetiapine, aripiprazole, and risperidone 
--account for the most utilization showing strong demand for mental health treatment.


/*-------------------------------------------------------------------------------
  B9 | Which drugs are used most by seniors (65+)?
-------------------------------------------------------------------------------*/
SELECT TOP 10
Gnrc_Name,
SUM(CAST(GE65_Tot_Clms AS BIGINT)) AS ge65_total_claims,
(SUM(GE65_Tot_Drug_Cst)) AS ge65_total_cost
FROM dbo.Medicare_Geo_Drug_stagging
WHERE Prscrbr_Geo_Lvl = 'National'
    GROUP BY Gnrc_Name
    ORDER BY ge65_total_claims DESC;
--Chronic-condition maintenance drugs account to the most drug used by seniors
--Reflecting long-term medication demand among those 65 and older.


/*===============================================================================
  END OF SCRIPT
  NEXT STEP : 04_integrated_joins.sql
===============================================================================*/
