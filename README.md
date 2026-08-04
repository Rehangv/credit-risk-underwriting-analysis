# Credit Risk Underwriting Analysis

## 1. Executive Summary

This project analyzes 50,000 real U.S. Small Business Administration (SBA) 7(a) loan
records to identify credit risk patterns relevant to MSME (Micro, Small, and Medium
Enterprise) lending. Framed from the perspective of an NBFC credit risk analyst, the
project answers: which business segments should we lend to, which should we avoid,
and what loan structures minimize default risk?

The analysis uses a complete data pipeline — Excel/Power Query for cleaning, MySQL for
relational querying, and Power BI for interactive visualization — culminating in a
4-page dashboard with actionable, data-backed lending recommendations.

## 2. Business Problem

MSME lenders (particularly NBFCs) must balance financial inclusion with credit risk
management. This project simulates the analytical workflow a credit risk team uses to
answer: which loan segments are safe to expand, and which need tighter underwriting
or exposure limits?

## 3. Data Source

- **Source:** U.S. Small Business Administration, 7(a) Loan Program FOIA dataset
- **Scope used:** 2010-2019 (545,751 total loan records)
- **Sample:** 50,000 loans, filtered to completed outcomes only (PIF = Paid in Full,
  CHGOFF = Charged Off/Defaulted) before random sampling (random_state=42 for
  reproducibility)
- **Public source:** SBA FOIA data releases (data.gov / SBA.gov)

## 4. Tech Stack

| Tool | Purpose |
|---|---|
| Python (pandas) | One-time data sampling (50K rows from 545K, pre-filtered to completed loans) |
| Excel + Power Query | Data cleaning, transformation, feature engineering, 11 core analyses |
| MySQL | Relational storage and 10 SQL business-question queries (window functions, CTEs) |
| Power BI + DAX | 4-page interactive dashboard, 10 DAX measures |

## 5. Data Cleaning Process

- Started from a random 50,000-loan sample of the 2010-2019 SBA dataset (data/sba_raw_sample.csv), including all loan statuses (PIF, CHGOFF, CANCLD, EXEMPT, COMMIT)
- Filtered to loans with a completed outcome (PIF or CHGOFF) before sampling — ensures
  every loan has a known result
- Removed 20 non-analytical columns (lender address/ID fields, redundant date/code
  fields, administrative metadata)
- Handled missing values: BusinessAge to "Unknown" (~89% missing in source data,
  documented as a limitation), NaicsDescription to "Other" (~0.1% missing),
  GrossChargeOffAmount to 0 for fully repaid loans
- Identified and corrected a 70-character field-truncation issue in NaicsDescription
  (a source-data limitation) by cross-referencing the U.S. Census Bureau's official
  NAICS 2017 code list via NaicsCode
- Engineered features: Default_Flag (binary outcome), Loan_Size_Tier (Micro/Small/
  Medium/Large), Term_Category (Short/Medium/Long), JobsBucket, RateBucket
- Identified and documented approximately 0.05% duplicate records inherited from the
  source government data

## 6. Analysis

**Excel (11 analyses):** overall default rate, default rate by sector, loan size,
term, business type, business age, revolver status, charge-off amount by sector, loan
approval trend by year, jobs supported vs. default, interest rate vs. default.
Full workbook: [excel/sba_excel_analysis.xlsx](excel/sba_excel_analysis.xlsx)

**MySQL (10 queries):** default rate by geography, year-over-year growth (LAG),
charge-off severity per default by sector, risk-adjusted composite sector ranking
(RANK, CTEs), guarantee coverage ratio vs. default, default rate by delivery method,
sector x loan size cross-analysis, top 10 largest loans, portfolio concentration by
sector (running totals), loan size x term default rate.
Full query set with comments: [sql/sql_queries.sql](sql/sql_queries.sql)
Exported results: [sql/sql_query_results.xlsx](sql/sql_query_results.xlsx)

## 7. Dashboard Overview

**Page 1 - Executive Credit Summary:** portfolio-wide KPIs, approval trend, loan
status breakdown.

**Page 2 - Sector Risk Intelligence:** top 10 riskiest sectors by rate and by dollar
loss, plus a treemap showing portfolio concentration (size) vs. default risk (color)
across the top 20 sectors by volume.

**Page 3 - Risk Drivers: Structure & Geography:** default rate by loan term, business
type, business age, and state, plus a loan size x term default rate heatmap.

**Page 4 - Portfolio Risk & Recommendations:** Portfolio at Risk / Recovery Rate KPIs,
a 30-sector risk-tier watchlist, and written lending recommendations.

Dashboard file: [powerbi/credit_risk_dashboard.pbix](powerbi/credit_risk_dashboard.pbix)

## 8. Key KPIs (DAX Measures)

| Measure | Value |
|---|---|
| Total Loans | 50,000 |
| Default Rate | 7.89% |
| Total Approved Amount | $16.55B |
| Total Charge-Off Loss | $533.99M |
| Average Loan Size | ~$331K |
| Loss Severity (avg loss per default) | ~$135,393 |
| Safe Lending Rate | 92.11% |
| Jobs Created Total | 543K |
| Portfolio at Risk | $827.17M |
| Recovery Rate | 35.44% |

## 9. Key Findings

- Loan structure is the strongest predictor of default identified - Micro loans with
  Short terms default at 37.4% vs. 1.9% for Large, Long-term loans, a 20x spread,
  consistent across every sector tested.
- Restaurants are the largest concentrated risk - Full- and Limited-Service
  Restaurants together account for over 12% of total portfolio dollar losses, with
  default rates (9.7-10.2%) above the 7.89% portfolio average.
- Interest rate pricing works as intended - default rate rises from 3.15% (low rate)
  to 12.07% (high rate), confirming risk-based pricing is functioning correctly.
- Newer businesses default meaningfully more - businesses under 3 years old default at
  ~14%, nearly 3x the rate of businesses undergoing a change of ownership (4.9%).
- Geography shows a real, if secondary, effect - Alabama (13.0%), Florida (11.9%), and
  New Jersey (10.8%) are the highest-risk states; Idaho (4.3%) and Wyoming (4.3%) are
  the safest.
- Jobs supported and revolving-credit status showed no meaningful correlation with
  default - reported as genuine null findings rather than forced narratives.

## 10. Business Impact

The composite risk framework built here (sector risk x loan structure x geography)
provides a template for setting differentiated underwriting standards - tighter terms
for Micro/Short-term loans in high-risk sectors, and expanded lending capacity for
Large/Long-term loans in consistently low-risk segments - without needing to restrict
lending uniformly across the portfolio.

## 11. Recommendations

- **Avoid / tighten underwriting:** Promoters of Performing Arts (25.7%), Family
  Clothing Stores (24.5%), Household Appliance/Electronics Retailers (23-24%),
  Ambulance Services (23.3%), Heating Oil Dealers (22.7%)
- **Prioritize:** Veterinary Services (1.2%, n=418), Hotels/Motels (1.8%, n=733),
  Offices of Dentists (2.8%), Offices of Optometrists (0.6%)
- **Optimal structure:** favor Large loan size + Long term combinations wherever
  feasible; treat Micro + Short term as the highest-risk combination requiring
  additional safeguards
- **Geographic focus:** exercise added caution in Alabama, Florida, and New Jersey;
  Idaho, Wyoming, and Maine show consistently lower risk

## 12. Limitations

- Sample of 50,000 loans (2010-2019 subset only) rather than the full 545,751-record
  or multi-decade SBA dataset
- BusinessAge is missing for approximately 89% of records in the source data, limiting
  the reliability of business-age findings
- U.S. lending data; underlying dollar figures, interest rate environment, and
  regulatory context differ from the Indian MSME/NBFC market - the analytical
  framework (sector, structure, and geographic risk segmentation) is intended to be
  transferable, not the specific figures
- NaicsDescription was truncated at 70 characters in the original government export;
  corrected via NAICS code cross-reference for most, but not all, affected records

## 13. Future Improvements

- Integrate Indian RBI/MSME lending data to directly validate the framework's
  transferability
- Build a machine learning credit scoring model (e.g., logistic regression or gradient
  boosting) using the engineered features as inputs
- Incorporate time-to-default analysis using FirstDisbursementDate and
  ChargeOffDate to study default timing, not just default likelihood
- Expand geographic analysis to county-level granularity where data permits

## Repository Structure

    credit-risk-underwriting-analysis/
    |-- README.md
    |-- data/
    |   |-- sba_raw_sample.csv             (50,000-row raw random sample, before cleaning)
    |   `-- sba_final_cleaned.csv          (50,000-row cleaned, filtered, engineered dataset)
    |-- excel/
    |   `-- sba_excel_analysis.xlsx        (cleaning + 11 analysis sheets)
    |-- sql/
    |   |-- sql_queries.sql                (10 commented SQL queries)
    |   `-- sql_query_results.xlsx         (exported query results)
    |-- powerbi/
    |   `-- credit_risk_dashboard.pbix     (4-page interactive dashboard)
    `-- docs/
        `-- state_lookup.xlsx              (US state code to full name reference)