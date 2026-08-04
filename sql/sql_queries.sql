-- Query 1: Default Rate by Geography
-- Business Question: Which US states/territories show the highest and lowest credit risk?
SELECT 
    ProjectState,
    COUNT(*) AS loan_count,
    ROUND(AVG(Default_Flag) * 100, 2) AS default_rate_pct
FROM sba_loans
GROUP BY ProjectState
HAVING COUNT(*) >= 50
ORDER BY default_rate_pct DESC;
-- Insight: AL, FL, NJ show highest risk (11-13%); ID, WY, ME safest (~4.3%). ~9pt spread across geography.


-- Query 2: Year-over-Year Loan Growth
-- Business Question: How fast is loan volume growing/shrinking each year?
SELECT 
    ApprovalFiscalYear,
    COUNT(*) AS loan_count,
    LAG(COUNT(*)) OVER (ORDER BY ApprovalFiscalYear) AS prev_year_count,
    ROUND(
        (COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY ApprovalFiscalYear)) 
        / LAG(COUNT(*)) OVER (ORDER BY ApprovalFiscalYear) * 100, 2
    ) AS yoy_growth_pct
FROM sba_loans
GROUP BY ApprovalFiscalYear
ORDER BY ApprovalFiscalYear;
-- Insight: Growth peaks in 2011 (+11%) and 2014-15 (+13-14%), steady decline from 2016, sharp drop 2019 (partial year).


-- Query 3: Charge-Off Severity Per Defaulted Loan, by Sector
-- Business Question: When a loan defaults, how much is lost on average, per sector?
SELECT 
    NaicsDescription_Fixed,
    COUNT(*) AS defaulted_loans,
    ROUND(AVG(GrossChargeOffAmount), 2) AS avg_loss_per_default
FROM sba_loans
WHERE LoanStatus = 'CHGOFF'
GROUP BY NaicsDescription_Fixed
HAVING COUNT(*) >= 5
ORDER BY avg_loss_per_default DESC
LIMIT 10;
-- Insight: Hotels/Motels rank top-3 in severity (~$920K/default) despite low default frequency - low frequency, high severity.


-- Query 4: Risk-Adjusted Sector Ranking
-- Business Question: Which sectors are risky on BOTH default rate AND severity combined?
WITH sector_stats AS (
    SELECT 
        NaicsDescription_Fixed,
        COUNT(*) AS loan_count,
        AVG(Default_Flag) AS default_rate,
        AVG(CASE WHEN LoanStatus = 'CHGOFF' THEN GrossChargeOffAmount END) AS avg_severity
    FROM sba_loans
    GROUP BY NaicsDescription_Fixed
    HAVING COUNT(*) >= 20
)
SELECT 
    NaicsDescription_Fixed,
    loan_count,
    ROUND(default_rate * 100, 2) AS default_rate_pct,
    ROUND(avg_severity, 2) AS avg_severity,
    RANK() OVER (ORDER BY default_rate DESC) AS rate_rank,
    RANK() OVER (ORDER BY avg_severity DESC) AS severity_rank,
    RANK() OVER (ORDER BY default_rate DESC) + RANK() OVER (ORDER BY avg_severity DESC) AS composite_risk_score
FROM sector_stats
ORDER BY composite_risk_score ASC
LIMIT 10;
-- Insight: Heating Oil Dealers, Cosmetology/Barber Schools rank worst on combined frequency + severity risk.


-- Query 5: Guarantee Coverage Ratio vs. Default Rate
-- Business Question: Does higher government guarantee % correlate with higher default rate?
SELECT 
    CASE 
        WHEN SBAGuaranteedApproval / GrossApproval < 0.5 THEN 'Low (<50%)'
        WHEN SBAGuaranteedApproval / GrossApproval < 0.75 THEN 'Mid (50-75%)'
        ELSE 'High (75-100%)'
    END AS guarantee_bucket,
    COUNT(*) AS loan_count,
    ROUND(AVG(Default_Flag) * 100, 2) AS default_rate_pct
FROM sba_loans
GROUP BY guarantee_bucket
ORDER BY default_rate_pct DESC;
-- Insight: High guarantee coverage (75-100%) loans default more (8.71%) - guarantee compensates for pre-existing risk, doesn't cause it.


-- Query 6: Default Rate by Delivery Method
-- Business Question: Do different SBA loan programs carry different default risk?
SELECT 
    DeliveryMethod,
    COUNT(*) AS loan_count,
    ROUND(AVG(Default_Flag) * 100, 2) AS default_rate_pct
FROM sba_loans
GROUP BY DeliveryMethod
HAVING COUNT(*) >= 30
ORDER BY default_rate_pct DESC;
-- Insight: Community Express (COMM EXPRS) defaults at 22.25% - 3x portfolio average; EWCP safest at 0.92%.


-- Query 7: Sector x Loan Size Tier Cross-Analysis
-- Business Question: Is a risky sector risky across all loan sizes, or concentrated in one tier?
SELECT 
    NaicsDescription_Fixed,
    Loan_Size_Tier,
    COUNT(*) AS loan_count,
    ROUND(AVG(Default_Flag) * 100, 2) AS default_rate_pct
FROM sba_loans
GROUP BY NaicsDescription_Fixed, Loan_Size_Tier
HAVING COUNT(*) >= 20
ORDER BY NaicsDescription_Fixed, default_rate_pct DESC;
-- Insight: Full-Service Restaurants risk is concentrated in Small/Medium/Micro tiers (10-10.6%), not Large (3.1%).


-- Query 8: Top 10 Largest Loans & Their Outcomes
-- Business Question: Are our biggest-dollar loans actually safe, or hidden concentration risk?
SELECT 
    BorrName,
    GrossApproval,
    NaicsDescription_Fixed,
    LoanStatus
FROM sba_loans
ORDER BY GrossApproval DESC
LIMIT 10;
-- Insight: All top 10 loans are capped at the $5M SBA maximum, and all 10 are PIF - zero defaults among largest exposures.


-- Query 9: Portfolio Concentration by Sector
-- Business Question: How concentrated is total lending exposure across sectors?
SELECT 
    NaicsDescription_Fixed,
    SUM(GrossApproval) AS total_approved,
    ROUND(
        SUM(SUM(GrossApproval)) OVER (ORDER BY SUM(GrossApproval) DESC) 
        / SUM(SUM(GrossApproval)) OVER () * 100, 2
    ) AS cumulative_pct_of_portfolio
FROM sba_loans
GROUP BY NaicsDescription_Fixed
ORDER BY total_approved DESC
LIMIT 10;
-- Insight: Top 10 sectors account for 30.83% of the entire $16.55B portfolio - meaningful concentration risk.


-- Query 10: Loan Size Tier x Term Category Default Rate
-- Business Question: What combination of loan size and term is the safest loan structure?
SELECT 
    Loan_Size_Tier,
    Term_Category,
    COUNT(*) AS loan_count,
    ROUND(AVG(Default_Flag) * 100, 2) AS default_rate_pct
FROM sba_loans
GROUP BY Loan_Size_Tier, Term_Category
ORDER BY Loan_Size_Tier, default_rate_pct DESC;
-- Insight: Short-term loans default far more than Long-term within EVERY size tier. Safest: Large+Long (1.9%). Riskiest: Micro+Short (37.4%).