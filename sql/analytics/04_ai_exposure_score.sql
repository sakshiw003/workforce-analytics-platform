-- ============================================================
-- KPI 5: AI Exposure Score
-- Measures how much each industry/role is exposed to AI
-- Business Question: "Which jobs are most at risk from AI?"
-- ============================================================

-- ── PART A: AI Exposure by Industry ──────────────────────
SELECT
    dc.industry,
    COUNT(f.job_posting_id)                         AS total_postings,
    SUM(CASE WHEN f.ai_related_job THEN 1 ELSE 0 END)   AS ai_jobs_count,
    ROUND(
        SUM(CASE WHEN f.ai_related_job THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(f.job_posting_id) * 100
    , 1)                                            AS ai_job_pct,
    ROUND(AVG(f.demand_score), 2)                   AS avg_demand_score,

    -- AI Exposure Score: composite of AI jobs % + demand
    ROUND(
        (SUM(CASE WHEN f.ai_related_job THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(f.job_posting_id) * 70)             -- 70% weight on AI job %
        + (AVG(f.demand_score) * 3)                 -- 30% weight on demand score
    , 1)                                            AS ai_exposure_score
FROM fact_job_postings f
JOIN dim_company dc ON f.company_id = dc.company_id
GROUP BY dc.industry
ORDER BY ai_exposure_score DESC;


-- ── PART B: AI Risk by Role ───────────────────────────────
SELECT
    dr.role_name,
    dr.role_category,
    dr.ai_risk_level,
    dr.seniority_level,
    COUNT(f.job_posting_id)                         AS total_postings,
    ROUND(AVG(f.salary_avg), 0)                     AS avg_salary,
    ROUND(AVG(f.demand_score), 2)                   AS avg_demand_score,
    SUM(f.job_openings)                             AS total_openings,

    -- Rank roles by automation risk
    RANK() OVER (ORDER BY
        CASE dr.ai_risk_level
            WHEN 'Very High'    THEN 5
            WHEN 'High'         THEN 4
            WHEN 'Medium'       THEN 3
            WHEN 'Low'          THEN 2
            WHEN 'Very Low'     THEN 1
            ELSE 0
        END DESC
    )                                               AS risk_rank
FROM fact_job_postings f
JOIN dim_role dr ON f.role_id = dr.role_id
GROUP BY dr.role_name, dr.role_category, dr.ai_risk_level, dr.seniority_level
ORDER BY risk_rank
LIMIT 25;