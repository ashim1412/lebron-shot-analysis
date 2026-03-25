import duckdb
import glob
import os
from pathlib import Path

def load_shot_data():

    db_path = 'lebron_analytics.duckdb'
    conn = duckdb.connect(db_path)

    print(f"Connected to DuckDB: {db_path}")

    ROOT_DIR = Path(__file__).resolve().parents[1]
    RAW_DATA_DIR = ROOT_DIR / "data" / "raw"

    parquet_files = sorted(RAW_DATA_DIR.glob("shots_*.parquet"))

    if not parquet_files:
        print(f"Error: No parquet file found in the data/raw")
        print(f"Please ensure file are present before moving forward")
        return
    
    print(f"\nFound {len(parquet_files)} season files:")
    for f in parquet_files:
        print(f" - {f}")

    conn.execute("CREATE SCHEMA IF NOT EXISTS raw")

    conn.execute("DROP TABLE IF EXISTS  raw.lebron_shots")

    print("\nLoading data in DuckDB...")

    union_queries = []

    for parquet_file in parquet_files:
        filename = os.path.basename(parquet_file)
        season = filename.replace('shots_','').replace('.parquet','')

        query = f"""
        SELECT 
            *,
            '{season}' as season,
            '{parquet_file}' as source_file
        FROM read_parquet('{parquet_file}')
        """

        union_queries.append(query)

    full_query = f"""
    CREATE TABLE raw.lebron_shots As
    {'UNION ALL'.join(union_queries)}
    """

    conn.execute(full_query)


    result = conn.execute("""
                          SELECT
                                season,
                          count(*) as shot_count
                          FROM raw.lebron_shots
                          GROUP BY season
                          ORDER BY season
                          """).fetchall()
    
    print("SUCCESS!!")
    
    total_shots = 0
    for season, count in result:
        print(f"{season}:{count:,} shots")
        total_shots += count
    
    print(f"\nTotal shots: {total_shots:,}")

    columns = conn.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'raw' 
        AND table_name = 'lebron_shots'
        ORDER BY ordinal_position
    """).fetchall()

    # Show sample columns
    print("\nTable columns:")
    for col_name, col_type in columns[:10]:  # Show first 10 columns
        print(f"  - {col_name}: {col_type}")
    if len(columns) > 10:
        print(f"  ... and {len(columns) - 10} more columns")

      # Show sample data
    print("\nSample data (first 3 rows):")
    sample = conn.execute("SELECT * FROM raw.lebron_shots LIMIT 3").fetchdf()
    print(sample.to_string())
    # print("DEBUG: did the files load?", sample.shape)

    conn.close()
    print(f"\nDatabase ready at: {db_path}")
    print("Next step: run 'dbt run' to build models.")

if __name__ == "__main__":
    load_shot_data() 

