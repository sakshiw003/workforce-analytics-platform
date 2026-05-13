# ============================================================
# Script  : run_etl.py
# Purpose : Master ETL runner — orchestrates Extract,
#           Transform, Load for the full pipeline
# Usage   : python etl/run_etl.py
# ============================================================

import sys
import os
from datetime import datetime

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from etl.extract.csv_extractor   import extract_all
from etl.transform.data_transformer import transform_all
from etl.load.db_loader           import load_all
from etl.utils.logger             import get_logger

logger = get_logger("etl.run_etl")


def run_pipeline():
    """
    Execute the full ETL pipeline:
      1. Extract  — Read all CSV files
      2. Transform — Clean, validate, type-cast
      3. Load     — Write to PostgreSQL in batches
      4. Report   — Print execution summary
    """

    pipeline_start = datetime.now()

    logger.info("╔══════════════════════════════════════════════════╗")
    logger.info("║   WORKFORCE ANALYTICS — ETL PIPELINE START      ║")
    logger.info(f"║   Started: {pipeline_start.strftime('%Y-%m-%d %H:%M:%S')}                      ║")
    logger.info("╚══════════════════════════════════════════════════╝\n")

    try:
        # ── PHASE 1: EXTRACT ─────────────────────────────────
        extract_start   = datetime.now()
        raw_data        = extract_all()
        extract_time    = (datetime.now() - extract_start).seconds

        # ── PHASE 2: TRANSFORM ───────────────────────────────
        transform_start = datetime.now()
        clean_data      = transform_all(raw_data)
        transform_time  = (datetime.now() - transform_start).seconds

        # ── PHASE 3: LOAD ────────────────────────────────────
        load_start  = datetime.now()
        summary     = load_all(clean_data)
        load_time   = (datetime.now() - load_start).seconds

        # ── PHASE 4: REPORT ──────────────────────────────────
        total_time      = (datetime.now() - pipeline_start).seconds
        total_rows      = sum(summary.values())

        logger.info("\n╔══════════════════════════════════════════════════╗")
        logger.info("║           ETL PIPELINE — EXECUTION SUMMARY      ║")
        logger.info("╠══════════════════════════════════════════════════╣")
        logger.info(f"║  {'Table':<25} {'Rows Loaded':>15}         ║")
        logger.info("╠══════════════════════════════════════════════════╣")
        for table, rows in summary.items():
            logger.info(f"║  {table:<25} {rows:>15,}         ║")
        logger.info("╠══════════════════════════════════════════════════╣")
        logger.info(f"║  {'TOTAL ROWS':<25} {total_rows:>15,}         ║")
        logger.info("╠══════════════════════════════════════════════════╣")
        logger.info(f"║  Extract time  : {extract_time:>4}s                            ║")
        logger.info(f"║  Transform time: {transform_time:>4}s                            ║")
        logger.info(f"║  Load time     : {load_time:>4}s                            ║")
        logger.info(f"║  Total time    : {total_time:>4}s                            ║")
        logger.info("╠══════════════════════════════════════════════════╣")
        logger.info("║  STATUS: ✅ PIPELINE COMPLETED SUCCESSFULLY     ║")
        logger.info("╚══════════════════════════════════════════════════╝\n")

    except Exception as e:
        total_time = (datetime.now() - pipeline_start).seconds
        logger.error(f"\n❌ PIPELINE FAILED after {total_time}s: {e}")
        sys.exit(1)


if __name__ == "__main__":
    run_pipeline()