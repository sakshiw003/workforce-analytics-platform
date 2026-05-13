# ============================================================
# Module  : db_loader.py
# Purpose : Load cleaned DataFrames into PostgreSQL
#           Uses batch inserts for performance on large tables
# ============================================================

import pandas as pd
import os
import sys
from sqlalchemy import create_engine, text
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from config.db_config import DATABASE_URL
from etl.utils.logger import get_logger

logger = get_logger(__name__)

# ── Batch sizes tuned for your data volumes ───────────────
BATCH_SIZES = {
    "dim_company"       : 500,      # 119 rows   — one shot
    "dim_role"          : 500,      # 75 rows    — one shot
    "dim_skill"         : 500,      # 102 rows   — one shot
    "dim_location"      : 500,      # 68 rows    — one shot
    "fact_job_postings" : 10_000,   # 500K rows  — 50 batches
    "job_skills_bridge" : 50_000,   # 2.5M rows  — 51 batches
}

# ── Load order respects foreign key dependencies ──────────
LOAD_ORDER = [
    "dim_company",
    "dim_role",
    "dim_skill",
    "dim_location",
    "fact_job_postings",
    "job_skills_bridge",
]


def get_engine():
    """Create and return SQLAlchemy engine"""
    return create_engine(DATABASE_URL, echo=False)


def truncate_table(engine, table_name: str):
    """
    Truncate table before loading — makes pipeline idempotent
    (safe to re-run without creating duplicates).
    CASCADE handles FK-dependent tables automatically.
    """
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {table_name} CASCADE;"))
    logger.info(f"  Truncated table: {table_name}")


def load_table(
    engine,
    table_name  : str,
    df          : pd.DataFrame,
    batch_size  : int
) -> int:
    """
    Load a DataFrame into a PostgreSQL table using batch inserts.

    Args:
        engine      : SQLAlchemy engine
        table_name  : target table name
        df          : cleaned DataFrame
        batch_size  : number of rows per batch

    Returns:
        Total rows loaded
    """
    total_rows      = len(df)
    rows_loaded     = 0
    batch_number    = 0
    total_batches   = (total_rows // batch_size) + (1 if total_rows % batch_size else 0)

    logger.info(f"  Loading {total_rows:,} rows in {total_batches} batches of {batch_size:,} ...")

    start_time = datetime.now()

    for start in range(0, total_rows, batch_size):
        batch_number += 1
        batch = df.iloc[start : start + batch_size]

        # to_sql with 'append' pushes data without recreating the table
        batch.to_sql(
            name        = table_name,
            con         = engine,
            if_exists   = "append",   # append to existing table
            index       = False,      # don't write DataFrame index
            method      = "multi",    # send multiple rows per INSERT
        )

        rows_loaded += len(batch)

        # Progress log every 10 batches for large tables
        if batch_number % 10 == 0 or batch_number == total_batches:
            elapsed = (datetime.now() - start_time).seconds
            pct     = (rows_loaded / total_rows) * 100
            logger.info(
                f"    Batch {batch_number:>3}/{total_batches} | "
                f"{rows_loaded:>8,}/{total_rows:,} rows | "
                f"{pct:5.1f}% | {elapsed}s elapsed"
            )

    elapsed_total = (datetime.now() - start_time).seconds
    logger.info(f"  └─ ✅ Loaded {rows_loaded:,} rows in {elapsed_total}s")

    return rows_loaded


def load_all(dataframes: dict) -> dict:
    """
    Load all DataFrames into PostgreSQL in dependency order.

    Args:
        dataframes: dict of { table_name: cleaned DataFrame }

    Returns:
        dict of { table_name: rows_loaded }
    """
    logger.info("=" * 55)
    logger.info("LOAD PHASE — Writing data to PostgreSQL")
    logger.info("=" * 55)

    engine  = get_engine()
    summary = {}

    for table_name in LOAD_ORDER:
        if table_name not in dataframes:
            logger.warning(f"'{table_name}' not in dataframes — skipping")
            continue

        df          = dataframes[table_name]
        batch_size  = BATCH_SIZES.get(table_name, 5_000)

        logger.info(f"\nLoading: {table_name} ({len(df):,} rows)")

        try:
            # Step 1: Truncate before load
            truncate_table(engine, table_name)

            # Step 2: Load in batches
            rows_loaded = load_table(engine, table_name, df, batch_size)
            summary[table_name] = rows_loaded

        except Exception as e:
            logger.error(f"Load failed for '{table_name}': {e}")
            raise

    logger.info(f"\nLoad complete — {len(summary)} tables written to PostgreSQL\n")
    return summary