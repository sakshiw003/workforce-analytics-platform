-- ============================================================
-- KPI 4: Skill Demand Index
-- Measures which skills are most in-demand globally
-- Business Question: "What skills should job seekers learn?"
-- ============================================================

WITH skill_posting_counts AS (
    -- Step 1: Count how many job postings require each skill
    SELECT
        jsb.skill_id,
        COUNT(jsb.job_posting_id)   AS posting_count
    FROM job_skills_bridge jsb
    GROUP BY jsb.skill_id
),

skill_metrics AS (
    -- Step 2: Join with dim_skill and calculate demand metrics
    SELECT
        ds.skill_name,
        ds.skill_category,
        ds.is_ai_related,
        spc.posting_count,

        -- Demand Index: normalize to 0-100 scale
        ROUND(
            (spc.posting_count::NUMERIC / MAX(spc.posting_count) OVER ()) * 100
        , 1)                        AS demand_index,

        -- Rank within category
        RANK() OVER (
            PARTITION BY ds.skill_category
            ORDER BY spc.posting_count DESC
        )                           AS rank_in_category,

        -- Global rank
        RANK() OVER (
            ORDER BY spc.posting_count DESC
        )                           AS global_rank

    FROM skill_posting_counts spc
    JOIN dim_skill ds ON spc.skill_id = ds.skill_id
)

SELECT
    global_rank,
    skill_name,
    skill_category,
    is_ai_related,
    posting_count,
    demand_index,
    rank_in_category,
    CASE
        WHEN demand_index >= 75 THEN 'Critical Skill'
        WHEN demand_index >= 50 THEN 'High Demand'
        WHEN demand_index >= 25 THEN 'Moderate Demand'
        ELSE                         'Niche Skill'
    END                             AS demand_tier
FROM skill_metrics
ORDER BY global_rank
LIMIT 30;