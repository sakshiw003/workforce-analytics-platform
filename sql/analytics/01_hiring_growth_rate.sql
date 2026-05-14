-- ============================================================
-- KPI 1: Hiring Growth Rate
-- Shows how job postings grew or declined year over year
-- Business Question: "Is global hiring accelerating or slowing?"
-- ============================================================

WITH yearly_postings AS (
    -- Step 1: Count total job openings per year
    SELECT
        EXTRACT(YEAR FROM posting_date)::INT   AS posting_year,
        SUM(job_openings)                       AS total_openings,
        COUNT(job_posting_id)                   AS total_postings,
        ROUND(AVG(applications_count), 0)       AS avg_applications
    FROM fact_job_postings
    GROUP BY EXTRACT(YEAR FROM posting_date)
),

growth_calc AS (
    -- Step 2: Calculate year-over-year growth using LAG window function
    -- LAG looks at the PREVIOUS row's value
    SELECT
        posting_year,
        total_openings,
        total_postings,
        avg_applications,
        LAG(total_openings) OVER (ORDER BY posting_year) AS prev_year_openings,
        LAG(total_postings) OVER (ORDER BY posting_year) AS prev_year_postings
    FROM yearly_postings
)

-- Step 3: Calculate final growth rate %
SELECT
    posting_year,
    total_postings,
    total_openings,
    avg_applications,
    prev_year_openings,
    CASE
        WHEN prev_year_openings IS NULL THEN NULL  -- first year has no growth rate
        ELSE ROUND(
            ((total_openings - prev_year_openings)::NUMERIC / prev_year_openings) * 100
        , 2)
    END                                             AS hiring_growth_rate_pct,
    CASE
        WHEN prev_year_openings IS NULL     THEN 'Baseline Year'
        WHEN total_openings > prev_year_openings THEN '📈 Growth'
        WHEN total_openings < prev_year_openings THEN '📉 Decline'
        ELSE                                         '➡ Flat'
    END                                             AS trend_direction
FROM growth_calc
ORDER BY posting_year;