"""
Extract unique teams from processed data
Purpose: Populate the teams dimension table
Run: python scripts/load/extract_teams.py
"""

import os
import sys
import pandas as pd
import json

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

PROCESSED_DATA_PATH = "./data/processed/lebron_shots_processed.csv"
LOG_DIR = "logs"

os.makedirs(LOG_DIR, exist_ok=True)

# Read processed data
df = pd.read_csv(PROCESSED_DATA_PATH)

print("=" * 70)
print("EXTRACTING TEAM DATA")
print("=" * 70)

# Get unique team IDs
print("\n[STEP 1] Finding unique teams...", end=" ")

# LeBron's teams over his career
lebron_teams = {
    2003: 'CLE',   # Cleveland Cavaliers
    2008: 'CLE',   # Still Cleveland
    2010: 'MIA',   # Miami Heat
    2014: 'CLE',   # Back to Cleveland
    2018: 'LAL',   # Los Angeles Lakers
}

# For opponent teams, we need to extract from the data
print("✓")

print("[STEP 2] Examining team columns...", end=" ")
print("\nAvailable columns:")
print(df.columns.tolist())

# NBA-API typically includes TEAM_ID and OPPONENT_TEAM_ID
# Let's check what we have
if 'TEAM_ID' in df.columns:
    print(f"\n✓ Found TEAM_ID column")
    unique_teams = pd.concat([
        df['TEAM_ID'].dropna(),
        df['OPPONENT_TEAM_ID'].dropna()
    ]).unique()
    print(f"  Unique team IDs: {len(unique_teams)}")
else:
    print("\n✗ TEAM_ID column not found")
    print("Available columns:")
    for col in df.columns:
        print(f"  - {col}")
    
    # Try to infer from other columns
    print("\nSearching for team-related columns...")
    team_cols = [col for col in df.columns if 'TEAM' in col.upper()]
    print(f"Found: {team_cols}")

# Print sample data to understand structure
print("\n[STEP 3] Sample data:")
print(df[['GAME_ID', 'GAME_DATE', 'SEASON']].head())

print("\n" + "=" * 70)
print("TEAM EXTRACTION COMPLETE")
print("=" * 70)
print("\nNote: Run this to understand team data structure")
print("We'll use this info in the main load script")
