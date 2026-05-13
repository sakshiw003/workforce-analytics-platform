-- ============================================================
-- Script  : 01_create_database.sql
-- Purpose : Create the workforce_analytics database
-- Author  : Workforce Analytics Platform
-- ============================================================

-- Connect to default postgres DB first, then run this
CREATE DATABASE workforce_analytics
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

COMMENT ON DATABASE workforce_analytics
    IS 'AI-Powered Global Workforce Analytics Platform';