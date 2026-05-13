-- ============================================================
-- Script  : 05_create_indexes.sql
-- Purpose : Create performance indexes for analytics queries
-- Author  : Workforce Analytics Platform
-- ============================================================

\c workforce_analytics;

-- ──────────────────────────────────────────────
-- FACT TABLE INDEXES
-- Critical for 500K row analytics performance
-- ──────────────────────────────────────────────

-- Date-based filtering (most common in analytics)
CREATE INDEX IF NOT EXISTS idx_fact_posting_date
    ON fact_job_postings(posting_date);

-- FK join indexes
CREATE INDEX IF NOT EXISTS idx_fact_company_id
    ON fact_job_postings(company_id);

CREATE INDEX IF NOT EXISTS idx_fact_role_id
    ON fact_job_postings(role_id);

CREATE INDEX IF NOT EXISTS idx_fact_location_id
    ON fact_job_postings(location_id);

-- Salary range analytics
CREATE INDEX IF NOT EXISTS idx_fact_salary_avg
    ON fact_job_postings(salary_avg);

-- Filter indexes for common WHERE clauses
CREATE INDEX IF NOT EXISTS idx_fact_work_mode
    ON fact_job_postings(work_mode);

CREATE INDEX IF NOT EXISTS idx_fact_employment_type
    ON fact_job_postings(employment_type);

CREATE INDEX IF NOT EXISTS idx_fact_ai_related
    ON fact_job_postings(ai_related_job);

CREATE INDEX IF NOT EXISTS idx_fact_remote_allowed
    ON fact_job_postings(remote_allowed);

-- Year extraction for trend analysis
CREATE INDEX IF NOT EXISTS idx_fact_posting_year
    ON fact_job_postings(EXTRACT(YEAR FROM posting_date));


-- ──────────────────────────────────────────────
-- BRIDGE TABLE INDEXES
-- Critical for 2.5M row skill lookups
-- ──────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_bridge_skill_id
    ON job_skills_bridge(skill_id);

CREATE INDEX IF NOT EXISTS idx_bridge_job_id
    ON job_skills_bridge(job_posting_id);


-- ──────────────────────────────────────────────
-- DIMENSION TABLE INDEXES
-- ──────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_company_industry
    ON dim_company(industry);

CREATE INDEX IF NOT EXISTS idx_company_hq_country
    ON dim_company(headquarters_country);

CREATE INDEX IF NOT EXISTS idx_role_category
    ON dim_role(role_category);

CREATE INDEX IF NOT EXISTS idx_role_ai_risk
    ON dim_role(ai_risk_level);

CREATE INDEX IF NOT EXISTS idx_skill_category
    ON dim_skill(skill_category);

CREATE INDEX IF NOT EXISTS idx_skill_ai_related
    ON dim_skill(is_ai_related);

CREATE INDEX IF NOT EXISTS idx_location_country
    ON dim_location(country);

CREATE INDEX IF NOT EXISTS idx_location_continent
    ON dim_location(continent);