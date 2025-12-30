"""
Database connection helper
Purpose: Centralize database connection logic
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

load_dotenv()

class DatabaseConnection:
    def __init__(self):
        self.host = os.getenv('DB_HOST')
        self.port = os.getenv('DB_PORT')
        self.database = os.getenv('DB_NAME')
        self.user = os.getenv('DB_USER')
        self.password = os.getenv('DB_PASSWORD')
    
    def connect(self):
        """Create a database connection"""
        try:
            conn = psycopg2.connect(
                host=self.host,
                port=self.port,
                database=self.database,
                user=self.user,
                password=self.password
            )
            print(f"✓ Connected to {self.database}")
            return conn
        except Exception as e:
            print(f"✗ Connection failed: {e}")
            raise
    
    def execute_query(self, query, params=None):
        """Execute a SELECT query and return results"""
        conn = self.connect()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        try:
            cursor.execute(query, params)
            results = cursor.fetchall()
            return results
        finally:
            cursor.close()
            conn.close()
    
    def execute_insert(self, query, params=None):
        """Execute an INSERT/UPDATE query"""
        conn = self.connect()
        cursor = conn.cursor()
        try:
            cursor.execute(query, params)
            conn.commit()
            return cursor.rowcount
        except Exception as e:
            conn.rollback()
            print(f"✗ Insert failed: {e}")
            raise
        finally:
            cursor.close()
            conn.close()


# Make it easy to use
db = DatabaseConnection()
