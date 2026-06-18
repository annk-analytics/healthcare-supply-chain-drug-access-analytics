/*===============================================================================
  PROJECT : Healthcare Supply Chain & Drug Access Analytics
  SCRIPT  : 02_data_quality_fixes.sql
  PURPOSE : Create a single clean therapeutic category for each drug.
  AUTHOR  : Ann Kariuki  (github.com/annk-analytics)
  DATABASE: PortfolioProject

  BACKGROUND
    Some drugs are listed under several therapeutic categories at once,
    separated by semicolons (e.g. "ANESTHESIA; PEDIATRIC"). This created 50+
    category variations that made charts hard to read.

  THE FIX
    Add a new column keeping only the first category, reducing 50+ variations
    to 23 clean categories. The original column is kept for reference. Applied
    at the staging table so all later steps use the same clean category.
===============================================================================*/

-- STEP 1 | Create a clean category column
ALTER TABLE PortfolioProject..shortages_FDA_stagging
ADD Primary_Therapeutic_Category VARCHAR(100);

-- STEP 2 | Keep only the text before the first semicolon
UPDATE PortfolioProject..shortages_FDA_stagging
SET Primary_Therapeutic_Category =
    LEFT(Therapeutic_Category, CHARINDEX(';', Therapeutic_Category + ';') - 1);

-- STEP 3 | Check the results
SELECT DISTINCT Primary_Therapeutic_Category
FROM PortfolioProject..shortages_FDA_stagging
ORDER BY Primary_Therapeutic_Category;

/*===============================================================================
END OF SCRIPT

OUTPUT
- Cleaner 23 therapeutic categories
- More readable charts for better analysis results

NEXT STEP
03_exploratory_analysis.sql
===============================================================================*/
