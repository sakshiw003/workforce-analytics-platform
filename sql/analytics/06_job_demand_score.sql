-- ============================================================
-- KPI 7: Job Demand Score Analysis
-- Identifies highest-demand roles and locations globally
-- Business Question: "Where are the hottest job markets?"
-- ============================================================

-- ── PART A: Top Demand Roles ──────────────────────────────
SELECT
    dr.role_name,
    dr.role_category,
    dr.seniority_level,
    COUNT(f.job_posting_id)             AS total_postings,
    ROUND(AVG(f.demand_score), 2)       AS avg_demand_score,
    SUM(f.job_openings)                 AS total_openings,
    ROUND(AVG(f.salary_avg), 0)         AS avg_salary,
    RANK() OVER (
        ORDER BY AVG(f.demand_score) DESC
    )                                   AS demand_rank
FROM fact_job_postings f
JOIN dim_role dr ON f.role_id = dr.role_id
GROUP BY dr.role_name, dr.role_category, dr.seniority_level
HAVING COUNT(f.job_posting_id) >= 50
ORDER BY avg_demand_score DESC
LIMIT 20;


-- ── PART B: Demand by Location (City-level) ───────────────
SELECT
    dl.city,
    dl.country,
    dl.continent,
    COUNT(f.job_posting_id)             AS total_postings,
    SUM(f.job_openings)                 AS total_openings,
    ROUND(AVG(f.demand_score), 2)       AS avg_demand_score,
    ROUND(AVG(f.salary_avg), 0)         AS avg_salary,
    RANK() OVER (
        ORDER BY SUM(f.job_openings) DESC
    )                                   AS openings_rank
FROM fact_job_postings f
JOIN dim_location dl ON f.location_id = dl.location_id
GROUP BY dl.city, dl.country, dl.continent
ORDER BY total_openings DESC
LIMIT 20;