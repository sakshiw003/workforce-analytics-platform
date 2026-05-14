-- ============================================================
-- KPI 2 & 3: Average Salary + Salary Growth %
-- Multi-dimensional salary analysis
-- Business Question: "Where and what pays the most?"
-- ============================================================

-- ── PART A: Salary by Country ─────────────────────────────
SELECT
    'by_country'                            AS analysis_type,
    dl.country,
    dl.continent,
    dl.currency,
    COUNT(f.job_posting_id)                 AS total_postings,
    ROUND(AVG(f.salary_avg), 0)             AS avg_salary,
    ROUND(MIN(f.salary_avg), 0)             AS min_salary,
    ROUND(MAX(f.salary_avg), 0)             AS max_salary,
    ROUND(
    (PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY salary_avg))::numeric,
    2
) AS median_salary,
    RANK() OVER (ORDER BY AVG(f.salary_avg) DESC) AS salary_rank
FROM fact_job_postings f
JOIN dim_location dl ON f.location_id = dl.location_id
GROUP BY dl.country, dl.continent, dl.currency
ORDER BY avg_salary DESC
LIMIT 20;


-- ── PART B: Salary by Role Category ──────────────────────
SELECT
    'by_role_category'                      AS analysis_type,
    dr.role_category,
    dr.seniority_level,
    COUNT(f.job_posting_id)                 AS total_postings,
    ROUND(AVG(f.salary_avg), 0)             AS avg_salary,
    ROUND(AVG(f.salary_min), 0)             AS avg_salary_min,
    ROUND(AVG(f.salary_max), 0)             AS avg_salary_max,
    ROUND(AVG(f.salary_max) - AVG(f.salary_min), 0) AS avg_salary_band_width
FROM fact_job_postings f
JOIN dim_role dr ON f.role_id = dr.role_id
GROUP BY dr.role_category, dr.seniority_level
ORDER BY avg_salary DESC
LIMIT 20;


-- ── PART C: Salary Growth Year over Year ─────────────────
WITH yearly_salary AS (
    SELECT
        EXTRACT(YEAR FROM posting_date)::INT    AS posting_year,
        ROUND(AVG(salary_avg), 0)               AS avg_salary
    FROM fact_job_postings
    GROUP BY EXTRACT(YEAR FROM posting_date)
)
SELECT
    posting_year,
    avg_salary,
    LAG(avg_salary) OVER (ORDER BY posting_year)    AS prev_year_salary,
    ROUND(
        ((avg_salary - LAG(avg_salary) OVER (ORDER BY posting_year))::NUMERIC
        / LAG(avg_salary) OVER (ORDER BY posting_year)) * 100
    , 2)                                            AS salary_growth_pct
FROM yearly_salary
ORDER BY posting_year;


-- ── PART D: Top 10 Highest Paying Roles ──────────────────
SELECT
    dr.role_name,
    dr.role_category,
    dr.seniority_level,
    dr.ai_risk_level,
    COUNT(f.job_posting_id)             AS total_postings,
    ROUND(AVG(f.salary_avg), 0)         AS avg_salary,
    ROUND(AVG(f.salary_max), 0)         AS avg_max_salary
FROM fact_job_postings f
JOIN dim_role dr ON f.role_id = dr.role_id
GROUP BY dr.role_name, dr.role_category, dr.seniority_level, dr.ai_risk_level
HAVING COUNT(f.job_posting_id) >= 100  -- only roles with significant sample size
ORDER BY avg_salary DESC
LIMIT 10;