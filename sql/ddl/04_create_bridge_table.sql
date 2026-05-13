-- ============================================================
-- Script  : 04_create_bridge_table.sql
-- Purpose : Create bridge table for job-skill many-to-many
-- Author  : Workforce Analytics Platform
-- ============================================================

\c workforce_analytics;

-- ──────────────────────────────────────────────
-- TABLE: job_skills_bridge
-- Many-to-many: one job can require many skills
-- One skill can appear in many jobs
-- 2.5 MILLION rows
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS job_skills_bridge (
    job_posting_id      VARCHAR(15)     NOT NULL REFERENCES fact_job_postings(job_posting_id),
    skill_id            VARCHAR(10)     NOT NULL REFERENCES dim_skill(skill_id),

    -- Composite Primary Key
    PRIMARY KEY (job_posting_id, skill_id)
);

COMMENT ON TABLE  job_skills_bridge                 IS 'Bridge table - maps job postings to required skills (2.5M rows)';
COMMENT ON COLUMN job_skills_bridge.job_posting_id  IS 'FK to fact_job_postings';
COMMENT ON COLUMN job_skills_bridge.skill_id        IS 'FK to dim_skill';