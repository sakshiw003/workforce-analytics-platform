# ============================================================
# Module  : data_transformer.py
# Purpose : Clean, validate, and type-cast all DataFrames
#           before loading into PostgreSQL
# ============================================================

import pandas as pd
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from etl.utils.logger import get_logger

logger = get_logger(__name__)


# ════════════════════════════════════════════
# DIMENSION TRANSFORMERS
# ════════════════════════════════════════════

def transform_dim_company(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and validate dim_company"""
    logger.info("Transforming dim_company ...")

    original_count = len(df)

    # 1. Strip whitespace from all string columns
    str_cols = ["company_id", "company_name", "industry",
                "company_size", "headquarters_country"]
    for col in str_cols:
        df[col] = df[col].astype(str).str.strip()

    # 2. Drop duplicates on primary key
    df = df.drop_duplicates(subset=["company_id"])

    # 3. Drop rows with null primary key
    df = df.dropna(subset=["company_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


def transform_dim_role(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and validate dim_role"""
    logger.info("Transforming dim_role ...")

    original_count = len(df)

    str_cols = ["role_id", "role_name", "role_category",
                "ai_risk_level", "seniority_level"]
    for col in str_cols:
        df[col] = df[col].astype(str).str.strip()

    df = df.drop_duplicates(subset=["role_id"])
    df = df.dropna(subset=["role_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


def transform_dim_skill(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and validate dim_skill"""
    logger.info("Transforming dim_skill ...")

    original_count = len(df)

    str_cols = ["skill_id", "skill_name", "skill_category"]
    for col in str_cols:
        df[col] = df[col].astype(str).str.strip()

    # Ensure boolean type for is_ai_related
    df["is_ai_related"] = df["is_ai_related"].astype(bool)

    df = df.drop_duplicates(subset=["skill_id"])
    df = df.dropna(subset=["skill_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


def transform_dim_location(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and validate dim_location"""
    logger.info("Transforming dim_location ...")

    original_count = len(df)

    str_cols = ["location_id", "country", "city", "continent", "currency"]
    for col in str_cols:
        df[col] = df[col].astype(str).str.strip()

    df = df.drop_duplicates(subset=["location_id"])
    df = df.dropna(subset=["location_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


# ════════════════════════════════════════════
# FACT TABLE TRANSFORMER
# ════════════════════════════════════════════

def transform_fact_job_postings(df: pd.DataFrame) -> pd.DataFrame:
    """Clean, validate, and type-cast fact_job_postings"""
    logger.info("Transforming fact_job_postings ...")

    original_count = len(df)

    # 1. String columns — strip whitespace
    str_cols = ["job_posting_id", "company_id", "role_id",
                "location_id", "employment_type", "work_mode"]
    for col in str_cols:
        df[col] = df[col].astype(str).str.strip()

    # 2. Parse posting_date as proper date
    df["posting_date"] = pd.to_datetime(df["posting_date"], errors="coerce").dt.date

    # 3. Integer columns
    int_cols = ["experience_required", "salary_min", "salary_max",
                "salary_avg", "job_openings", "applications_count"]
    for col in int_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0).astype(int)

    # 4. Boolean columns
    bool_cols = ["remote_allowed", "ai_related_job"]
    for col in bool_cols:
        df[col] = df[col].astype(bool)

    # 5. Float column
    df["demand_score"] = pd.to_numeric(df["demand_score"], errors="coerce").round(1)

    # 6. Business validations
    invalid_salary = df["salary_max"] < df["salary_min"]
    invalid_date   = df["posting_date"].isna()
    invalid_demand = ~df["demand_score"].between(0, 10)

    if invalid_salary.any():
        logger.warning(f"  ⚠ {invalid_salary.sum()} rows with salary_max < salary_min — dropping")
        df = df[~invalid_salary]

    if invalid_date.any():
        logger.warning(f"  ⚠ {invalid_date.sum()} rows with invalid posting_date — dropping")
        df = df[~invalid_date]

    if invalid_demand.any():
        logger.warning(f"  ⚠ {invalid_demand.sum()} rows with demand_score out of 0-10 — clamping")
        df["demand_score"] = df["demand_score"].clip(0, 10)

    # 7. Remove duplicates on PK
    df = df.drop_duplicates(subset=["job_posting_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


# ════════════════════════════════════════════
# BRIDGE TABLE TRANSFORMER
# ════════════════════════════════════════════

def transform_job_skills_bridge(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and validate job_skills_bridge"""
    logger.info("Transforming job_skills_bridge ...")

    original_count = len(df)

    df["job_posting_id"] = df["job_posting_id"].astype(str).str.strip()
    df["skill_id"]       = df["skill_id"].astype(str).str.strip()

    # Remove duplicate composite keys
    df = df.drop_duplicates(subset=["job_posting_id", "skill_id"])

    # Drop rows with nulls in either key
    df = df.dropna(subset=["job_posting_id", "skill_id"])

    logger.info(f"  └─ {original_count:,} → {len(df):,} rows after cleaning")
    return df


# ════════════════════════════════════════════
# MASTER TRANSFORM FUNCTION
# ════════════════════════════════════════════

# Maps table name → its transformer function
TRANSFORMERS = {
    "dim_company"       : transform_dim_company,
    "dim_role"          : transform_dim_role,
    "dim_skill"         : transform_dim_skill,
    "dim_location"      : transform_dim_location,
    "fact_job_postings" : transform_fact_job_postings,
    "job_skills_bridge" : transform_job_skills_bridge,
}


def transform_all(dataframes: dict) -> dict:
    """
    Apply the correct transformer to each DataFrame.

    Args:
        dataframes: dict of { table_name: raw DataFrame }

    Returns:
        dict of { table_name: cleaned DataFrame }
    """
    logger.info("=" * 55)
    logger.info("TRANSFORM PHASE — Cleaning and validating data")
    logger.info("=" * 55)

    cleaned = {}

    for table_name, df in dataframes.items():
        if table_name not in TRANSFORMERS:
            logger.warning(f"No transformer for '{table_name}' — passing through as-is")
            cleaned[table_name] = df
            continue
        try:
            cleaned[table_name] = TRANSFORMERS[table_name](df.copy())
        except Exception as e:
            logger.error(f"Transform failed for '{table_name}': {e}")
            raise

    logger.info(f"Transform complete — {len(cleaned)} tables cleaned\n")
    return cleaned