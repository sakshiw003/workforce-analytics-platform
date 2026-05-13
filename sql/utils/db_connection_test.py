# ============================================================
# Script  : db_connection_test.py
# Purpose : Verify PostgreSQL connection and schema setup
# Author  : Workforce Analytics Platform
# ============================================================

import sys
import os

# Add project root to path so we can import config
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from config.db_config import DB_CONFIG, DATABASE_URL
import psycopg2
from sqlalchemy import create_engine, text

def test_psycopg2_connection():
    """Test raw PostgreSQL connection"""
    print("\n🔌 Testing psycopg2 connection...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"   ✅ Connected! PostgreSQL version: {version[:50]}")
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"   ❌ Connection failed: {e}")
        return False

def test_sqlalchemy_connection():
    """Test SQLAlchemy connection (used by ETL pipelines)"""
    print("\n🔌 Testing SQLAlchemy connection...")
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT current_database();"))
            db_name = result.fetchone()[0]
            print(f"   ✅ Connected! Current database: {db_name}")
        return True
    except Exception as e:
        print(f"   ❌ Connection failed: {e}")
        return False

def check_tables():
    """Verify all expected tables exist"""
    print("\n📋 Checking tables in workforce_analytics...")

    expected_tables = [
        "dim_company",
        "dim_role",
        "dim_skill",
        "dim_location",
        "fact_job_postings",
        "job_skills_bridge"
    ]

    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """))
            existing_tables = [row[0] for row in result]

        print(f"   Found {len(existing_tables)} table(s):\n")
        for table in expected_tables:
            status = "✅" if table in existing_tables else "❌ MISSING"
            print(f"   {status}  {table}")

    except Exception as e:
        print(f"   ❌ Table check failed: {e}")

def check_indexes():
    """Verify indexes were created"""
    print("\n⚡ Checking indexes...")
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT indexname, tablename
                FROM pg_indexes
                WHERE schemaname = 'public'
                ORDER BY tablename, indexname;
            """))
            indexes = result.fetchall()
        print(f"   ✅ Total indexes found: {len(indexes)}")
        for idx in indexes:
            print(f"   ⚡ {idx[1]}.{idx[0]}")
    except Exception as e:
        print(f"   ❌ Index check failed: {e}")

if __name__ == "__main__":
    print("=" * 55)
    print("  Workforce Analytics — DB Connection Test")
    print("=" * 55)

    p2p = test_psycopg2_connection()
    sa  = test_sqlalchemy_connection()

    if p2p and sa:
        check_tables()
        check_indexes()
        print("\n✅ All checks complete!")
    else:
        print("\n❌ Fix connection errors before proceeding.")