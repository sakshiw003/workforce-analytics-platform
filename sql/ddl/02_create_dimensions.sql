-- ============================================================
-- Script  : 02_create_dimensions.sql
-- Purpose : Create all dimension tables (Star Schema)
-- Author  : Workforce Analytics Platform
-- ============================================================

-- Connect to workforce_analytics before running this script
\c workforce_analytics;

-- ──────────────────────────────────────────────
-- TABLE: dim_company
-- Stores company information
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_company (
    company_id              VARCHAR(10)     PRIMARY KEY,
    company_name            VARCHAR(255)    NOT NULL,
    industry                VARCHAR(100)    NOT NULL,
    company_size            VARCHAR(50)     NOT NULL,
    headquarters_country    VARCHAR(100)    NOT NULL,
    created_at              TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  dim_company                       IS 'Company dimension - stores employer information';
COMMENT ON COLUMN dim_company.company_id            IS 'Unique company identifier (e.g. CMP0001)';
COMMENT ON COLUMN dim_company.company_size          IS 'Size category: Startup, SME, Large, Enterprise';
COMMENT ON COLUMN dim_company.headquarters_country  IS 'Country where company HQ is located';


-- ──────────────────────────────────────────────
-- TABLE: dim_role
-- Stores job role and AI risk information
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_role (
    role_id             VARCHAR(10)     PRIMARY KEY,
    role_name           VARCHAR(255)    NOT NULL,
    role_category       VARCHAR(100)    NOT NULL,
    ai_risk_level       VARCHAR(50)     NOT NULL,
    seniority_level     VARCHAR(50)     NOT NULL,
    created_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  dim_role                  IS 'Role dimension - stores job titles and AI risk categorization';
COMMENT ON COLUMN dim_role.role_id          IS 'Unique role identifier (e.g. ROL0001)';
COMMENT ON COLUMN dim_role.ai_risk_level    IS 'AI automation risk: Very Low, Low, Medium, High, Very High';
COMMENT ON COLUMN dim_role.seniority_level  IS 'Career level: Junior, Mid-Senior, Senior, Lead, Executive';


-- ──────────────────────────────────────────────
-- TABLE: dim_skill
-- Stores skill and category information
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_skill (
    skill_id            VARCHAR(10)     PRIMARY KEY,
    skill_name          VARCHAR(255)    NOT NULL,
    skill_category      VARCHAR(100)    NOT NULL,
    is_ai_related       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  dim_skill                 IS 'Skill dimension - stores technical and soft skills';
COMMENT ON COLUMN dim_skill.skill_id        IS 'Unique skill identifier (e.g. SKL0001)';
COMMENT ON COLUMN dim_skill.is_ai_related   IS 'TRUE if skill is AI/ML related';


-- ──────────────────────────────────────────────
-- TABLE: dim_location
-- Stores geographic information
-- ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_location (
    location_id     VARCHAR(10)     PRIMARY KEY,
    country         VARCHAR(100)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    continent       VARCHAR(50)     NOT NULL,
    currency        VARCHAR(10)     NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  dim_location              IS 'Location dimension - stores geographic data';
COMMENT ON COLUMN dim_location.location_id  IS 'Unique location identifier (e.g. LOC0001)';
COMMENT ON COLUMN dim_location.currency     IS 'Local currency code (e.g. USD, EUR, GBP)';