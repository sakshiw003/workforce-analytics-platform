-- ============================================================
-- KPI 8: Automation Risk Score
-- Quantifies which roles face highest automation threat
-- Business Question: "Which careers are safest in the AI era?"
-- ============================================================

WITH role_risk_metrics AS (
    SELECT
        dr.role_name,
        dr.role_category,
        dr.ai_risk_level,
        dr.seniority_level,
        COUNT(f.job_posting_id)                                 AS total_postings,
        ROUND(AVG(f.salary_avg), 0)                             AS avg_salary,
        ROUND(AVG(f.demand_score), 2)                           AS avg_demand_score,
        SUM(f.job_openings)                                     AS total_openings,

        -- Convert text risk to numeric score (1-5 scale)
        CASE dr.ai_risk_level
            WHEN 'Very High'    THEN 5
            WHEN 'High'         THEN 4
            WHEN 'Medium'       THEN 3
            WHEN 'Low'          THEN 2
            WHEN 'Very Low'     THEN 1
            ELSE 0
        END                                                     AS risk_numeric,

        -- Year-over-year trend: is demand growing or declining?
        ROUND(
            CORR(
                EXTRACT(YEAR FROM f.posting_date),
                f.demand_score
            )::NUMERIC
        , 3)                                                    AS demand_trend_correlation
    FROM fact_job_postings f
    JOIN dim_role dr ON f.role_id = dr.role_id
    GROUP BY dr.role_name, dr.role_category, dr.ai_risk_level, dr.seniority_level
    HAVING COUNT(f.job_posting_id) >= 50
)
SELECT
    role_name,
    role_category,
    ai_risk_level,
    seniority_level,
    total_postings,
    avg_salary,
    avg_demand_score,
    total_openings,
    risk_numeric,
    demand_trend_correlation,

    -- Final Automation Risk Score (0-100)
    ROUND(
        (risk_numeric * 15)                             -- Risk level: up to 75 pts
        + (CASE WHEN avg_demand_score < 5 THEN 15 ELSE 0 END) -- Low demand adds risk
        + (CASE WHEN demand_trend_correlation < 0 THEN 10 ELSE 0 END) -- Declining trend
    , 0)                                                AS automation_risk_score,

    CASE
        WHEN risk_numeric >= 4                          THEN '🔴 High Risk'
        WHEN risk_numeric = 3                           THEN '🟡 Medium Risk'
        ELSE                                                 '🟢 Safe Career'
    END                                                 AS risk_category,

    CASE
        WHEN demand_trend_correlation > 0.3             THEN '📈 Growing'
        WHEN demand_trend_correlation < -0.3            THEN '📉 Declining'
        ELSE                                                 '➡ Stable'
    END                                                 AS demand_trend
FROM role_risk_metrics
ORDER BY automation_risk_score DESC;