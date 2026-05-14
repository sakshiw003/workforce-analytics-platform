-- ============================================================
-- Executive Summary Dashboard Query
-- Single query giving CEO-level snapshot of the platform
-- Business Question: "Give me the full workforce picture"
-- ============================================================

-- ── PLATFORM OVERVIEW ────────────────────────────────────
SELECT 'PLATFORM OVERVIEW' AS section, NULL AS metric, NULL AS value
UNION ALL
SELECT '──────────────────', NULL, NULL
UNION ALL
SELECT 'Total Job Postings',      'count',  COUNT(job_posting_id)::TEXT         FROM fact_job_postings
UNION ALL
SELECT 'Total Job Openings',      'count',  SUM(job_openings)::TEXT              FROM fact_job_postings
UNION ALL
SELECT 'Total Applications',      'count',  SUM(applications_count)::TEXT        FROM fact_job_postings
UNION ALL
SELECT 'Data Years Covered',      'range', '2015 - 2024'
UNION ALL
SELECT 'Countries Covered',       'count',  COUNT(DISTINCT country)::TEXT        FROM dim_location
UNION ALL
SELECT 'Industries Covered',      'count',  COUNT(DISTINCT industry)::TEXT       FROM dim_company
UNION ALL
SELECT 'Unique Roles',            'count',  COUNT(DISTINCT role_id)::TEXT        FROM dim_role
UNION ALL
SELECT 'Skills Tracked',          'count',  COUNT(DISTINCT skill_id)::TEXT       FROM dim_skill

UNION ALL SELECT '', NULL, NULL
UNION ALL SELECT 'SALARY INTELLIGENCE', NULL, NULL
UNION ALL SELECT '──────────────────', NULL, NULL
UNION ALL
SELECT 'Global Avg Salary',       'USD',    ROUND(AVG(salary_avg),0)::TEXT       FROM fact_job_postings
UNION ALL
SELECT 'Global Median Salary',    'USD',    PERCENTILE_CONT(0.5)
                                            WITHIN GROUP (ORDER BY salary_avg)::NUMERIC::INT::TEXT
                                                                                  FROM fact_job_postings
UNION ALL
SELECT 'Highest Avg Salary Role', 'role',   dr.role_name
FROM (
    SELECT f.role_id, AVG(f.salary_avg) AS avg_sal
    FROM fact_job_postings f GROUP BY f.role_id
    ORDER BY avg_sal DESC LIMIT 1
) top_role
JOIN dim_role dr ON top_role.role_id = dr.role_id

UNION ALL SELECT '', NULL, NULL
UNION ALL SELECT 'WORKFORCE TRENDS', NULL, NULL
UNION ALL SELECT '──────────────────', NULL, NULL
UNION ALL
SELECT 'Remote Work %',           'pct',
    ROUND(SUM(CASE WHEN work_mode='Remote' THEN 1 ELSE 0 END)::NUMERIC
    / COUNT(*) * 100, 1)::TEXT || '%'
FROM fact_job_postings
UNION ALL
SELECT 'AI-Related Jobs %',       'pct',
    ROUND(SUM(CASE WHEN ai_related_job THEN 1 ELSE 0 END)::NUMERIC
    / COUNT(*) * 100, 1)::TEXT || '%'
FROM fact_job_postings
UNION ALL
SELECT 'Avg Demand Score',        'score', ROUND(AVG(demand_score),2)::TEXT      FROM fact_job_postings;