# ============================================================
# Module  : csv_extractor.py
# Purpose : Extract (read) all CSV source files into DataFrames
# ============================================================

import pandas as pd
import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from etl.utils.logger import get_logger

logger = get_logger(__name__)

# ── Path to your data/raw folder ──────────────────────────
RAW_DATA_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "data", "raw"
)

# ── Map: table name → CSV filename ───────────────────────
CSV_FILES = {
    "dim_company"       : "dim_company.csv",
    "dim_role"          : "dim_role.csv",
    "dim_skill"         : "dim_skill.csv",
    "dim_location"      : "dim_location.csv",
    "fact_job_postings" : "fact_job_postings.csv",
    "job_skills_bridge" : "job_skills_bridge.csv",
}

def extract_csv(table_name: str) -> pd.DataFrame:
    """
    Read a single CSV file into a Pandas DataFrame.

    Args:
        table_name: key from CSV_FILES dict

    Returns:
        DataFrame with raw data
    """
    if table_name not in CSV_FILES:
        raise ValueError(f"Unknown table: '{table_name}'. Valid: {list(CSV_FILES.keys())}")

    file_path = os.path.join(RAW_DATA_DIR, CSV_FILES[table_name])

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"CSV not found: {file_path}")

    logger.info(f"Extracting '{table_name}' from {CSV_FILES[table_name]} ...")

    df = pd.read_csv(file_path)

    logger.info(f"  └─ Extracted {len(df):,} rows × {len(df.columns)} columns")

    return df


def extract_all() -> dict:
    """
    Extract all CSV files.

    Returns:
        dict of { table_name: DataFrame }
    """
    logger.info("=" * 55)
    logger.info("EXTRACT PHASE — Reading all CSV files")
    logger.info("=" * 55)

    dataframes = {}

    for table_name in CSV_FILES:
        try:
            dataframes[table_name] = extract_csv(table_name)
        except Exception as e:
            logger.error(f"Failed to extract '{table_name}': {e}")
            raise  # Stop pipeline — we cannot proceed with missing data

    logger.info(f"Extract complete — {len(dataframes)} tables loaded\n")

    return dataframes