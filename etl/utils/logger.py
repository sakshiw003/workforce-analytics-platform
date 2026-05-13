# ============================================================
# Module  : logger.py
# Purpose : Centralized logging for all ETL scripts
# ============================================================

import logging
import os
from datetime import datetime

def get_logger(name: str) -> logging.Logger:
    """
    Creates and returns a logger that writes to:
      1. Console (so you see output in terminal)
      2. A log file in etl/logs/ (permanent record)

    Args:
        name: usually __name__ of the calling module

    Returns:
        Configured logger instance
    """

    # Build log file path with timestamp
    log_dir = os.path.join(os.path.dirname(__file__), "..", "logs")
    os.makedirs(log_dir, exist_ok=True)

    timestamp   = datetime.now().strftime("%Y%m%d")
    log_file    = os.path.join(log_dir, f"etl_{timestamp}.log")

    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    # Avoid duplicate handlers if logger is re-used
    if logger.handlers:
        return logger

    # Format: timestamp | level | module | message
    formatter = logging.Formatter(
        fmt     = "%(asctime)s | %(levelname)-8s | %(name)-25s | %(message)s",
        datefmt = "%Y-%m-%d %H:%M:%S"
    )

    # Console handler — shows INFO and above
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)

    # File handler — captures DEBUG and above (more detail)
    file_handler = logging.FileHandler(log_file, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)

    logger.addHandler(console_handler)
    logger.addHandler(file_handler)

    return logger