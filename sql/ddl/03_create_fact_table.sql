-- ============================================================
-- Script  : 03_create_fact_table.sql
-- Purpose : Create the central fact table (500K rows)
-- Author  : Workforce Analytics Platform
-- ============================================================

\c workforce_analytics;

-- ──────────────────────────────────────────────
-- TABLE: fact_job_postings
-- Central fact table - all job posting metrics
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_job_postings (
    job_posting_id          VARCHAR(15)     PRIMARY KEY,

    -- Foreign Keys to Dimensions
    company_id              VARCHAR(10)     NOT NULL REFERENCES dim_company(company_id),
    role_id                 VARCHAR(10)     NOT NULL REFERENCES dim_role(role_id),
    location_id             VARCHAR(10)     NOT NULL REFERENCES dim_location(location_id),

    -- Time Data
    posting_date            DATE            NOT NULL,

    -- Job Details
    experience_required     SMALLINT        NOT NULL CHECK (experience_required >= 0),
    employment_type         VARCHAR(50)     NOT NULL,
    work_mode               VARCHAR(50)     NOT NULL,

    -- Salary Metrics
    salary_min              INTEGER         NOT NULL CHECK (salary_min >= 0),
    salary_max              INTEGER         NOT NULL CHECK (salary_max >= salary_min),
    salary_avg              INTEGER         NOT NULL CHECK (salary_avg >= 0),

    -- Volume Metrics
    job_openings            INTEGER         NOT NULL DEFAULT 1 CHECK (job_openings > 0),
    applications_count      INTEGER         NOT NULL DEFAULT 0 CHECK (applications_count >= 0),

    -- Boolean Flags
    remote_allowed          BOOLEAN         NOT NULL DEFAULT FALSE,
    ai_related_job          BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Scores
    demand_score            NUMERIC(4,1)    NOT NULL CHECK (demand_score BETWEEN 0 AND 10),

    -- Audit
    created_at              TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  fact_job_postings                     IS 'Central fact table - 500K job postings with salary, demand, and workforce metrics';
COMMENT ON COLUMN fact_job_postings.job_posting_id      IS 'Unique job posting identifier (e.g. JOB00000001)';
COMMENT ON COLUMN fact_job_postings.salary_avg          IS 'Average salary in local currency';
COMMENT ON COLUMN fact_job_postings.demand_score        IS 'Job demand score 0-10 (higher = more demand)';
COMMENT ON COLUMN fact_job_postings.remote_allowed      IS 'TRUE if position allows remote work';
COMMENT ON COLUMN fact_job_postings.ai_related_job      IS 'TRUE if job is in AI/ML domain';
COMMENT ON COLUMN fact_job_postings.applications_count  IS 'Number of applications received';