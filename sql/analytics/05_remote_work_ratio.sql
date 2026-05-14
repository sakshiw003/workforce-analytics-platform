-- ============================================================
-- KPI 6: Remote Work Ratio
-- Tracks the shift to remote work over time
-- Business Question: "How has remote work evolved since 2015?"
-- ============================================================

-- ── PART A: Remote Work Trend by Year ────────────────────
WITH yearly_remote AS (
    SELECT
        EXTRACT(YEAR FROM posting_date)::INT        AS posting_year,
        COUNT(job_posting_id)                       AS total_postings,
        SUM(CASE WHEN work_mode = 'Remote'  THEN 1 ELSE 0 END) AS remote_count,
        SUM(CASE WHEN work_mode = 'Hybrid'  THEN 1 ELSE 0 END) AS hybrid_count,
        SUM(CASE WHEN work_mode = 'On-site' THEN 1 ELSE 0 END) AS onsite_count,
        SUM(CASE WHEN remote_allowed = TRUE THEN 1 ELSE 0 END) AS remote_allowed_count
    FROM fact_job_postings
    GROUP BY EXTRACT(YEAR FROM posting_date)
)
SELECT
    posting_year,
    total_postings,
    remote_count,
    hybrid_count,
    onsite_count,
    ROUND(remote_count::NUMERIC  / total_postings * 100, 1) AS remote_pct,
    ROUND(hybrid_count::NUMERIC  / total_postings * 100, 1) AS hybrid_pct,
    ROUND(onsite_count::NUMERIC  / total_postings * 100, 1) AS onsite_pct,
    ROUND(remote_allowed_count::NUMERIC / total_postings * 100, 1) AS remote_allowed_pct
FROM yearly_remote
ORDER BY posting_year;


-- ── PART B: Remote Work by Industry ──────────────────────
SELECT
    dc.industry,
    COUNT(f.job_posting_id)                                     AS total_postings,
    ROUND(
        SUM(CASE WHEN f.work_mode = 'Remote' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(f.job_posting_id) * 100
    , 1)                                                        AS remote_pct,
    ROUND(
        SUM(CASE WHEN f.work_mode = 'Hybrid' THEN 1 ELSE 0 END)::NUMERIC
        / COUNT(f.job_posting_id) * 100
    , 1)                                                        AS hybrid_pct,
    ROUND(AVG(f.salary_avg), 0)                                 AS avg_salary
FROM fact_job_postings f
JOIN dim_company dc ON f.company_id = dc.company_id
GROUP BY dc.industry
ORDER BY remote_pct DESC;