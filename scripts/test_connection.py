"""
Test script to verify database connection
Run: python scripts/test_connection.py
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config.database import db

try:
    # Try to connect and query
    result = db.execute_query("SELECT COUNT(*) FROM teams;")
    print(f"✓ Database connection successful!")
    print(f"Current teams in database: {result[0]['count']}")
except Exception as e:
    print(f"✗ Connection failed: {e}")
